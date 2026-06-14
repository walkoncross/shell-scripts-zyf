#!/bin/bash
# yum/dnf 换源脚本（适用于 CentOS/RHEL/Rocky/AlmaLinux/Fedora）
# 用法: ./switch_yum_mirror.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源
# 需要 sudo 权限
#
# 关键设计：换源后必须让旧的官方 .repo「失效」，否则它们和新写入的镜像 repo
#           同时 enabled，yum 仍可能从官方源拉取(与 homebrew 旧脚本同类问题)。
#           本脚本通过把旧 .repo 重命名为 .repo.disabled 来禁用(yum 只认 .repo 后缀)，
#           restore 时再改回，全程不删除文件、可逆。

REPO_DIR="/etc/yum.repos.d"
MIRROR="${1:-aliyun}"

# 本脚本生成的镜像 repo 文件名(restore 时需禁用它们；换源时不自我禁用)
MIRROR_REPO_FILES=("CentOS-Base.repo" "fedora.repo" "rhel-base.repo")

# 包管理器命令：新版用 dnf，老版回退 yum
if command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
else
    PKG="yum"
fi

# 检测发行版
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"                       # centos / rhel / fedora / rocky / almalinux
    VERSION_MAJOR="${VERSION_ID%%.*}"
    IS_STREAM=0
    [[ "$NAME" == *Stream* ]] && IS_STREAM=1   # 区分 CentOS Stream 与传统 CentOS
else
    echo "无法检测发行版，请确认在 CentOS/RHEL/Fedora 上运行"
    exit 1
fi

echo "发行版: $NAME $VERSION_ID  (包管理器: $PKG)"
echo ""
echo "当前启用的 repo："
$PKG repolist 2>/dev/null | sed 's/^/  /' || echo "  (无法获取 repolist)"
echo ""

is_mirror_repo() {  # 判断某文件名是否本脚本生成的镜像 repo
    local name="$1"
    for m in "${MIRROR_REPO_FILES[@]}"; do [[ "$name" == "$m" ]] && return 0; done
    return 1
}

# 禁用除镜像 repo 外的所有 .repo(重命名为 .disabled)，使镜像源成为唯一来源
disable_official_repos() {
    for f in "$REPO_DIR"/*.repo; do
        [[ -e "$f" ]] || continue
        is_mirror_repo "$(basename "$f")" && continue
        sudo mv "$f" "$f.disabled"
        echo "  已禁用: $(basename "$f")"
    done
}

# 根据镜像选择地址
case "$MIRROR" in
    tuna)   BASE="https://mirrors.tuna.tsinghua.edu.cn" ;;
    ustc)   BASE="https://mirrors.ustc.edu.cn" ;;
    aliyun) BASE="https://mirrors.aliyun.com" ;;
    restore)
        echo "恢复官方源..."
        # 1) 把镜像 repo 文件禁用掉(改名为 .disabled，不删除)
        for m in "${MIRROR_REPO_FILES[@]}"; do
            [[ -f "$REPO_DIR/$m" ]] && sudo mv "$REPO_DIR/$m" "$REPO_DIR/$m.disabled" \
                && echo "  已移除镜像 repo: $m"
        done
        # 2) 把之前禁用的官方 repo 恢复回来
        restored=0
        for f in "$REPO_DIR"/*.repo.disabled; do
            [[ -e "$f" ]] || continue
            is_mirror_repo "$(basename "${f%.disabled}")" && continue  # 跳过镜像 repo 的 .disabled
            sudo mv "$f" "${f%.disabled}"
            echo "  已恢复: $(basename "${f%.disabled}")"
            restored=1
        done
        [[ "$restored" -eq 0 ]] && echo "  未找到可恢复的官方 .repo.disabled 备份，请手动检查 $REPO_DIR"
        sudo "$PKG" clean all >/dev/null 2>&1
        sudo "$PKG" makecache 2>/dev/null
        echo "验证 repo 列表："
        $PKG repolist
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($BASE)"
echo ""
echo "禁用现有官方 repo(改名为 .disabled，可通过 restore 还原)："
disable_official_repos
echo ""

# 根据发行版生成对应镜像 repo 文件
case "$DISTRO" in
    centos)
        if [[ "$IS_STREAM" -eq 1 ]]; then
            # CentOS Stream：$stream 变量在 Stream 系统上有定义(8/9)
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
        elif [[ "$VERSION_MAJOR" -ge 8 ]]; then
            # 传统 CentOS 8 已 EOL，仓库迁移到 vault；如有问题请改用 CentOS Stream
            echo "警告: 传统 CentOS $VERSION_MAJOR 已 EOL，使用 vault 归档源，建议迁移到 Stream"
            sudo tee "$REPO_DIR/CentOS-Base.repo" > /dev/null <<EOF
[baseos]
name=CentOS-\$releasever - BaseOS (vault)
baseurl=${BASE}/centos-vault/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream]
name=CentOS-\$releasever - AppStream (vault)
baseurl=${BASE}/centos-vault/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        else
            # CentOS 7 已 EOL(2024-06)，aliyun 仍保留 centos/7 路径
            echo "警告: CentOS $VERSION_MAJOR 已 EOL，镜像可能不再更新"
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

echo "已写入镜像 repo 到 $REPO_DIR"
sudo "$PKG" clean all >/dev/null 2>&1
sudo "$PKG" makecache
echo ""
echo "验证 repo 列表："
$PKG repolist
