#!/usr/bin/env bash

# install & launch ssserver on ubuntu

CONFIG_FILE="/etc/shadowsocks/config.json"
QRCOED_FILE="/etc/shadowsocks/ssserver.qrcode"
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

pre_install() {
  if ! command -v "ssserver" > /dev/null; then
    install_shadowsocks
  fi
  if ! command -v "qrencode" > /dev/null; then
    install_qrencode
  fi
  sed -i '/ssserver/d' /etc/rc.local
  echo "ssserver -c $CONFIG_FILE -d start" >> /etc/rc.local
}

launch() {
  cipher=`rand_cipher`
  passwd=`pwgen`
  public_ip=`curl -s ipv4.canhazip.com`
  port=`rand_port`
  while port_check "$port"; do
    port=`rand_port`
  done

  cat > "$CONFIG_FILE" <<-EOF
		{
		    "server": "0.0.0.0",
		    "server_port": ${port},
		    "local_address": "127.0.0.1",
		    "local_port": 1080,
		    "password": "${passwd}",
		    "timeout": 300,
		    "method": "${cipher}",
		    "fast_open": true
		}
	EOF

  # protocol ss://method:password@hostname:port
  configuration="${cipher}:${passwd}@${public_ip}:${port}"
  ss_url="ss://`echo $configuration | base64`"
  ssserver -c "$CONFIG_FILE" -d start
  echo "configuration QRCode saved to $QRCOED_FILE"
  qrencode -t UTF8 -l H "$ss_url" | tee "$QRCOED_FILE"
}
