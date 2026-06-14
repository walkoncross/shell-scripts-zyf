#!/bin/bash
# pip 换源脚本
# 用法: ./pip_change_source.sh [tuna|ustc|aliyun|douban|restore]
# 默认使用 aliyun 源；restore 恢复官方源

MIRROR="${1:-aliyun}"

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
    restore)
        echo "恢复 pip 官方源..."
        pip config unset global.index-url 2>/dev/null || true
        pip3 config unset global.index-url 2>/dev/null || true
        echo "已恢复官方源"
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, douban, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($MIRROR_URL)"

pip config set global.index-url "$MIRROR_URL"
pip3 config set global.index-url "$MIRROR_URL"
