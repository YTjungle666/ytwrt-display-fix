#!/bin/sh
# Rollback ytwrt-display-fix local packages to the official Kwrt versions.
# Usage on the router:  sh /root/ytwrt-display-fix/rollback.sh
cd /root/ytwrt-display-fix/backup || exit 1
opkg flag user luci-mod-status
opkg flag user autocore
opkg install --force-downgrade --force-reinstall ./luci-mod-status_27.278.03253~93e12ac_x86_64.ipk
opkg install --force-downgrade --force-reinstall ./autocore_1_x86_64.ipk
echo "rollback done: official versions restored (no reboot needed; netstat.lua and cpuinfo are read per request)"
