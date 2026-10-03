#!/bin/bash

set -e

if [ "$#" -ne 8 ]; then
    echo ""
    echo "=========================================="
    echo "        XBoard HY2 一键部署"
    echo "=========================================="
    echo ""
    echo "参数数量错误！"
    echo ""
    echo "用法："
    echo "./deploy.sh 'IP' '密码' '面板URL' 'Token' 'NodeID' '域名' '邮箱' 'CF_API_TOKEN'"
    echo ""
    echo "示例："
    echo "./deploy.sh '154.88.64.193' 'password' 'https://new.9999521.xyz' 'xinhuayun@233333' '47' 'ceshi01.8882220.xyz' 'missljq@gmail.com' 'CF_API_TOKEN'"
    echo ""
    exit 1
fi

# ============================================================
# 接收参数
# ============================================================

IP="$1"
SSH_PASSWORD="$2"
PANEL_URL="$3"
PANEL_TOKEN="$4"
NODE_ID="$5"
DOMAIN="$6"
EMAIL="$7"
CF_API_TOKEN="$8"

# ============================================================
# 显示部署信息
# ============================================================

echo ""
echo "=========================================="
echo "        XBoard HY2 一键部署"
echo "=========================================="
echo ""
echo "目标 IP    : $IP"
echo "Panel URL  : $PANEL_URL"
echo "Node ID    : $NODE_ID"
echo "Domain     : $DOMAIN"
echo "Email      : $EMAIL"
echo ""
echo "开始部署..."
echo ""

# ============================================================
# 创建临时目录
# ============================================================

TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

chmod 700 "$TMP_DIR"

# ============================================================
# 创建 Ansible Inventory
#
# 注意：
# playbook/deploy.yml 使用的是 hosts: hy2
# 因此这里必须保持 hy2 主机组名称。
# ============================================================

export DEPLOY_IP="$IP"
export DEPLOY_PASSWORD="$SSH_PASSWORD"
export INVENTORY_FILE="$TMP_DIR/inventory.json"

python3 <<'PY'
import json
import os

inventory = {
    "hy2": {
        "hosts": {
            "hy2-node": {
                "ansible_host": os.environ["DEPLOY_IP"],
                "ansible_user": "root",
                "ansible_password": os.environ["DEPLOY_PASSWORD"],
                "ansible_ssh_common_args": "-o StrictHostKeyChecking=no"
            }
        }
    }
}

with open(os.environ["INVENTORY_FILE"], "w", encoding="utf-8") as f:
    json.dump(inventory, f, ensure_ascii=False, indent=2)
PY

# ============================================================
# 创建 Ansible Extra Vars
#
# 使用 JSON 文件传递参数，避免特殊字符被 Shell
# 或 ansible-playbook 的命令行参数再次解析。
# ============================================================

export DEPLOY_PANEL_URL="$PANEL_URL"
export DEPLOY_PANEL_TOKEN="$PANEL_TOKEN"
export DEPLOY_NODE_ID="$NODE_ID"
export DEPLOY_DOMAIN="$DOMAIN"
export DEPLOY_EMAIL="$EMAIL"
export DEPLOY_CF_API_TOKEN="$CF_API_TOKEN"

export VARS_FILE="$TMP_DIR/extra_vars.json"

python3 <<'PY'
import json
import os

variables = {
    "panel_url": os.environ["DEPLOY_PANEL_URL"],
    "panel_token": os.environ["DEPLOY_PANEL_TOKEN"],
    "node_id": os.environ["DEPLOY_NODE_ID"],
    "domain": os.environ["DEPLOY_DOMAIN"],
    "email": os.environ["DEPLOY_EMAIL"],
    "cf_api_token": os.environ["DEPLOY_CF_API_TOKEN"]
}

with open(os.environ["VARS_FILE"], "w", encoding="utf-8") as f:
    json.dump(variables, f, ensure_ascii=False, indent=2)
PY

chmod 600 "$TMP_DIR/inventory.json"
chmod 600 "$TMP_DIR/extra_vars.json"

# ============================================================
# 执行 Ansible
# ============================================================

ansible-playbook \
    -i "$TMP_DIR/inventory.json" \
    playbook/deploy.yml \
    -e "@$VARS_FILE"

# ============================================================
# 部署完成
# ============================================================

echo ""
echo "=========================================="
echo "        部署执行结束"
echo "=========================================="
echo ""