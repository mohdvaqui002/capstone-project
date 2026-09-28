#!/usr/bin/env sh
set -eu
release_date="${1:-$(TZ=Asia/Kolkata date +%F)}"
case "$release_date" in ????-??-25) exit 0 ;; *) exit 1 ;; esac
