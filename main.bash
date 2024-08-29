#!/usr/bin/bash

set -euo pipefail

function fetch {
    curl -fsSL "$@"
}

function fetch_sing {
    fetch "https://github.com/SagerNet/sing-geosite/raw/rule-set/geosite-$1.srs" -o "$1.srs"
}

function fetch_meta {
    fetch "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/$1.json" -o "$1.json"
}

function merge {
    python merge.py "$@"
}

function target {
    targ_dir="target/$1"
    shift 1
    mkdir -p "$targ_dir"
    for arg in "$@"; do
        cp -r "$arg" "$targ_dir"
    done
}

function do_adgsdns {
    # AdGuard rules
    fetch https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt -o adgsdns.txt
    # -> adgsdns.srs
    ./sing-box rule-set convert --type adguard adgsdns.txt
    target box adgsdns.srs
    # -> adgsdns.0.txt adgsdns.1.txt adgsdns.2.txt
    # pin produced expression
    unirule adgsdns.txt 'adgsdns.{}.txt' -i adguard-dns-multiout -o dlc 2> >(tee /dev/tty) | grep -F "((item_0 && !item_1) || item_2)"
    target raw adgsdns.*.txt
}

function do_copy {
    # -> category-ads-all.txt
    fetch https://github.com/v2fly/domain-list-community/raw/master/data/category-ads-all -o category-ads-all.txt
    target raw category-ads-all.txt
    # -> ip-cn.txt
    fetch https://github.com/MetaCubeX/meta-rules-dat/raw/meta/geo/geoip/cn.list -o ip-cn.txt
    target raw ip-cn.txt
}

# main
do_adgsdns
do_copy
