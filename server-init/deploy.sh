#!/usr/bin/env bash

set -e

IP="${1:-}"
PASSWORD="${2:-}"

if [ -z "$IP" ] || [ -z "$PASSWORD" ]; then
    echo "用法："
    echo "./deploy.sh 'VPS_B_IP' 'VPS_B密码'"
    exit 1
fi

echo "======================================"
echo " VPS 初始化部署"
echo "======================================"
echo "目标 VPS：$IP"
echo

# 检查 sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    echo "[+] 未检测到 sshpass，正在安装..."

    apt-get update
    apt-get install -y sshpass
fi

echo "[+] 正在连接 VPS：$IP"
echo

sshpass -p "$PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 \
    root@"$IP" \
    'bash -s' <<'REMOTE_SCRIPT'

set -e

echo "=============================================="
echo "       Linux Server Initialization"
echo "=============================================="
echo

echo "[INFO] Preparing apt/dpkg..."

# ------------------------------------------------
# 1. 停止 Ubuntu/Debian 自动更新服务
# ------------------------------------------------

echo
echo "[1/6] Stopping automatic apt services"
echo "----------------------------------------------"

systemctl stop unattended-upgrades.service 2>/dev/null || true
systemctl stop apt-daily.service 2>/dev/null || true
systemctl stop apt-daily-upgrade.service 2>/dev/null || true

echo "[OK] Automatic apt services stopped."

# ------------------------------------------------
# 2. 等待可能正在运行的 apt/dpkg 进程
# ------------------------------------------------

echo
echo "[2/6] Checking apt/dpkg processes"
echo "----------------------------------------------"

for i in $(seq 1 30); do

    if ! pgrep -x apt >/dev/null 2>&1 \
        && ! pgrep -x apt-get >/dev/null 2>&1 \
        && ! pgrep -x dpkg >/dev/null 2>&1 \
        && ! pgrep -x unattended-upgr >/dev/null 2>&1; then

        echo "[OK] No active apt/dpkg process."
        break
    fi

    echo "[INFO] Waiting for apt/dpkg process... ($i/30)"
    sleep 2

done

# ------------------------------------------------
# 3. 修复 dpkg 状态
# ------------------------------------------------

echo
echo "[3/6] Repairing dpkg"
echo "----------------------------------------------"

dpkg --configure -a

echo "[OK] dpkg configuration completed."

# ------------------------------------------------
# 4. 修复依赖
# ------------------------------------------------

echo
echo "[4/6] Fixing package dependencies"
echo "----------------------------------------------"

apt-get -f install -y

echo "[OK] Package dependencies fixed."

# ------------------------------------------------
# 5. 更新软件包列表
# ------------------------------------------------

echo
echo "[5/6] Updating system packages"
echo "----------------------------------------------"

apt-get update

echo "[OK] apt update completed."

# ------------------------------------------------
# 6. 安装 curl
# ------------------------------------------------

echo
echo "[6/6] Installing curl"
echo "----------------------------------------------"

apt-get install -y curl

echo "[OK] curl installed."

# ------------------------------------------------
# 执行真正的 server-init
# ------------------------------------------------

echo
echo "=============================================="
echo "       Running server-init"
echo "=============================================="
echo

curl -fsSL \
    https://raw.githubusercontent.com/krililrify/server-init/main/install.sh \
    | bash

REMOTE_SCRIPT

echo
echo "======================================"
echo " VPS 初始化完成"
echo "======================================"
echo "目标 VPS：$IP"
echo "======================================"