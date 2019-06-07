#!/bin/bash

DEVICE="/dev/nvme1n1"
RANCHER_DIR="/opt/rancher"
RANCHER_IMAGE="rancher/rancher"

while [[ ! -b ${DEVICE} ]]; do echo "Waiting for device ${DEVICE} ..."; sleep 5; done

blkid ${DEVICE}

if [[ $? -ne "0" ]]; then
  echo "No filesystem detected on device ${DEVICE}. Creating ext4 filesystem."
  mkfs -t ext4 ${DEVICE}
  if [[ $? -ne "0" ]]; then
    echo "Failed to create file system."
    exit 1
  fi
else
  echo "File system already present on ${DEVICE}"
fi

mkdir /opt/rancher

mount ${DEVICE} ${RANCHER_DIR}
echo ${DEVICE}  ${RANCHER_DIR} ext4 defaults,nofail 0 2 >> /etc/fstab

curl -sSL https://get.docker.com/ | sh
until docker info; do echo 'Docker not ready yet ...'; sleep 1;  done
docker run -d --name rancher --restart=unless-stopped -p 8080:8080 -p 8443:8443 -v ${RANCHER_DIR}:/var/lib/rancher ${RANCHER_IMAGE} --http-listen-port 8080 --https-listen-port 8443
