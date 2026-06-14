#!/bin/bash
# 查看 conda 当前镜像源配置

echo "当前 conda 镜像源："
conda config --show channels 2>/dev/null || echo "暂无 conda 配置"
