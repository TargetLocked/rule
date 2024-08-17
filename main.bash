#!/usr/bin/bash

set -euo pipefail

function fetch {
    curl -fsSL "$@"
}

function fetch_sing {
    fetch "https://github.com/SagerNet/sing-geosite/raw/rule-set/geosite-$1.srs" -o "$1.srs"
}

function fetch_meta {
    fetch "https://github.com/MetaCubeX/meta-rules-dat/blob/sing/geo/geosite/$1.json" -o "$1.json"
}

function merge {
    python merge.py "$@"
}

function target {
    for arg in "$@"; do
        cp "$arg" target/
    done
}

function do_block {
    # adg.json: AdGuard rules
    fetch https://github.com/AdguardTeam/AdGuardSDNSFilter/raw/gh-pages/Filters/filter.txt -o adg.txt
    sing-box rule-set convert --type adguard --output adg.srs adg.txt
    sing-box rule-set decompile adg.srs
    # category-ads-all.json: geosite
    fetch_meta category-ads-all

    # block.{json,txt}
    merge adg.json category-ads-all.json >block.json
    unirule block.json block.txt -i singbox -o dlc

    target block.json block.txt
}

# main
mkdir "target"
do_block
