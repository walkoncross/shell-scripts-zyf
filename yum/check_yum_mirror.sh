#!/bin/bash
# 查看 yum 当前镜像源配置

REPO_DIR="/etc/yum.repos.d"

echo "当前 yum 源文件："
if ls "$REPO_DIR"/*.repo &>/dev/null; then
    for f in "$REPO_DIR"/*.repo; do
        echo "  [$f]"
        grep -E '^(name|baseurl|mirrorlist|enabled)=' "$f" 2>/dev/null | sed 's/^/    /'
        echo ""
    done
else
    echo "  未找到 .repo 文件"
fi
