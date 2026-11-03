#!/bin/bash
# apt 换源脚本（适用于 Ubuntu/Debian）
# 用法: ./switch_apt_mirror.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源
# 需要 sudo 权限
#
# 关键设计：Ubuntu 24.04 / Debian 12+ 默认改用 DEB822 格式的
#           /etc/apt/sources.list.d/ubuntu.sources(或 debian.sources)，
#           此时传统 /etc/apt/sources.list 可能为空甚至不存在。只写老文件
#           在新系统上不生效，故本脚本自动探测格式并写对应文件。

MIRROR="${1:-aliyun}"

LIST_FILE="/etc/apt/sources.list"

# 检测发行版和 codename
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"                 # ubuntu / debian
    CODENAME="$VERSION_CODENAME"
else
    echo "无法检测发行版，请确认在 Ubuntu/Debian 上运行"
    exit 1
fi

# 探测当前使用的源格式：DEB822(.sources) 优先，否则用传统 sources.list
DEB822_FILE=""
for f in /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/debian.sources; do
    [[ -f "$f" ]] && DEB822_FILE="$f" && break
done

if [[ -n "$DEB822_FILE" ]]; then
    FORMAT="deb822"
    TARGET="$DEB822_FILE"
else
    FORMAT="legacy"
    TARGET="$LIST_FILE"
fi
BACKUP="$TARGET.bak"

echo "发行版: $DISTRO $CODENAME  (源格式: $FORMAT)"
echo "目标文件: $TARGET"
echo ""
echo "当前源内容："
grep -vE '^\s*(#|$)' "$TARGET" 2>/dev/null | sed 's/^/  /' || echo "  无法读取 $TARGET"
echo ""

# 根据镜像选择地址
case "$MIRROR" in
    tuna)   BASE="https://mirrors.tuna.tsinghua.edu.cn" ;;
    ustc)   BASE="https://mirrors.ustc.edu.cn" ;;
    aliyun) BASE="https://mirrors.aliyun.com" ;;
    restore)
        if [[ -f "$BACKUP" ]]; then
            echo "恢复官方源..."
            sudo cp "$BACKUP" "$TARGET"
            echo "已从备份恢复: $BACKUP -> $TARGET"
        else
            echo "未找到备份文件: $BACKUP"
            echo "请手动恢复 $TARGET"
            exit 1
        fi
        sudo apt-get update
        echo "验证当前源文件："
        grep -vE '^\s*(#|$)' "$TARGET" | head
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($BASE)"

# 备份原始文件(仅首次)
if [[ -f "$TARGET" && ! -f "$BACKUP" ]]; then
    sudo cp "$TARGET" "$BACKUP"
    echo "已备份原始配置到: $BACKUP"
fi

# Debian security 仓库的路径与组件随版本不同，单独计算
deb_security_line() {
    # bookworm(12) 起 security 路径为 debian-security，套件名为 <codename>-security
    echo "deb ${BASE}/debian-security/ ${CODENAME}-security main contrib non-free non-free-firmware"
}

if [[ "$FORMAT" == "deb822" ]]; then
    # DEB822 格式：写 .sources 文件
    if [[ "$DISTRO" == "ubuntu" ]]; then
        sudo tee "$TARGET" > /dev/null <<EOF
Types: deb
URIs: ${BASE}/ubuntu/
Suites: ${CODENAME} ${CODENAME}-updates ${CODENAME}-backports ${CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
    else  # debian
        sudo tee "$TARGET" > /dev/null <<EOF
Types: deb
URIs: ${BASE}/debian/
Suites: ${CODENAME} ${CODENAME}-updates ${CODENAME}-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: ${BASE}/debian-security/
Suites: ${CODENAME}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    fi
else
    # 传统 legacy 格式：写 sources.list
    if [[ "$DISTRO" == "ubuntu" ]]; then
        sudo tee "$TARGET" > /dev/null <<EOF
deb ${BASE}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb ${BASE}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb ${BASE}/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb ${BASE}/ubuntu/ ${CODENAME}-security main restricted universe multiverse
EOF
    else  # debian
        sudo tee "$TARGET" > /dev/null <<EOF
deb ${BASE}/debian/ ${CODENAME} main contrib non-free non-free-firmware
deb ${BASE}/debian/ ${CODENAME}-updates main contrib non-free non-free-firmware
deb ${BASE}/debian/ ${CODENAME}-backports main contrib non-free non-free-firmware
$(deb_security_line)
EOF
    fi
fi

echo "已更新 $TARGET"
sudo apt-get update
echo "验证当前源文件："
grep -vE '^\s*(#|$)' "$TARGET" | head
