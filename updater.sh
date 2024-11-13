#!/bin/env bash

set -euo pipefail

mkdir -p /var/log/rugov-blacklist
mkdir -p /var/local/rugov-blacklist

log() {
    local LOG_FILE='/var/log/rugov-blacklist/blacklist-updater.log'

    echo "$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

get_iptables_cmd() {
    [[ "$1" == *":"* ]] && echo "ip6tables" || echo "iptables"
}

[[ "$(id -u)" -ne 0 ]] && echo 'The script is intended to run under root' && exit 1

OLD_IP_FILE=/var/local/rugov-blacklist/blacklist.old.txt
NEW_IP_FILE=/var/local/rugov-blacklist/blacklist.txt
BLOCK_MESSAGE='Blocked RUGOV IP attempt: '

is_logging_installed=
[[ -f "/etc/rsyslog.d/51-iptables-rugov.conf" ]] && is_logging_installed=true

[[ ! -f "$NEW_IP_FILE" ]] && touch "$NEW_IP_FILE"
mv "$NEW_IP_FILE" "$OLD_IP_FILE"

if ! curl -fsSLo "$NEW_IP_FILE" https://github.com/C24Be/AS_Network_List/raw/main/blacklists/blacklist.txt; then
    log 'Failed to load new blacklist. Leaving the list unchanged.'
    exit 1
fi

sort -o "$NEW_IP_FILE" "$NEW_IP_FILE"
sort -o "$OLD_IP_FILE" "$OLD_IP_FILE" &> /dev/null || true

existing_ips=$(iptables -t raw -S PREROUTING | grep 'DROP' || true)
existing_ips_v6=$(ip6tables -t raw -S PREROUTING | grep 'DROP' || true)
combined_existing_ips=$(echo -e "$existing_ips\n$existing_ips_v6" | awk '{print $4}' | sort)

ips_to_add=$(grep -Fvxf <(echo "$combined_existing_ips") "$NEW_IP_FILE" || true)
while IFS= read -r ip || [[ -n "$ip" ]]; do
    [[ -z "$ip" ]] && continue

    cmd=$(get_iptables_cmd "$ip")

    if [[ "$is_logging_installed" = true ]]; then
        "$cmd" -t raw -A PREROUTING -s "$ip" -j LOG --log-prefix "$BLOCK_MESSAGE"
    fi
    "$cmd" -t raw --append PREROUTING -s "$ip" -j DROP
done <<< "$ips_to_add"

ips_to_remove=$(grep -Fvxf "$NEW_IP_FILE" "$OLD_IP_FILE" || true)
while IFS= read -r ip || [[ -n "$ip" ]]; do
    [[ -z "$ip" ]] && continue

    cmd=$(get_iptables_cmd "$ip")
    "$cmd" -t raw --delete PREROUTING -s "$ip" -j LOG --log-prefix "$BLOCK_MESSAGE" 2>&1 || true
    "$cmd" -t raw --delete PREROUTING -s "$ip" -j DROP
done <<< "$ips_to_remove"

iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Substract trailing newline
added=$(($(echo "$ips_to_add" | wc -l) - 1))
removed=$(($(echo "$ips_to_remove" | wc -l) - 1))

log "Added: $added, removed: $removed"
