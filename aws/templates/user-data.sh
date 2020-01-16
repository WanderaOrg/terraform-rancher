#!/bin/bash

RANCHER_IMAGE=${rancher_image}
FLUENTD_IMAGE=${fluentd_image}
NODE_EXPORTER_VER=${node_exporter_version}
NODE_EXPORTER_PORT=${node_exporter_port}
NODE_EXPORTER_PATH=${node_exporter_path}
RANCHER_DIR="/opt/rancher"
HTTPS_PORT="8443"
ETCD_PORT="2379"
RANCHER_HOSTNAME="${rancher_hostname}"
S3CMD_VER=${s3cmd_version}

hostname_setup() {
  echo "Setting up hostname."

  if [[ -n "$RANCHER_HOSTNAME" ]]; then
    hostname $RANCHER_HOSTNAME
    echo $RANCHER_HOSTNAME > /etc/hostname
    sed -i -e "/$RANCHER_HOSTNAME/d" /etc/hosts
    echo "$(ip addr show dev $(ip addr show | egrep "ens5:|eth0:" | cut -d':' -f2) | grep 'inet ' | awk '{print $2}' | cut -d/ -f1) $RANCHER_HOSTNAME $(echo $RANCHER_HOSTNAME | cut -d. -f1)" >> /etc/hosts
  else
    RANCHER_HOSTNAME="$(hostname)"
  fi

}

filesystem_setup() {
  DEVICE=""
  while [[ -z $DEVICE ]]; do
    echo "Waiting for device $DEVICE ..."
    for i in $(readlink -f /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_* | grep -e "^/dev/nvme[0-9]n[0-9]$"); do
      if [[ -z `blkid $i | grep "PTTYPE=\"dos\""` ]]; then
        DEVICE=$i
        break
      fi
    done
    sleep 5
  done

  blkid $DEVICE
  if [[ $? -ne "0" ]]; then
    echo "No filesystem detected on device $DEVICE. Creating ext4 filesystem."
    mkfs -t ext4 $DEVICE
    if [[ $? -ne "0" ]]; then
      echo "Failed to create file system."
      exit 1
    fi
  else
    echo "File system already present on $DEVICE"
  fi

  mkdir /opt/rancher

  mount $DEVICE $RANCHER_DIR
  echo `blkid $DEVICE -o export | grep -E "UUID=+*"` $RANCHER_DIR ext4 defaults,nofail 0 2 >> /etc/fstab
}

docker_setup() {
  groupadd docker
  curl -sSL https://get.docker.com/ | sh
  until docker info; do echo 'Docker not ready yet ...'; sleep 1;  done
}

rancher_setup() {
  groupadd --system rancher
  useradd -s /sbin/nologin --system -g rancher rancher
  usermod -aG docker rancher

  cat > /etc/systemd/system/rancher.service << EOF
[Unit]
Description=Rancher
Documentation=https://github.com/rancher/rancher
Wants=network-online.target docker.socket
After=docker.service

[Service]
Type=simple
User=rancher
Group=rancher
ExecStartPre=/bin/bash -c """/usr/bin/docker container inspect rancher 2> /dev/null || /usr/bin/docker run -d --name=rancher --hostname=$RANCHER_HOSTNAME --restart=on-failure -p $HTTPS_PORT:$HTTPS_PORT -p $ETCD_PORT:$ETCD_PORT -v $RANCHER_DIR:/var/lib/rancher $RANCHER_IMAGE --https-listen-port=$HTTPS_PORT --no-cacerts"""
ExecStart=/usr/bin/docker start -a rancher
ExecReload=/usr/bin/docker stop -t 30 rancher

SyslogIdentifier=rancher
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl start rancher
  systemctl enable rancher
}

node_exporter_setup() {
  groupadd --system prometheus
  useradd -s /sbin/nologin --system -g prometheus prometheus

  wget -qO - https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VER/node_exporter-$NODE_EXPORTER_VER.linux-amd64.tar.gz | tar xvzC /tmp
  mv /tmp/node_exporter-$NODE_EXPORTER_VER.linux-amd64/node_exporter /usr/local/bin/

  node_exporter --version

  COLLECTORS=""
  for it in ${node_exporter_collectors}; do
    COLLECTORS="$COLLECTORS --collector.$it"
  done

  cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/node_exporter $COLLECTORS \
    --web.listen-address=:$NODE_EXPORTER_PORT \
    --web.telemetry-path="$NODE_EXPORTER_PATH" \
    --collector.filesystem.ignored-mount-points="(^/(sys|proc|dev)|/var/lib/docker|/run/docker/netns)(\$|/)"

SyslogIdentifier=node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl start node_exporter
  systemctl enable node_exporter

  ufw allow $NODE_EXPORTER_PORT
}

etcd_backup_restore () {

  echo "Restoring backup"
  if [[ "$(s3cmd ls s3://${s3_backup_bucket}/backups/)" ]]; then
    s3cmd get --force $(s3cmd ls s3://${s3_backup_bucket}/backups/  | awk '{print $4}' | sort -r | head -1 ) /tmp/rancher_snapshot.tgz
    systemctl stop rancher
    tar -xf /tmp/rancher_snapshot.tgz -C /
    systemctl start rancher
  else
    echo "No Backup to restore from s3://${s3_backup_bucket}/backups/"
  fi

}

etcd_backup_setup () {

  echo "Installing s3cmd"
  pip install python-dateutil
  pip install python-magic
  curl -O -L https://github.com/s3tools/s3cmd/releases/download/v$S3CMD_VER/s3cmd-$S3CMD_VER.tar.gz
  tar -xzvf s3cmd-$S3CMD_VER.tar.gz -C /tmp
  cp -R /tmp/s3cmd-$S3CMD_VER/s3cmd /tmp/s3cmd-$S3CMD_VER/S3 /usr/local/bin/

  cat > /root/.s3cfg << EOF
[default]
access_key = ${s3_backup_key}
secret_key = ${s3_backup_secret}
EOF

  if [[ "${s3_backup_restore}" -eq "1" ]]; then
    etcd_backup_restore
  fi

  cat > /etc/systemd/system/etcdbackup.timer << EOF
[Unit]
Description=etcd backup timer
Requires=etcdbackup.service
Wants=network-online.target docker.socket
After=docker.service

[Timer]
Unit=etcdbackup.service
OnCalendar=${s3_backup_schedule}
Persistent=true

SyslogIdentifier=etcdbackup

[Install]
WantedBy=timers.target
EOF
  cat > /etc/systemd/system/etcdbackup.service << EOF
[Unit]
Description=etcd backup service
Wants=network-online.target docker.socket etcdbackup.timer
After=docker.service

[Service]
ExecStart=/bin/bash -c /usr/local/bin/backup_etcd

SyslogIdentifier=etcdbackup

[Install]
WantedBy=multi-user.target
EOF

  cat > /usr/local/bin/backup_etcd << EOF
  FILE_NAME=snapshot-\$(date +%Y-%m-%d-%H%M).tgz
  tar --exclude='$RANCHER_DIR/management-state/etcd/member/wal' -czvf /tmp/\$FILE_NAME $RANCHER_DIR
  s3cmd put /tmp/\$FILE_NAME s3://${s3_backup_bucket}/backups/\$FILE_NAME
EOF
  chmod +x /usr/local/bin/backup_etcd

  systemctl start etcdbackup
  systemctl enable etcdbackup
}

fluentd_setup() {
  groupadd --system fluentd
  useradd -s /sbin/nologin --system -g fluentd fluentd
  usermod -aG docker fluentd

  cat > /etc/systemd/system/fluentd.service << EOF
[Unit]
Description=Fluentd
Documentation=https://github.com/fluent/fluentd
Wants=network-online.target docker.socket
After=docker.service

[Service]
Type=simple
User=fluentd
Group=fluentd
ExecStartPre=/bin/bash -c """/usr/bin/docker container inspect fluentd 2> /dev/null || /usr/bin/docker run -d --name=fluentd --hostname=$RANCHER_HOSTNAME --restart=on-failure -v /var/log:/var/log -v /etc/fluentd/:/etc/fluentd/:ro --entrypoint=fluentd $FLUENTD_IMAGE --config=/etc/fluentd/fluent.conf"""
ExecStart=/usr/bin/docker start -a fluentd
ExecReload=/usr/bin/docker stop -t 30 fluentd

SyslogIdentifier=fluentd
Restart=always

[Install]
WantedBy=multi-user.target
EOF

if [[ -n "${grok_patterns_file}" ]]; then
  grok_file=${grok_patterns_file}
  mkdir -p $${grok_file%/*}
  cat > ${grok_patterns_file} << EOF
${grok_pattern}
EOF
fi

cat > /etc/fluentd/fluent.conf << EOF
<source>
  @type tail
  path /var/log/syslog
  pos_file /var/log/syslog.pos

  tag syslog

  <parse>
    @type syslog
  </parse>
</source>

${fluentd_config}
EOF

  chown -R fluentd:fluentd /etc/fluentd/

  systemctl start fluentd
  systemctl enable fluentd
}

# Main section
export DEBIAN_FRONTEND=noninteractive
hostname_setup
filesystem_setup
docker_setup
rancher_setup
node_exporter_setup

if [[ -n "${fluentd_config}" ]]; then
  fluentd_setup
fi

if [[ -n "${s3_backup_region}" && -n "${s3_backup_bucket}" ]]; then
  etcd_backup_setup
fi
