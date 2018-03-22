<h1 align="center"><a href="https://git.io/sslaunch" target="_blank">SSlaunch.sh</a></h1>

<p align="center">
  <a href="https://github.com/zthxxx/SSlaunch" target="_blank"><img src="https://img.shields.io/github/languages/code-size/zthxxx/sslaunch.svg" alt="Code Size"></a>
  <a href="https://www.ubuntu.com/server" target="_blank"><img src="https://img.shields.io/badge/platform-ubuntu-brightgreen.svg" alt="Platform Support"></a>
  <a href="http://kernel.ubuntu.com/~kernel-ppa/mainline" target="_blank"><img src="https://img.shields.io/badge/kernel-4.9+-blue.svg" alt="Kernel Support"></a>
  <a href="https://github.com/zthxxx/SSlaunch/blob/master/LICENSE" target="_blank"><img src="https://img.shields.io/github/license/zthxxx/SSlaunch.svg" alt="License"></a>
</p>

# Shadowsocks launch

run BBR, install shadowsocks, 

launch ssserver with random config, also make it run-on-startup

and print the config QRCode on the terminal.


## Install with only 1 line

```bash
curl -sL git.io/sslaunch | bash
```

## Usage

- random config stored in `/etc/shadowsocks/config.json`

- start server manually: `systemctl start shadowsocks`

- use `cat /etc/shadowsocks/ss_qrcode_ipv4.log` will show the QRCode on the terminal

- change port and cipher by random: `. sslaunch.sh && launch`


## Author

**SSlaunch.sh** © [zthxxx](https://github.com/zthxxx), Released under the **[MIT](./LICENSE)** License.<br>

> Blog [@zthxxx](https://blog.zthxxx.com) · GitHub [@zthxxx](https://github.com/zthxxx)

