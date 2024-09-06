# Keep your webserver clean from RKN bots using iptables.

This project uses blacklists from https://github.com/C24Be/AS_Network_List/blob/main/blacklists/blacklist.txt

Pay attention! This script was tested on Ubuntu 22.04, there could be any issues on other versions or Linuxes!

Original instructions from the author of this solution: [original_instruction.pdf](https://github.com/freemedia-tech/iptables-rugov-block/blob/06465fbc5fc65aa61311200e53f42a8adf0f4f72/original_instruction.pdf)

## How to use

1. `sudo apt-get install iptables-persistent rsyslog` \
(rsyslog is required if you want to keep logs).
1. Clone this repo to your server
1. Run `sudo ./install.sh` or `sudo ./install.sh --log` to enable logging of all requests from forbidden IPs.

Log file: `/var/log/rugov_blacklist/blacklist.log`

## What it does

- adds rsyslogd rules in /etc/rsyslog.d/51-iptables-rugov.conf (only with `--log`)
- makes directory `/var/log/rugov_blacklist/`, puts there all necessary files
- runs the update process
- installs cron script to /etc/cron.daily/rugov_updater
