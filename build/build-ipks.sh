#!/bin/bash
# Repack the fixed sources into local held packages for Kwrt / YT-WRT (opkg-lede layout).
#
# Inputs:
#   vendor/<pkg>_<ver>_x86_64.ipk   official packages (on the device: `opkg download <pkg>`,
#                                   or copy from /root/ytwrt-display-fix/backup/)
#   files/<package>/<file>          fixed payload files (this repo)
# Output:
#   dist/*.ipk                      locally versioned packages (-r1.yt1)
#
# Only the payload file(s) and the Version line differ from the vendor packages.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="$ROOT/files"; V="$ROOT/vendor"; D="$ROOT/dist"; W="$ROOT/work"
LMS_VENDOR="luci-mod-status_27.278.03253~93e12ac_x86_64.ipk"
AUTO_VENDOR="autocore_1_x86_64.ipk"
mkdir -p "$D" "$W"
for f in "$V/$LMS_VENDOR" "$V/$AUTO_VENDOR"; do
  [ -f "$f" ] || { echo "ERROR: missing $f (see README)"; exit 1; }
done

# ---------- luci-mod-status ----------
rm -rf "$W/lms"; mkdir -p "$W/lms"; cd "$W/lms"
tar xzf "$V/$LMS_VENDOR"
mkdir data ctrl
tar xzf data.tar.gz -C data
tar xzf control.tar.gz -C ctrl
cp ctrl/control ctrl/control.vendor
install -m0644 "$F/luci-mod-status/netstat.lua" data/usr/lib/lua/luci/controller/netstat.lua
touch -r data/usr/lib/lua/luci/controller data/usr/lib/lua/luci/controller/netstat.lua
sed -i 's/^Version: .*/Version: 27.278.03253~93e12ac-r1.yt1/' ctrl/control
(cd data && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../data.tar.gz .)
(cd ctrl && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../control.tar.gz .)
tar --numeric-owner --owner=0 --group=0 -czf "$D/luci-mod-status_27.278.03253~93e12ac-r1.yt1_x86_64.ipk" ./debian-binary ./data.tar.gz ./control.tar.gz

# ---------- autocore ----------
rm -rf "$W/ac"; mkdir -p "$W/ac"; cd "$W/ac"
tar xzf "$V/$AUTO_VENDOR"
mkdir data ctrl
tar xzf data.tar.gz -C data
tar xzf control.tar.gz -C ctrl
cp ctrl/control ctrl/control.vendor
install -m0755 "$F/autocore/cpuinfo" data/sbin/cpuinfo
touch -r data/sbin data/sbin/cpuinfo
sed -i 's/^Version: .*/Version: 1-r1.yt1/' ctrl/control
(cd data && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../data.tar.gz .)
(cd ctrl && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../control.tar.gz .)
tar --numeric-owner --owner=0 --group=0 -czf "$D/autocore_1-r1.yt1_x86_64.ipk" ./debian-binary ./data.tar.gz ./control.tar.gz

echo "=== built ==="
ls -la "$D"/*.ipk
echo "=== payload md5 (expected) ==="
echo "  luci-mod-status/netstat.lua   a9c5c5e5a08a35d5d3fa99e085d864f0"
echo "  luci-app-netstat/netstat.lua  f475525d780324521c8f6b5f630abf61"
echo "  autocore/cpuinfo              bf22b40e5046a2fbb525553a6f13e4dc"
md5sum "$F"/luci-mod-status/netstat.lua "$F"/luci-app-netstat/netstat.lua "$F"/autocore/cpuinfo
