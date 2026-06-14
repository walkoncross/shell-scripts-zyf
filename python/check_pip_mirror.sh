#!/bin/bash
# 查看 pip 当前镜像源配置

echo "当前 pip 镜像源："
pip config list 2>/dev/null || echo "暂无 pip 配置，使用官方默认源"
