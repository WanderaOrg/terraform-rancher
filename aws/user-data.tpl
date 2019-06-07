#!/bin/bash

RANCHER_IMAGE=${rancher_image}
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
docker run -d --name rancher --restart=unless-stopped -p $HTTP_PORT:$HTTP_PORT -p $HTTPS_PORT:$HTTPS_PORT -v $RANCHER_DIR:/var/lib/rancher $RANCHER_IMAGE --http-listen-port $HTTP_PORT --https-listen-port $HTTPS_PORT
