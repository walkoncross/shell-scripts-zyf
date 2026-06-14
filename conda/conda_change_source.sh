#!/bin/bash
# conda 换源脚本
# 用法: ./conda_change_source.sh [--mirror <tuna|ustc|aliyun>]
# 默认使用 tuna 源

# 解析参数
MIRROR="tuna"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mirror)
            MIRROR="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: $0 [--mirror <tuna|ustc|aliyun>]"
            exit 1
            ;;
    esac
done

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
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun"
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
