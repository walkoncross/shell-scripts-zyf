#!/bin/bash
# 查看 Homebrew 当前镜像源配置

# 检测 shell 类型，确定 rc 文件
case "$(basename "$SHELL")" in
    bash) RC_FILE="$HOME/.bash_profile" ;;
    *)    RC_FILE="$HOME/.zshrc" ;;
esac

echo "当前 Homebrew 远程地址："
git -C "$(brew --repo)" remote get-url origin 2>/dev/null || echo "无法获取 Homebrew 远程地址"
echo ""
echo "$RC_FILE 中的 Homebrew 环境变量："
sed -n '/>>> homebrew mirror >>>/,/<<< homebrew mirror <<</p' "$RC_FILE" 2>/dev/null || echo "  无"
