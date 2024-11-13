# Block RKN bots using iptables

Blacklist: https://github.com/C24Be/AS_Network_List/blob/main/blacklists/blacklist.txt \
Original instruction: [original_instruction.pdf](https://github.com/freemedia-tech/iptables-rugov-block/blob/06465fbc5fc65aa61311200e53f42a8adf0f4f72/original_instruction.pdf) \
Original repo: [freemedia-tech/iptables-rugov-block](https://github.com/freemedia-tech/iptables-rugov-block)

Tested on Ubuntu 22.04 and Debian 12.

## Usage

With logging:
```bash
apt install -y iptables-persistent rsyslog \
    && git clone https://github.com/moetelo/iptables-rkn.git \
    && ./iptables-rkn/install.sh --log
```

Without logging:
```bash
apt install -y iptables-persistent \
    && git clone https://github.com/moetelo/iptables-rkn.git \
    && ./iptables-rkn/install.sh
```

Blocked attempts log: `/var/log/rugov-blacklist/blacklist.log` \
Blacklist updater log: `/var/log/rugov-blacklist/blacklist-updater.log` \
Executable: `/usr/local/bin/rugov-blacklist-update.sh`

## Key differences with the upstream repo

- Fixes annoying bug that caused iptables pollution and server throughput slowdown.
    <details>
    <summary>Info for the original author</summary>

    ```
    iptables v1.8.9 (nf_tables): Illegal option `-n' with this command
    ```

    ```diff
    -if ! sudo "$FMT_IPCMD" -n -t raw -C PREROUTING -s "$addr" -j DROP &>/dev/null; then
    +if ! sudo "$FMT_IPCMD" -t raw -C PREROUTING -s "$addr" -j DROP &>/dev/null; then
    ```
    </details>

- Follows [Filesystem Hierarchy Standard (FHS)](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)
- Persists ip6tables via `ip6tables-save`
- Removed PDF from the repo. You don't need this on the server.

## Uninstall

```sh
rm -f /etc/rsyslog.d/51-iptables-rugov.conf
rm -f /etc/cron.daily/rugov-blacklist-update
rm -f /usr/local/bin/rugov-blacklist-update.sh
```
