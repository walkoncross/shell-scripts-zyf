#!/bin/bash
# pip 换源脚本
# 用法: ./set_pip_mirror.sh [--mirror <tuna|ustc|aliyun|douban>]
# 默认使用 aliyun 源

# 解析参数
MIRROR="aliyun"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mirror)
            MIRROR="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: $0 [--mirror <tuna|ustc|aliyun|douban>]"
            exit 1
            ;;
    esac
done

# 根据镜像选择地址
case "$MIRROR" in
    tuna)
        MIRROR_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
        ;;
    ustc)
        MIRROR_URL="https://pypi.mirrors.ustc.edu.cn/simple"
        ;;
    aliyun)
        MIRROR_URL="https://mirrors.aliyun.com/pypi/simple/"
        ;;
    douban)
        MIRROR_URL="https://pypi.douban.com/simple/"
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, douban"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($MIRROR_URL)"

pip config set global.index-url "$MIRROR_URL"
pip3 config set global.index-url "$MIRROR_URL"
