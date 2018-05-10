#!/usr/bin/env bash

# install & launch ssserver on ubuntu

CONFIG_FILE="/etc/shadowsocks/config.json"
SERVICE_FILE="/etc/systemd/system/shadowsocks.service"
QRCOED_IPv4_FILE="/etc/shadowsocks/ss_qrcode_ipv4.log"
QRCOED_IPv6_FILE="/etc/shadowsocks/ss_qrcode_ipv6.log"
CIPHERS=(
  aes-256-gcm
  aes-128-gcm
  chacha20-ietf-poly1305
  chacha20-ietf
)

is_command() { command -v $@ &> /dev/null; }

pwgen() { openssl rand -base64 12; }

rand_port() {
  local port_range
  if port_range=`sysctl net.ipv4.ip_local_port_range`; then 
    local port_start=`awk '{print $3}' <<< "$port_range"`
    local port_end=`awk '{print $4}' <<< "$port_range"`
  fi

  if [[ -n $port_start ]] && [[ -n $port_end ]]; then
    shuf -i ${port_start}-${port_end} -n 1
  else
    shuf -i 1024-65535 -n 1
  fi
}

port_hold_check() { netstat -tlpn | awk '{print $4}' | cut -d ':' -f 2 | grep -E "^${1}$" > /dev/null;  }

rand_cipher() { shuf -e "${CIPHERS[@]}" -n 1; }

install_shadowsocks() {
  apt install -y libsodium-dev python3-pip python3-setuptools
  pip3 install setuptools
  pip3 install -U https://github.com/shadowsocks/shadowsocks/archive/master.zip
}

install_qrencode() { apt install -y qrencode; }

run_on_startup() {
  cat > "$SERVICE_FILE" <<-EOF
		[Unit]
		Description=Shadowsocks
		
		[Service]
		ExecStart=/usr/bin/env ssserver -c ${CONFIG_FILE}
		
		[Install]
		WantedBy=multi-user.target
	EOF
  systemctl daemon-reload
  systemctl enable shadowsocks
}

pre_install() {
  if ! is_command ssserver; then
    install_shadowsocks
  fi
  if ! is_command qrencode; then
    install_qrencode
  fi
  mkdir -p /etc/shadowsocks
  touch "$CONFIG_FILE"
  run_on_startup
}

launch() {
  if ! is_command ssserver; then
    echo
    echo "[ERROR] shadowsocks is not installed! Cannot to launch it!"
    return 1
  fi

  local cipher=`rand_cipher`
  local passwd=`pwgen`
  local port=`rand_port`
  while port_hold_check "$port"; do
    port=`rand_port`
  done

  cat > "$CONFIG_FILE" <<-EOF
		{
		    "server": "::",
		    "server_port": ${port},
		    "local_address": "127.0.0.1",
		    "local_port": 1080,
		    "password": "${passwd}",
		    "timeout": 300,
		    "method": "${cipher}",
		    "fast_open": true
		}
	EOF

  # launch ss with manually or systemd 
  # ssserver -c "$CONFIG_FILE" -d start
  systemctl restart shadowsocks

  if ! systemctl status shadowsocks; then
    echo
    echo "[ERROR] shadowsocks server launch failed, plz check the status log."
    return 1
  fi

  local public_ipv4=`curl -s4 icanhazip.com`
  local public_ipv6=`curl -s6 icanhazip.com`
  # protocol ss://method:password@hostname:port
  local config_ipv4="${cipher}:${passwd}@${public_ipv4}:${port}"
  local config_ipv6="${cipher}:${passwd}@${public_ipv6}:${port}"
  local ss_ipv4_url="ss://`echo $config_ipv4 | base64 -w 0`"
  local ss_ipv6_url="ss://`echo $config_ipv6 | base64 -w 0`"

  echo
  echo "shadowsocks server ipv4 config QRCode saved to $QRCOED_IPv4_FILE"
  qrencode -t UTF8 -l Q "$ss_ipv4_url" | tee "$QRCOED_IPv4_FILE"
  echo
  echo
  echo "shadowsocks server ipv6 config QRCode saved to $QRCOED_IPv6_FILE"
  qrencode -t UTF8 -l M "$ss_ipv6_url" | tee "$QRCOED_IPv6_FILE"
}
