#!/bin/bash
# 查看 conda 当前镜像源配置
#
# 关注点：仅看 channels 不够——defaults 实际指向哪由 default_channels 决定，
#         conda-forge 等社区 channel 由 custom_channels / channel_alias 决定。
#         这几个键才是「实际生效的源」，必须一并查看。

if ! command -v conda >/dev/null 2>&1; then
    echo "未检测到 conda 命令"
    exit 1
fi

echo "========== conda 实际生效的源配置 =========="
conda config --show channels default_channels custom_channels channel_alias show_channel_urls 2>/dev/null \
    || echo "暂无 conda 配置"
echo ""

echo "========== ~/.condarc 文件内容 =========="
if [[ -f "$HOME/.condarc" ]]; then
    cat "$HOME/.condarc"
else
    echo "(~/.condarc 不存在，使用 conda 内置默认源)"
fi
