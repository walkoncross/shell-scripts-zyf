#!/bin/bash
# conda 换源脚本
# 用法: ./switch_conda_mirror.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源

MIRROR="${1:-aliyun}"

echo "当前 conda 配置："
conda config --show channels 2>/dev/null || echo "暂无 conda 配置"
echo ""

# 根据镜像选择地址
case "$MIRROR" in
    tuna)
        BASE="https://mirrors.tuna.tsinghua.edu.cn/anaconda"
        ;;
    ustc)
        BASE="https://mirrors.ustc.edu.cn/anaconda"
        ;;
    aliyun)
        BASE="https://mirrors.aliyun.com/anaconda"
        ;;
    restore)
        echo "恢复 conda 官方源..."
        conda config --remove-key channels 2>/dev/null || true
        conda config --remove-key show_channel_urls 2>/dev/null || true
        echo "已恢复官方默认源"
        echo "当前 conda 配置："
        conda config --show channels
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($BASE)"

conda config --set show_channel_urls yes
conda config --remove-key channels 2>/dev/null || true

conda config --add channels defaults
conda config --add channels "${BASE}/cloud/conda-forge/"
conda config --add channels "${BASE}/pkgs/free/"
conda config --add channels "${BASE}/pkgs/main/"

echo "当前 conda 配置："
conda config --show channels
