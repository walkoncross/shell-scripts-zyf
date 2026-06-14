#!/bin/bash
# apt 换源脚本（适用于 Ubuntu/Debian）
# 用法: ./switch_apt_source.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源
# 需要 sudo 权限

SOURCES_LIST="/etc/apt/sources.list"
BACKUP="$SOURCES_LIST.bak"

MIRROR="${1:-aliyun}"

# 检测发行版和 codename
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"          # ubuntu / debian
    CODENAME="$VERSION_CODENAME"
else
    echo "无法检测发行版，请确认在 Ubuntu/Debian 上运行"
    exit 1
fi

echo "发行版: $DISTRO $CODENAME"
echo ""
echo "当前 apt 源文件："
grep -v '^#' "$SOURCES_LIST" 2>/dev/null | grep -v '^$' || echo "无法读取 $SOURCES_LIST"
echo ""

# 根据镜像选择地址
case "$MIRROR" in
    tuna)
        BASE="https://mirrors.tuna.tsinghua.edu.cn"
        ;;
    ustc)
        BASE="https://mirrors.ustc.edu.cn"
        ;;
    aliyun)
        BASE="https://mirrors.aliyun.com"
        ;;
    restore)
        if [[ -f "$BACKUP" ]]; then
            echo "恢复官方源..."
            sudo cp "$BACKUP" "$SOURCES_LIST"
            echo "已从备份恢复: $BACKUP"
        else
            echo "未找到备份文件: $BACKUP"
            echo "请手动恢复 $SOURCES_LIST"
            exit 1
        fi
        sudo apt-get update
        echo "验证当前 apt 源文件："
        head "$SOURCES_LIST"
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($BASE)"

# 备份原始 sources.list
if [[ ! -f "$BACKUP" ]]; then
    sudo cp "$SOURCES_LIST" "$BACKUP"
    echo "已备份原始配置到: $BACKUP"
fi

# 生成新的 sources.list
if [[ "$DISTRO" == "ubuntu" ]]; then
    sudo tee "$SOURCES_LIST" > /dev/null <<EOF
deb ${BASE}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb ${BASE}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb ${BASE}/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb ${BASE}/ubuntu/ ${CODENAME}-security main restricted universe multiverse
EOF
elif [[ "$DISTRO" == "debian" ]]; then
    sudo tee "$SOURCES_LIST" > /dev/null <<EOF
deb ${BASE}/debian/ ${CODENAME} main contrib non-free
deb ${BASE}/debian/ ${CODENAME}-updates main contrib non-free
deb ${BASE}/debian/ ${CODENAME}-backports main contrib non-free
deb ${BASE}/debian-security/ ${CODENAME}-security main contrib non-free
EOF
else
    echo "不支持的发行版: $DISTRO，仅支持 ubuntu / debian"
    exit 1
fi

echo "已更新 $SOURCES_LIST"
sudo apt-get update
echo "验证当前 apt 源文件："
head "$SOURCES_LIST"
