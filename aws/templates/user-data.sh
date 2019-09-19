#!/bin/bash

RANCHER_HOSTNAME="${rancher_hostname}"

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

rancher_setup() {
  cp -p /etc/systemd/system/rancher.service /etc/systemd/system/rancher.service.bkp
  sed -i -e "s/--hostname=[^ ]* /--hostname=$RANCHER_HOSTNAME /g" /etc/systemd/system/rancher.service
  systemctl restart rancher
}

fluentd_setup() {
  cp -p /etc/systemd/system/fluentd.service /etc/systemd/system/fluentd.service.bkp
  sed -i -e "s/--hostname=[^ ]* /--hostname=$RANCHER_HOSTNAME /g" /etc/systemd/system/fluentd.service

  if [[ -n "${grok_patterns_file}" ]]; then
    grok_file=${grok_patterns_file}
    mkdir -p $${grok_file%/*}
    cat > ${grok_patterns_file} << EOF
${grok_pattern}
EOF
  fi

  if [[ -n "${fluentd_config}" ]]; then
    cp -p /etc/fluentd/fluent.conf /etc/fluentd/fluent.conf.bkp
    cat >> /etc/fluentd/fluent.conf << EOF

${fluentd_config}
EOF
  fi

  systemctl restart fluentd
}


# Main section
export DEBIAN_FRONTEND=noninteractive
hostname_setup
rancher_setup
fluentd_setup
