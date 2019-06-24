#!/bin/bash

RANCHER_IMAGE=${rancher_image}
NODE_EXPORTER_VER=${node_exporter_version}
NODE_EXPORTER_PORT=${node_exporter_port}
NODE_EXPORTER_PATH=${node_exporter_path}
DEVICE="/dev/nvme1n1"
RANCHER_DIR="/opt/rancher"
HTTP_PORT="8080"
HTTPS_PORT="8443"

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
echo $DEVICE  $RANCHER_DIR ext4 defaults,nofail 0 2 >> /etc/fstab

curl -sSL https://get.docker.com/ | sh
until docker info; do echo 'Docker not ready yet ...'; sleep 1;  done
docker run -d --name rancher --restart=unless-stopped -p $HTTP_PORT:$HTTP_PORT -p $HTTPS_PORT:$HTTPS_PORT -v $RANCHER_DIR:/var/lib/rancher $RANCHER_IMAGE --http-listen-port $HTTP_PORT --https-listen-port $HTTPS_PORT --no-cacerts


# Node exporter
groupadd --system prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus

wget -qO - https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VER/node_exporter-$NODE_EXPORTER_VER.linux-amd64.tar.gz | tar xvzC /tmp
mv /tmp/node_exporter-$NODE_EXPORTER_VER.linux-amd64/node_exporter /usr/local/bin/

node_exporter  --version

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