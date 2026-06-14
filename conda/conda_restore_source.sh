#!/bin/bash
# 重置 conda 为官方源

conda config --remove-key channels 2>/dev/null || true
conda config --remove-key show_channel_urls 2>/dev/null || true

echo "已重置为官方默认源"
echo "当前 conda 配置："
conda config --show channels
