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

function from_adgsdns {
    fetch https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt -o adgsdns.txt

    # -> box/adgsdns.srs
    ./sing-box rule-set convert --type adguard --output ./adgsdns.srs adgsdns.txt
    target box adgsdns.srs

    # -> raw/adgsdns.0.txt raw/adgsdns.1.txt raw/adgsdns.2.txt
    TMP=$(mktemp)
    unirule adgsdns.txt 'adgsdns.{}.txt' -i adguard-dns-multiout -o dlc 2> >(tee -a "$TMP")
    # pin produced expression
    grep -F "((item_0 && !item_1) || item_2)" "$TMP" >/dev/null
    target raw adgsdns.*.txt
}

function from_dlc {
    fetch https://github.com/v2fly/domain-list-community/raw/release/category-ads-all.txt -o dlc-ads-all.txt

    # -> raw/category-ads-all.txt
    # remove attributes
    unirule dlc-ads-all.txt category-ads-all.txt -i dlc -o dlc
    target raw category-ads-all.txt
}

function from_custom {
    # -> box/hbr.srs
    ./sing-box rule-set compile --output ./hbr.srs target/box/hbr.json
    target box hbr.srs
}

function from_meta_ip {
    fetch https://github.com/MetaCubeX/meta-rules-dat/raw/meta/geo/geoip/cn.list -o ip-cn.txt

    # -> raw/ip-cn.txt
    target raw ip-cn.txt
}

function from_sing {
    fetch_sing geolocation-cn
    fetch_sing geolocation-!cn

    # -> raw/geolocation-cn.txt
    ./sing-box rule-set decompile --output ./cn.json ./geolocation-cn.srs
    unirule cn.json geolocation-cn.txt -i singbox -o dlc
    target raw geolocation-cn.txt
    # -> raw/geolocation-!cn.txt
    ./sing-box rule-set decompile --output ./!cn.json ./geolocation-!cn.srs
    unirule !cn.json geolocation-!cn.txt -i singbox -o dlc
    target raw geolocation-!cn.txt
}

# main
from_adgsdns
from_dlc
from_custom
from_meta_ip
from_sing
