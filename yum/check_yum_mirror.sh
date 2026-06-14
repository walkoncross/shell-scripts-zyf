#!/bin/bash
# 查看 yum/dnf 当前镜像源配置
#
# 关注点：.repo 文件里的 enabled= 才决定该源是否真正生效；换源后若旧官方 repo
#         仍 enabled，会与镜像 repo 同时拉取。故需区分「启用/禁用」并列出已禁用文件。

REPO_DIR="/etc/yum.repos.d"

if command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
else
    PKG="yum"
fi

echo "========== 1) 当前启用的 repo($PKG repolist) =========="
$PKG repolist 2>/dev/null | sed 's/^/  /' || echo "  (无法获取 repolist)"
echo ""

echo "========== 2) $REPO_DIR 下的 .repo 文件及其 baseurl/enabled =========="
if ls "$REPO_DIR"/*.repo &>/dev/null; then
    for f in "$REPO_DIR"/*.repo; do
        echo "  [$f]"
        grep -E '^(name|baseurl|mirrorlist|enabled)=' "$f" 2>/dev/null | sed 's/^/    /'
        echo ""
    done
else
    echo "  未找到启用的 .repo 文件"
    echo ""
fi

echo "========== 3) 已禁用的 repo(.repo.disabled，由换源脚本重命名) =========="
if ls "$REPO_DIR"/*.repo.disabled &>/dev/null; then
    for f in "$REPO_DIR"/*.repo.disabled; do
        echo "  $f"
    done
else
    echo "  (无)"
fi
