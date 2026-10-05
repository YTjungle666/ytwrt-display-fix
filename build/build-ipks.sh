#!/bin/bash
# Repack the fixed sources into local held packages for Kwrt / YT-WRT (opkg-lede layout).
#
# Inputs:
#   vendor/<pkg>_<ver>.ipk          official packages (on the device: `opkg download <pkg>`,
#                                   or copy from the device backup dirs)
#   files/<package>/<file>          fixed payload files (this repo)
# Output:
#   dist/*.ipk                      locally versioned packages (-r*.yt1)
#
# Only the payload file(s) and the Version line differ from the vendor packages.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="$ROOT/files"; V="$ROOT/vendor"; D="$ROOT/dist"; W="$ROOT/work"
LMS_VENDOR="luci-mod-status_27.278.03253~93e12ac_x86_64.ipk"
AUTO_VENDOR="autocore_1_x86_64.ipk"
MDS_VENDOR="my-default-settings_2-r30_all.ipk"
mkdir -p "$D" "$W"
for f in "$V/$LMS_VENDOR" "$V/$AUTO_VENDOR" "$V/$MDS_VENDOR"; do
  [ -f "$f" ] || { echo "ERROR: missing $f (see README)"; exit 1; }
done

# ---------- luci-mod-status ----------
rm -rf "$W/lms"; mkdir -p "$W/lms"; cd "$W/lms"
tar xzf "$V/$LMS_VENDOR"
mkdir data ctrl
tar xzf data.tar.gz -C data
tar xzf control.tar.gz -C ctrl
cp ctrl/control ./control.vendor
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
cp ctrl/control ./control.vendor
install -m0755 "$F/autocore/cpuinfo" data/sbin/cpuinfo
touch -r data/sbin data/sbin/cpuinfo
sed -i 's/^Version: .*/Version: 1-r1.yt1/' ctrl/control
(cd data && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../data.tar.gz .)
(cd ctrl && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../control.tar.gz .)
tar --numeric-owner --owner=0 --group=0 -czf "$D/autocore_1-r1.yt1_x86_64.ipk" ./debian-binary ./data.tar.gz ./control.tar.gz

# ---------- my-default-settings ----------
rm -rf "$W/mds"; mkdir -p "$W/mds"; cd "$W/mds"
tar xzf "$V/$MDS_VENDOR"
mkdir data ctrl
tar xzf data.tar.gz -C data
tar xzf control.tar.gz -C ctrl
cp ctrl/control ./control.vendor
install -m0755 "$F/my-default-settings/30-sysinfo.sh" data/etc/profile.d/30-sysinfo.sh
touch -r data/etc/profile.d data/etc/profile.d/30-sysinfo.sh
sed -i 's/^Version: .*/Version: 2-r30.yt1/' ctrl/control
(cd data && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../data.tar.gz .)
(cd ctrl && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../control.tar.gz .)
tar --numeric-owner --owner=0 --group=0 -czf "$D/my-default-settings_2-r30.yt1_all.ipk" ./debian-binary ./data.tar.gz ./control.tar.gz

echo "=== built ==="
ls -la "$D"/*.ipk
echo "=== payload md5 (expected) ==="
echo "  luci-mod-status/netstat.lua        a9c5c5e5a08a35d5d3fa99e085d864f0"
echo "  luci-app-netstat/netstat.lua       f475525d780324521c8f6b5f630abf61"
echo "  autocore/cpuinfo                   bf22b40e5046a2fbb525553a6f13e4dc"
echo "  my-default-settings/30-sysinfo.sh  9a461e6d117337335db63c0797fb8672"
md5sum "$F"/luci-mod-status/netstat.lua "$F"/luci-app-netstat/netstat.lua "$F"/autocore/cpuinfo "$F"/my-default-settings/30-sysinfo.sh
