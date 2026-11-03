#!/bin/bash
# conda 换源脚本
# 用法: ./switch_conda_mirror.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源
#
# 原理：conda 的 channels 列表只决定「用哪些 channel」，而这些 channel 实际
#       解析到哪个 URL 由 default_channels(对应 defaults) 和 custom_channels/
#       channel_alias(对应 conda-forge 等社区 channel) 决定。只往 channels
#       里加镜像地址、不改后两者，defaults 和 conda-forge 仍会走官方源。
#       因此本脚本直接写完整 ~/.condarc(含备份)，与 apt/yum 脚本保持一致。

MIRROR="${1:-aliyun}"
CONDARC="$HOME/.condarc"
BACKUP="$CONDARC.bak"

echo "当前 conda 配置(channels / default_channels / channel_alias)："
conda config --show channels default_channels channel_alias custom_channels 2>/dev/null || echo "暂无 conda 配置"
echo ""

# 根据镜像选择 anaconda 镜像根地址(三家目录结构一致：pkgs/main、pkgs/r、cloud/)
case "$MIRROR" in
    tuna)
        BASE="https://mirrors.tuna.tsinghua.edu.cn/anaconda"
        ;;
    ustc)
        BASE="https://mirrors.ustc.edu.cn/anaconda"
        ;;
    aliyun)
        BASE="https://mirrors.aliyun.com/anaconda"
        ;;
    restore)
        echo "恢复 conda 官方源..."
        if [[ -f "$BACKUP" ]]; then
            cp "$BACKUP" "$CONDARC"
            echo "已从备份恢复: $BACKUP"
        else
            # 无备份则移除镜像相关键，回退到 conda 内置默认源
            for key in channels default_channels custom_channels channel_alias show_channel_urls; do
                conda config --remove-key "$key" 2>/dev/null || true
            done
            echo "未找到备份，已移除镜像相关配置键，回退到内置默认源"
        fi
        conda clean -i -y 2>/dev/null || true   # 清索引缓存，避免沿用旧源元数据
        echo ""
        echo "当前 conda 配置："
        conda config --show channels default_channels channel_alias 2>/dev/null
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR ($BASE)"

# 备份原始 ~/.condarc(仅首次，避免覆盖已有备份)
if [[ -f "$CONDARC" && ! -f "$BACKUP" ]]; then
    cp "$CONDARC" "$BACKUP"
    echo "已备份原始配置到: $BACKUP"
fi

# 写入完整 .condarc（default_channels 解析 defaults，custom_channels 解析社区 channel）
cat > "$CONDARC" <<EOF
channels:
  - defaults
show_channel_urls: true
default_channels:
  - ${BASE}/pkgs/main
  - ${BASE}/pkgs/r
  - ${BASE}/pkgs/msys2
custom_channels:
  conda-forge: ${BASE}/cloud
  pytorch: ${BASE}/cloud
  bioconda: ${BASE}/cloud
  msys2: ${BASE}/cloud
  menpo: ${BASE}/cloud
  simpleitk: ${BASE}/cloud
EOF

echo "已写入 $CONDARC"
conda clean -i -y 2>/dev/null || true   # 清索引缓存，确保下次解析用新源
echo ""
echo "当前 conda 配置："
conda config --show channels default_channels channel_alias custom_channels 2>/dev/null
