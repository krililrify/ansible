#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

INVENTORY_FILE="$(mktemp)"
VARS_FILE="$(mktemp)"

cleanup() {
    rm -f "$INVENTORY_FILE"
    rm -f "$VARS_FILE"
}

trap cleanup EXIT

if [ "$#" -ne 14 ]; then
    echo "错误：需要 14 个参数，实际收到 $# 个。"
    echo
    echo "用法："
    echo "./deploy.sh 'IP' 'SSH密码' '面板A' 'tokenA' 'Aid' '域名A' '邮箱A' 'cfapiA' '面板B' 'tokenB' 'Bid' '域名B' '邮箱B' 'cfapiB'"
    exit 1
fi

IP="$1"
SSH_PASSWORD="$2"

PANEL_A="$3"
TOKEN_A="$4"
NODE_ID_A="$5"
DOMAIN_A="$6"
EMAIL_A="$7"
CF_API_A="$8"

PANEL_B="$9"
TOKEN_B="${10}"
NODE_ID_B="${11}"
DOMAIN_B="${12}"
EMAIL_B="${13}"
CF_API_B="${14}"

echo "========================================"
echo "       Hysteria22 双节点自动部署"
echo "========================================"
echo
echo "目标 VPS : $IP"
echo "节点 A   : $PANEL_A"
echo "Node A   : $NODE_ID_A"
echo "域名 A   : $DOMAIN_A"
echo
echo "节点 B   : $PANEL_B"
echo "Node B   : $NODE_ID_B"
echo "域名 B   : $DOMAIN_B"
echo
echo "========================================"
echo

# 检查 Ansible
if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "错误：未找到 ansible-playbook"
    exit 1
fi

# 检查 sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    echo "错误：未找到 sshpass"
    echo "请执行：apt install -y sshpass"
    exit 1
fi

# 检查 Python
if ! command -v python3 >/dev/null 2>&1; then
    echo "错误：未找到 python3"
    exit 1
fi

# 创建临时 inventory
cat > "$INVENTORY_FILE" <<EOF2
[xboard]
xboard-node ansible_host=$IP ansible_user=root ansible_python_interpreter=/usr/bin/python3
EOF2

chmod 600 "$INVENTORY_FILE"
chmod 600 "$VARS_FILE"

# 使用 Python 生成 JSON，避免 token / 密码中的特殊字符破坏 Ansible 参数
export H22_SSH_PASSWORD="$SSH_PASSWORD"
export H22_PANEL_A="$PANEL_A"
export H22_TOKEN_A="$TOKEN_A"
export H22_NODE_ID_A="$NODE_ID_A"
export H22_DOMAIN_A="$DOMAIN_A"
export H22_EMAIL_A="$EMAIL_A"
export H22_CF_API_A="$CF_API_A"
export H22_PANEL_B="$PANEL_B"
export H22_TOKEN_B="$TOKEN_B"
export H22_NODE_ID_B="$NODE_ID_B"
export H22_DOMAIN_B="$DOMAIN_B"
export H22_EMAIL_B="$EMAIL_B"
export H22_CF_API_B="$CF_API_B"

python3 - "$VARS_FILE" <<'PY'
import json
import os
import sys

output = sys.argv[1]

data = {
    "ansible_password": os.environ["H22_SSH_PASSWORD"],

    "panel_a": os.environ["H22_PANEL_A"],
    "token_a": os.environ["H22_TOKEN_A"],
    "node_id_a": os.environ["H22_NODE_ID_A"],
    "domain_a": os.environ["H22_DOMAIN_A"],
    "email_a": os.environ["H22_EMAIL_A"],
    "cf_api_a": os.environ["H22_CF_API_A"],

    "panel_b": os.environ["H22_PANEL_B"],
    "token_b": os.environ["H22_TOKEN_B"],
    "node_id_b": os.environ["H22_NODE_ID_B"],
    "domain_b": os.environ["H22_DOMAIN_B"],
    "email_b": os.environ["H22_EMAIL_B"],
    "cf_api_b": os.environ["H22_CF_API_B"],
}

with open(output, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

echo "开始连接 VPS..."
echo

ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook \
    -i "$INVENTORY_FILE" \
    "$BASE_DIR/playbook/deploy.yml" \
    -e "@$VARS_FILE"

echo
echo "========================================"
echo "          部署成功"
echo "========================================"
echo
echo "VPS      : $IP"
echo "节点 A   : Node $NODE_ID_A / $DOMAIN_A"
echo "节点 B   : Node $NODE_ID_B / $DOMAIN_B"
echo
echo "xboard-node 已启动。"
echo "========================================"
