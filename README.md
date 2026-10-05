# ytwrt-display-fix

Kwrt（Proxmox LXC + lxcfs）状态页与登录横幅显示问题的修复源码与本地包构建脚本。

## 修复内容

1. **CPU 温度恒为假值（如 20°C）**：容器内 `/sys/class/thermal` 只有宿主 ACPI 的摆设热区，读数恒定且无意义；改为优先按 hwmon 传感器名读取 CPU 温度（k10temp / coretemp / zenpower / cpu_thermal / soc_thermal，多路取最高值），找不到再回退原有热区扫描。
2. **STORAGE 恒为 0 MB / 0 MB**：busybox `df` 遇到长设备名（LVM / 容器根盘）会把设备名折到第二行，`awk 'NR==2'` 解析为空；改用 `df -kP`（POSIX 输出，恒为单行）。
3. **CPU 核数少算（如 7C 8T）**：容器内 `/proc/cpuinfo` 是宿主过滤出的部分视图（processor 数 < siblings），宿主 core id 会原样透出；当分配到的 CPU 集合包含同一物理核的两个 SMT 线程时，按 core id 去重会少算。改为检测到部分视图时直接按分配到的 CPU 数显示核数/线程数；裸机行为不变。
4. **登录横幅报错与数值失真**（`/etc/profile.d/30-sysinfo.sh`，my-default-settings 包）：
   - busybox `df` 折行导致 `awk: cmd. line:1: Access to negative field` 报错、系统存储行丢失 → `df -h /` 改为 `df -P -h /`；
   - `uptime`/`free` 在容器内显示宿主机的负载/运行时间/内存 → 改为直读 `/proc/loadavg`、`/proc/uptime`、`/proc/meminfo`（裸机行为不变，仅格式统一）；
   - CPU 型号被 `cut -d ' ' -f -4` 截断（`AMD Ryzen AI 9 HX PRO 370 ...` → `AMD Ryzen AI 9`）→ 改为 `cut -f 1-7`。

## 目录

    files/luci-mod-status/netstat.lua       → root/usr/lib/lua/luci/controller/netstat.lua
    files/luci-app-netstat/netstat.lua      → files/usr/lib/lua/luci/controller/netstat.lua
                                              （luci-mod-status 内的副本源自此包，一并修正）
    files/autocore/cpuinfo                  → /sbin/cpuinfo
    files/my-default-settings/30-sysinfo.sh → /etc/profile.d/30-sysinfo.sh
    patches/                                → 上游 kiddin9/op-packages 的 diy patch（每次上游同步自动重放）
    build/build-ipks.sh                     → 用官方 ipk 重打包成本地版本（-r*.yt1）
    build/rollback.sh                       → 设备上回滚到官方版本

## 部署状态

- 已安装并 hold：`luci-mod-status 27.278.03253~93e12ac-r1.yt1`、`autocore 1-r1.yt1`、`my-default-settings 2-r30.yt1`（`opkg flag hold`）
- 本地版本号高于 feed，且已 hold，不会随 opkg 更新；完整升级/重刷会还原官方文件，之后重新安装即可
- 设备端备份：`/root/ytwrt-display-fix/backup/`（官方 ipk + 原文件）

## 上游提交（kiddin9/op-packages）

- PR #11（netstat 温度 + 磁盘）：https://github.com/kiddin9/op-packages/pull/11
- PR #12（autocore 核数）：https://github.com/kiddin9/op-packages/pull/12
- my-default-settings 登录横幅：https://github.com/kiddin9/op-packages/pull/13

以 `.github/diy/patches/*.patch` 形式提交（Sync 会重克隆所有包目录、只保留 `.github/diy/`，补丁在克隆后按文件名排序自动应用）。

## 重新构建（本地包）

    mkdir -p vendor
    # 取官方 ipk（任一方式）：
    #   路由器上:  opkg download luci-mod-status autocore my-default-settings
    #   或从设备备份 /root/ytwrt-display-fix/backup/ 取
    cp <官方ipk> vendor/
    bash build/build-ipks.sh        # 输出 dist/*.ipk

## 说明

- 相关：procd 容器视图修复 https://github.com/YTjungle666/procd-lxcfs-fix

## 许可证

本仓库以 **GPL-3.0** 发布（见 [LICENSE](LICENSE)）——与主要参考源码 [nooblk-98/luci-app-netstat](https://github.com/nooblk-98/luci-app-netstat)（GPL-3.0）一致，`files/luci-*/netstat.lua` 为其修改版。

`files/autocore/cpuinfo` 来自 [immortalwrt](https://github.com/immortalwrt/immortalwrt) 的 autocore（GPL-2.0-only），`files/my-default-settings/30-sysinfo.sh` 来自 [kiddin9/my-packages](https://github.com/kiddin9/my-packages) 的 my-default-settings（GPL-2.0），均保留其原始许可声明；各修改文件版权归原项目所有。
