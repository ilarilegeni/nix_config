#!/usr/bin/env bash

INTERFACE="wlp9s0"  # ← à adapter (ex: wlan0, enp3s0...)

get_bytes() {
    cat /proc/net/dev | grep "$INTERFACE" | awk '{print $2, $10}'
}

read rx1 tx1 < <(get_bytes)
sleep 1
read rx2 tx2 < <(get_bytes)

rx_rate=$(( (rx2 - rx1) ))
tx_rate=$(( (tx2 - tx1) ))

# Format humain (en KB/s ou MB/s)
format_rate() {
    local rate=$1
    if (( rate > 1048576 )); then
        printf "%.1f MB/S" "$(bc -l <<< "$rate/1048576")"
    elif (( rate > 1024 )); then
        printf "%.1f KB/S" "$(bc -l <<< "$rate/1024")"
    else
        printf "%d B/s" "$rate"
    fi
}

echo " $(format_rate $rx_rate)  $(format_rate $tx_rate) "

