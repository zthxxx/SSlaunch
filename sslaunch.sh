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

pwgen() { head -c 64 /dev/random | md5sum | head -c 12; }

rand_port() { shuf -i 1024-65535 -n 1; }

port_hold_check() { netstat -tlpn | awk '{print $4}' | cut -d ':' -f 2 | grep -E "^${1}$" > /dev/null;  }

rand_cipher() { shuf -e "${CIPHERS[@]}" -n 1; }

install_shadowsocks() {
  apt-get install -y python3-pip
  pip3 install setuptools
  pip3 install git+https://github.com/shadowsocks/shadowsocks.git@master
}

install_qrencode() { apt-get install -y qrencode; }

run_on_startup() {
  if [ -f /etc/rc.local ]; then 
    sed -i '/ssserver/d' /etc/rc.local
    echo "ssserver -c $CONFIG_FILE -d start" >> /etc/rc.local
  else
    cat > "$SERVICE_FILE" <<-EOF
			[Unit]
			Description=Shadowsocks
			
			[Service]
			TimeoutStartSec=0
			ExecStart=/usr/bin/ssserver -c ${CONFIG_FILE}
			
			[Install]
			WantedBy=multi-user.target
		EOF
    systemctl enable shadowsocks
  fi
}

pre_install() {
  if ! command -v "ssserver" > /dev/null; then
    install_shadowsocks
  fi
  if ! command -v "qrencode" > /dev/null; then
    install_qrencode
  fi
  mkdir -p /etc/shadowsocks
  touch "$CONFIG_FILE"
  run_on_startup
}

launch() {
  cipher=`rand_cipher`
  passwd=`pwgen`
  port=`rand_port`
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

  ssserver -c "$CONFIG_FILE" -d start


  public_ipv4=`curl -s4 icanhazip.com`
  public_ipv6=`curl -s6 icanhazip.com`
  # protocol ss://method:password@hostname:port
  config_ipv4="${cipher}:${passwd}@${public_ipv4}:${port}"
  config_ipv6="${cipher}:${passwd}@${public_ipv6}:${port}"
  ss_ipv4_url="ss://`echo $config_ipv4 | base64 -w 0`"
  ss_ipv6_url="ss://`echo $config_ipv6 | base64 -w 0`"

  echo
  echo "shadowsocks server ipv4 config QRCode saved to $QRCOED_IPv4_FILE"
  qrencode -t UTF8 -l Q "$ss_ipv4_url" | tee "$QRCOED_IPv4_FILE"
  echo
  echo
  echo "shadowsocks server ipv6 config QRCode saved to $QRCOED_IPv6_FILE"
  qrencode -t UTF8 -l M "$ss_ipv6_url" | tee "$QRCOED_IPv6_FILE"
}
