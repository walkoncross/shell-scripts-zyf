#!/bin/bash
# 查看 apt 当前镜像源配置

SOURCES_LIST="/etc/apt/sources.list"

echo "当前 apt 源文件："
grep -v '^#' "$SOURCES_LIST" 2>/dev/null | grep -v '^$' || echo "  无法读取 $SOURCES_LIST"
