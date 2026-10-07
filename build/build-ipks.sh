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
# 2026-10-07: rebased onto feed builds luci-mod-status 27.280.22511~5849cf3 / my-default-settings 2-r33;
#             luci-mod-status additionally drops the status-page sponsor-links row (local preference).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="$ROOT/files"; V="$ROOT/vendor"; D="$ROOT/dist"; W="$ROOT/work"
LMS_VENDOR="luci-mod-status_27.280.22511~5849cf3_x86_64.ipk"
LMS_VER="27.280.22511~5849cf3-r1.yt1"
AUTO_VENDOR="autocore_1_x86_64.ipk"
MDS_VENDOR="my-default-settings_2-r33_all.ipk"
MDS_VER="2-r33.yt1"
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
# guards: full-file swaps are only valid while the vendor files are unchanged
test "$(md5sum data/usr/lib/lua/luci/controller/netstat.lua | cut -d' ' -f1)" = "0746719cc1929cd3cae1ca9cbaa007e2" || { echo "netstat.lua vendor baseline changed - reapply the fix first"; exit 1; }
test "$(md5sum data/www/luci-static/resources/view/status/include/10_system.js | cut -d' ' -f1)" = "6e84bd31b74fc7a7a5c62df7f3ea1804" || { echo "10_system.js vendor baseline changed - regenerate the patched file first"; exit 1; }
install -m0644 "$F/luci-mod-status/netstat.lua" data/usr/lib/lua/luci/controller/netstat.lua
touch -r data/usr/lib/lua/luci/controller data/usr/lib/lua/luci/controller/netstat.lua
install -m0644 "$F/luci-mod-status/10_system.js" data/www/luci-static/resources/view/status/include/10_system.js
touch -r data/www/luci-static/resources/view/status/include data/www/luci-static/resources/view/status/include/10_system.js
sed -i "s/^Version: .*/Version: $LMS_VER/" ctrl/control
(cd data && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../data.tar.gz .)
(cd ctrl && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../control.tar.gz .)
tar --numeric-owner --owner=0 --group=0 -czf "$D/luci-mod-status_${LMS_VER}_x86_64.ipk" ./debian-binary ./data.tar.gz ./control.tar.gz

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
test "$(md5sum data/etc/profile.d/30-sysinfo.sh | cut -d' ' -f1)" = "9b74cc16f61f4b763fdde4c7eba26452" || { echo "30-sysinfo.sh vendor baseline changed - reapply the fix first"; exit 1; }
REF=$(mktemp); touch -r data/etc/profile.d/30-sysinfo.sh "$REF"
install -m0755 "$F/my-default-settings/30-sysinfo.sh" data/etc/profile.d/30-sysinfo.sh
touch -r "$REF" data/etc/profile.d/30-sysinfo.sh; rm -f "$REF"
sed -i "s/^Version: .*/Version: $MDS_VER/" ctrl/control
(cd data && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../data.tar.gz .)
(cd ctrl && tar --numeric-owner --owner=0 --group=0 --sort=name -czf ../control.tar.gz .)
tar --numeric-owner --owner=0 --group=0 -czf "$D/my-default-settings_${MDS_VER}_all.ipk" ./debian-binary ./data.tar.gz ./control.tar.gz

echo "=== built ==="
ls -la "$D"/*.ipk
echo "=== payload md5 (expected) ==="
echo "  luci-mod-status/netstat.lua        a9c5c5e5a08a35d5d3fa99e085d864f0"
echo "  luci-mod-status/10_system.js       889137a6252eb0850209f926ba5a795c"
echo "  luci-app-netstat/netstat.lua       f475525d780324521c8f6b5f630abf61"
echo "  autocore/cpuinfo                   bf22b40e5046a2fbb525553a6f13e4dc"
echo "  my-default-settings/30-sysinfo.sh  9a461e6d117337335db63c0797fb8672"
md5sum "$F"/luci-mod-status/netstat.lua "$F"/luci-mod-status/10_system.js "$F"/luci-app-netstat/netstat.lua "$F"/autocore/cpuinfo "$F"/my-default-settings/30-sysinfo.sh
