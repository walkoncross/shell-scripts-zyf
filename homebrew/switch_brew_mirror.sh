#!/bin/bash
# Homebrew 换源脚本
# 用法: ./switch_brew_mirror.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源

MIRROR="${1:-aliyun}"

echo "当前 Homebrew 远程地址："
git -C "$(brew --repo)" remote get-url origin 2>/dev/null || echo "无法获取 Homebrew 远程地址"
echo ""

# 根据镜像选择地址
case "$MIRROR" in
    tuna)
        BREW_GIT="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
        CORE_GIT="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
        CASK_GIT="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"
        BOTTLE="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
        ;;
    ustc)
        BREW_GIT="https://mirrors.ustc.edu.cn/brew.git"
        CORE_GIT="https://mirrors.ustc.edu.cn/homebrew-core.git"
        CASK_GIT="https://mirrors.ustc.edu.cn/homebrew-cask.git"
        BOTTLE="https://mirrors.ustc.edu.cn/homebrew-bottles"
        ;;
    aliyun)
        BREW_GIT="https://mirrors.aliyun.com/homebrew/brew.git"
        CORE_GIT="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
        CASK_GIT="https://mirrors.aliyun.com/homebrew/homebrew-cask.git"
        BOTTLE="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
        ;;
    restore)
        echo "恢复 Homebrew 官方源..."
        git -C "$(brew --repo)" remote set-url origin https://github.com/Homebrew/brew.git
        # git -C "$(brew --repo homebrew/core)" remote set-url origin https://github.com/Homebrew/homebrew-core.git
        # git -C "$(brew --repo homebrew/cask)" remote set-url origin https://github.com/Homebrew/homebrew-cask.git
        echo "已恢复官方源"
        sed -i '' '/>>> homebrew mirror >>>/,/<<< homebrew mirror <<</d' ~/.zshrc 2>/dev/null
        echo "已清理 ~/.zshrc 中的 Homebrew 环境变量"
        echo "验证当前 Homebrew 远程地址："
        git -C "$(brew --repo)" remote get-url origin
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR"

# 替换 Homebrew 仓库远程地址
git -C "$(brew --repo)" remote set-url origin "$BREW_GIT"
# git -C "$(brew --repo homebrew/core)" remote set-url origin "$CORE_GIT"
# git -C "$(brew --repo homebrew/cask)" remote set-url origin "$CASK_GIT"

# 写入环境变量到 ~/.zshrc（标记块方式，避免重复）
sed -i '' '/>>> homebrew mirror >>>/,/<<< homebrew mirror <<</d' ~/.zshrc 2>/dev/null
{
    echo '# >>> homebrew mirror >>>'
    echo "export HOMEBREW_BOTTLE_DOMAIN=$BOTTLE"
    echo 'export HOMEBREW_NO_AUTO_UPDATE=1'
    echo '# <<< homebrew mirror <<<'
} >> ~/.zshrc

echo "环境变量已写入 ~/.zshrc，执行 source ~/.zshrc 使其生效"
echo ""
echo "验证当前 Homebrew 远程地址："
git -C "$(brew --repo)" remote get-url origin
