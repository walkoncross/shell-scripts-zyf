#!/bin/bash
# 查看 Homebrew 当前镜像源配置

echo "当前 Homebrew 远程地址："
git -C "$(brew --repo)" remote get-url origin 2>/dev/null || echo "无法获取 Homebrew 远程地址"
echo ""
echo "~/.zshrc 中的 Homebrew 环境变量："
sed -n '/^# >>> homebrew mirror >>>$/,/^# <<< homebrew mirror <<<$/p' ~/.zshrc 2>/dev/null || echo "  无"
