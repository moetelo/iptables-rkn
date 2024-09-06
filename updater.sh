#!/bin/env bash

set -euo pipefail

log() {
    local LOG_FILE='/var/log/rugov_blacklist/blacklist_updater.log'

    echo "$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

get_iptables_cmd() {
    [[ "$1" == *":"* ]] && echo "ip6tables" || echo "iptables"
}

[[ "$(id -u)" -ne 0 ]] && echo 'The script is intended to run under root' && exit 1

IFS=$'\n\t'

OLD_IP_FILE=/var/local/rugov_blacklist/old_blacklist.txt
NEW_IP_FILE=/var/local/rugov_blacklist/blacklist.txt
BLOCK_MESSAGE='Blocked RUGOV IP attempt: '

is_logging_installed=
[[ -f "/etc/rsyslog.d/51-iptables-rugov.conf" ]] && is_logging_installed=true

mv "$NEW_IP_FILE" "$OLD_IP_FILE"

if ! wget -O "$NEW_IP_FILE" https://github.com/C24Be/AS_Network_List/raw/main/blacklists/blacklist.txt; then
    log 'Failed to load new blacklist. Leaving the list unchanged.'
    exit 1
fi

added=0
while IFS= read -r ip || [[ -n "$ip" ]]; do
    cmd=$(get_iptables_cmd "$ip")

    if ! "$cmd" -n -t raw --check PREROUTING -s "$ip" -j DROP &>/dev/null; then
        if [[ "$is_logging_installed" = true ]]; then
            "$cmd" -t raw -A PREROUTING -s "$ip" -j LOG --log-prefix "$BLOCK_MESSAGE"
        fi
        "$cmd" -t raw --append PREROUTING -s "$ip" -j DROP
        ((added++)) || true
    fi
done < "$NEW_IP_FILE"

removed=0
while IFS= read -r ip || [[ -n "$ip" ]]; do
    cmd=$(get_iptables_cmd "$ip")

    if ! grep -q "$ip" "$NEW_IP_FILE"; then
        "$cmd" -t raw --delete PREROUTING -s "$ip" -j LOG --log-prefix "$BLOCK_MESSAGE" || true
        "$cmd" -t raw --delete PREROUTING -s "$ip" -j DROP
        ((removed++)) || true
    fi
done < "$OLD_IP_FILE"

iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

log "Added: $added, removed: $removed"
