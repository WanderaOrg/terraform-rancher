#!/bin/bash

RANCHER_IMAGE=${rancher_image}
NODE_EXPORTER_VER=${node_exporter_version}
NODE_EXPORTER_PORT=${node_exporter_port}
NODE_EXPORTER_PATH=${node_exporter_path}
DEVICE="/dev/nvme1n1"
RANCHER_DIR="/opt/rancher"
HTTPS_PORT="8443"
ETCD_PORT="2379"

filesystem_setup() {
  while [[ ! -b $DEVICE ]]; do echo "Waiting for device $DEVICE ..."; sleep 5; done

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
  echo $DEVICE $RANCHER_DIR ext4 defaults,nofail 0 2 >> /etc/fstab
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
ExecStartPre=/bin/bash -c """/usr/bin/docker container inspect rancher 2> /dev/null || /usr/bin/docker run -d --name=rancher --restart=on-failure -p $HTTPS_PORT:$HTTPS_PORT -p $ETCD_PORT:$ETCD_PORT -v $RANCHER_DIR:/var/lib/rancher $RANCHER_IMAGE --https-listen-port=$HTTPS_PORT --no-cacerts"""
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
    --web.telemetry-path="$NODE_EXPORTER_PATH"

SyslogIdentifier=node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl start node_exporter
  systemctl enable node_exporter

  ufw allow $NODE_EXPORTER_PORT
}

etcd_backup_setup () {

  echo "Installing awsless"
  curl https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash
  mv awless /usr/local/bin/

  awless --version

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
Environment=AWS_ACCESS_KEY_ID=${s3_backup_key}
Environment=AWS_SECRET_ACCESS_KEY=${s3_backup_secret}
ExecStart=/bin/bash -c /usr/local/bin/backup_etcd

SyslogIdentifier=etcdbackup

[Install]
WantedBy=multi-user.target
EOF

  cat > /usr/local/bin/backup_etcd << EOF
  /usr/local/bin/awless --aws-region=${s3_backup_region} --force create s3object bucket=${s3_backup_bucket} name=backups/snapshot-\$(date +%Y-%m-%d-%H%M).db file=$RANCHER_DIR/management-state/etcd/member/snap/db
EOF
  chmod +x /usr/local/bin/backup_etcd

  systemctl start etcdbackup
  systemctl enable etcdbackup
}

# Main section
filesystem_setup
docker_setup
rancher_setup
node_exporter_setup

if [[ -n "${s3_backup_region}" && -n "${s3_backup_bucket}" ]]; then
  etcd_backup_setup
fi
