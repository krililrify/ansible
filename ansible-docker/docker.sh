#!/bin/bash

set -e

# ==========================================
# Docker 一键安装
# 使用方法:
# ./docker.sh "IP" "密码"
# ==========================================

if [ "$#" -ne 2 ]; then
    echo ""
    echo "=========================================="
    echo "        Docker 一键安装"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./docker.sh \"IP\" \"密码\""
    echo ""
    echo "示例:"
    echo "  ./docker.sh \"154.88.64.193\" \"123456\""
    echo ""
    exit 1
fi

TARGET_IP="$1"
TARGET_PASSWORD="$2"

INVENTORY_FILE="/tmp/ansible-docker-inventory-$$.ini"

echo ""
echo "=========================================="
echo "        Docker 一键安装"
echo "=========================================="
echo ""
echo "目标 IP : $TARGET_IP"
echo ""

# 检查 Ansible
if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "[ERROR] 未找到 ansible-playbook"
    exit 1
fi

echo "[1/4] 准备 SSH..."

mkdir -p /root/.ssh
touch /root/.ssh/known_hosts

ssh-keyscan -H "$TARGET_IP" >> /root/.ssh/known_hosts 2>/dev/null || true

echo "[OK] SSH 配置完成"
echo ""

echo "[2/4] 生成临时配置..."

cat > "$INVENTORY_FILE" <<INVENTORY
[docker_servers]
docker_target ansible_host=$TARGET_IP
INVENTORY

echo "[OK] 临时配置生成完成"
echo ""

echo "[3/4] 安装 Docker..."
echo ""

ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook \
    -i "$INVENTORY_FILE" \
    playbook.yml \
    -e "ansible_password=$TARGET_PASSWORD"

RESULT=$?

rm -f "$INVENTORY_FILE"

if [ "$RESULT" -ne 0 ]; then
    echo ""
    echo "=========================================="
    echo "        Docker 安装失败"
    echo "=========================================="
    echo ""
    echo "目标 IP : $TARGET_IP"
    echo ""
    exit "$RESULT"
fi

echo ""
echo "[4/4] 安装检查完成"
echo ""
echo "=========================================="
echo "        Docker 部署成功"
echo "=========================================="
echo ""
echo "目标 IP : $TARGET_IP"
echo ""
