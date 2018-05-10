#!/usr/bin/env bash

# launch BBR on ubuntu v17.10 and above

version_ge() { test "$(echo "$1 $2" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

check_bbr_kernel_version() {
  local BBR_VERSION="4.9"
  local kernel_version=$(uname -r | cut -d - -f 1)
  version_ge "${kernel_version}" "$BBR_VERSION"
}

check_bbr_status() {
  local param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
  [ "${param}" == "bbr" ]
}

sysctl_bbr() {
  modprobe tcp_bbr
  sed -i '/tcp_bbr/d' /etc/modules-load.d/modules.conf
  echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
  sysctl -p >/dev/null 2>&1
}

bbr() {
  if ! check_bbr_status; then
    if check_bbr_kernel_version; then
      sysctl_bbr
    fi
  fi
}

