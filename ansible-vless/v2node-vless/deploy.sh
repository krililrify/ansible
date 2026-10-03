#!/bin/bash

set -e

export ANSIBLE_HOST_KEY_CHECKING=False

# ==============================
# v2node 一键部署脚本
# ==============================

if [ "$#" -ne 4 ]; then
    echo ""
    echo "用法："
    echo "./deploy.sh \"IP\" \"密码\" \"NodeID1\" \"NodeID2\""
    echo ""
    echo "示例："
    echo "./deploy.sh \"154.88.64.193\" \"你的密码\" \"42\" \"53\""
    echo ""
    exit 1
fi

TARGET_IP="$1"
TARGET_PASSWORD="$2"
NODE_ID_1="$3"
NODE_ID_2="$4"

BASE_DIR="/root/ansible-vless/v2node-vless"
INVENTORY="$BASE_DIR/inventory.ini"

echo ""
echo "=========================================="
echo "        v2node 一键部署"
echo "=========================================="
echo ""
echo "目标 IP    : $TARGET_IP"
echo "NodeID 1   : $NODE_ID_1"
echo "NodeID 2   : $NODE_ID_2"
echo ""

# ==============================
# 检查参数
# ==============================

if ! [[ "$TARGET_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "错误：IP 地址格式不正确"
    exit 1
fi

if ! [[ "$NODE_ID_1" =~ ^[0-9]+$ ]]; then
    echo "错误：NodeID1 必须是数字"
    exit 1
fi

if ! [[ "$NODE_ID_2" =~ ^[0-9]+$ ]]; then
    echo "错误：NodeID2 必须是数字"
    exit 1
fi

# ==============================
# 生成临时 inventory
# ==============================

cat > "$INVENTORY" <<EOF2
[v2node]
test ansible_host=$TARGET_IP ansible_user=root ansible_password='$TARGET_PASSWORD' node_id_1=$NODE_ID_1 node_id_2=$NODE_ID_2
EOF2

echo "正在测试 SSH / Ansible 连接..."
echo ""

if ! ANSIBLE_HOST_KEY_CHECKING=False ansible -i "$INVENTORY" v2node -m ping; then
    echo ""
    echo "=========================================="
    echo "SSH / Ansible 连接失败"
    echo "=========================================="
    echo ""
    rm -f "$INVENTORY"
    exit 1
fi

echo ""
echo "SSH 连接成功"
echo ""
echo "开始部署 v2node..."
echo ""

# ==============================
# 执行 Ansible Playbook
# ==============================

if ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY" "$BASE_DIR/deploy.yml"; then
    RESULT=0
else
    RESULT=$?
fi

# ==============================
# 删除临时 inventory
# ==============================

rm -f "$INVENTORY"

echo ""

if [ "$RESULT" -eq 0 ]; then
    echo "=========================================="
    echo "        v2node 部署成功"
    echo "=========================================="
    echo ""
    echo "IP       : $TARGET_IP"
    echo "NodeID1  : $NODE_ID_1"
    echo "NodeID2  : $NODE_ID_2"
    echo ""
else
    echo "=========================================="
    echo "        v2node 部署失败"
    echo "=========================================="
    echo ""
    exit "$RESULT"
fi