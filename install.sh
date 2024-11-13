#!/bin/env bash

set -euo pipefail

EXECUTABLE_PATH=/usr/local/bin/rugov-blacklist-update.sh

if [[ "$(id -u)" != "0" ]]; then
    echo "The script is intended to run under root"
    exit 1
fi

installer_dir=$(dirname "$(readlink -f "$0")")

install_logs=
if [[ -n ${1+x} && "$1" == "--log" ]];then
    install_logs=true
fi

if [[ ! -d "/etc/iptables/" ]]; then
    echo 'The script is intended to be used with iptables. Are you sure all the necessary packages are installed? Run:'
    echo 'sudo apt install iptables-persistent'
    exit 2
fi

if [[ "$install_logs" = true ]]; then
    if [[ ! -d "/etc/rsyslog.d/" ]]; then
        echo '/etc/rsyslog.d/ not found, are you sure rsyslogd is installed? Run:'
        echo 'sudo apt install rsyslog'
        exit 1
    fi

    echo "Installing rsyslogd config..."
    cp "$installer_dir/51-iptables-rugov.conf" /etc/rsyslog.d/51-iptables-rugov.conf

    service rsyslog restart
fi

echo "Installing common files..."
mkdir -p /var/log/rugov-blacklist
chown nobody:adm /var/log/rugov-blacklist
chmod 0755 /var/log/rugov-blacklist

cp "$installer_dir/updater.sh" $EXECUTABLE_PATH
chmod +x $EXECUTABLE_PATH

echo "Running initial setup process..."
$EXECUTABLE_PATH

ln -sf $EXECUTABLE_PATH /etc/cron.daily/

echo "Installation finished successfully!"
