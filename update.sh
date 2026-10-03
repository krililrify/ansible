#!/bin/bash

set -e

REPO="https://github.com/krililrify/ansible/archive/refs/heads/main.zip"
TMP_DIR="/root/.ansible-update"
ZIP_FILE="/root/.ansible-update.zip"

echo "======================================"
echo "   VPS 脚本仓库更新工具"
echo "   GitHub: krililrify/ansible"
echo "======================================"
echo ""

echo "[1/4] 准备临时目录..."
rm -rf "$TMP_DIR" "$ZIP_FILE"
mkdir -p "$TMP_DIR"

echo "[2/4] 下载 GitHub 最新版本..."
wget -q "$REPO" -O "$ZIP_FILE"

echo "[3/4] 解压并同步到 /root..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

rm -rf "$ZIP_FILE"

cp -a "$TMP_DIR"/ansible-main/. /root/

rm -rf "$TMP_DIR"

echo ""
echo "[4/4] 更新完成！"
echo ""
echo "当前 /root 内容："
echo "--------------------------------------"
ls -lah /root
echo "--------------------------------------"
echo ""
echo "GitHub 仓库已同步到 /root"
