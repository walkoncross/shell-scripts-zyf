#!/bin/bash
# yum 换源脚本（适用于 CentOS/RHEL/Fedora）
# 用法: ./switch_yum_source.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源
# 需要 sudo 权限

REPO_DIR="/etc/yum.repos.d"
BACKUP_DIR="$REPO_DIR/backup"

MIRROR="${1:-aliyun}"

# 检测发行版
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"           # centos / rhel / fedora / rocky / almalinux
    VERSION_MAJOR="${VERSION_ID%%.*}"
else
    echo "无法检测发行版，请确认在 CentOS/RHEL/Fedora 上运行"
    exit 1
fi

echo "发行版: $DISTRO $VERSION_ID"
echo ""
echo "当前 yum 源文件："
ls "$REPO_DIR"/*.repo 2>/dev/null | while read f; do echo "  $f"; head -3 "$f" 2>/dev/null | grep -E '^(name|baseurl|mirrorlist)' | sed 's/^/    /'; done
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
        if [[ -d "$BACKUP_DIR" ]] && ls "$BACKUP_DIR"/*.repo &>/dev/null; then
            echo "恢复官方源..."
            sudo cp "$BACKUP_DIR"/*.repo "$REPO_DIR/"
            echo "已从备份恢复: $BACKUP_DIR"
        else
            echo "未找到备份文件: $BACKUP_DIR"
            echo "请手动恢复 $REPO_DIR 下的 .repo 文件"
            exit 1
        fi
        sudo yum makecache
        echo "验证 yum 仓库列表："
        yum repolist
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($BASE)"

# 备份原始 .repo 文件
if ! ls "$BACKUP_DIR"/*.repo &>/dev/null; then
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp "$REPO_DIR"/*.repo "$BACKUP_DIR/" 2>/dev/null || true
    echo "已备份原始配置到: $BACKUP_DIR"
fi

# 根据发行版生成对应 repo 文件
case "$DISTRO" in
    centos)
        if [[ "$VERSION_MAJOR" -ge 8 ]]; then
            sudo tee "$REPO_DIR/CentOS-Base.repo" > /dev/null <<EOF
[baseos]
name=CentOS Stream \$releasever - BaseOS
baseurl=${BASE}/centos-stream/\$stream/BaseOS/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream]
name=CentOS Stream \$releasever - AppStream
baseurl=${BASE}/centos-stream/\$stream/AppStream/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        else
            sudo tee "$REPO_DIR/CentOS-Base.repo" > /dev/null <<EOF
[base]
name=CentOS-\$releasever - Base
baseurl=${BASE}/centos/\$releasever/os/\$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-\$releasever - Updates
baseurl=${BASE}/centos/\$releasever/updates/\$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-\$releasever - Extras
baseurl=${BASE}/centos/\$releasever/extras/\$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        fi
        ;;
    fedora)
        sudo tee "$REPO_DIR/fedora.repo" > /dev/null <<EOF
[fedora]
name=Fedora \$releasever - \$basearch
baseurl=${BASE}/fedora/releases/\$releasever/Everything/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch

[updates]
name=Fedora \$releasever - \$basearch - Updates
baseurl=${BASE}/fedora/updates/\$releasever/Everything/\$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
EOF
        ;;
    rhel | rocky | almalinux)
        sudo tee "$REPO_DIR/rhel-base.repo" > /dev/null <<EOF
[baseos]
name=BaseOS
baseurl=${BASE}/rockylinux/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[appstream]
name=AppStream
baseurl=${BASE}/rockylinux/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        ;;
    *)
        echo "不支持的发行版: $DISTRO，仅支持 centos / rhel / rocky / almalinux / fedora"
        exit 1
        ;;
esac

echo "已更新 $REPO_DIR"
sudo yum makecache
echo "验证 yum 仓库列表："
yum repolist
