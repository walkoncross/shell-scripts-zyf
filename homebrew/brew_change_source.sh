#!/bin/bash
# Homebrew 换源脚本
# 用法: ./brew_change_source.sh [--mirror <tuna|ustc|aliyun|restore>]
# 默认使用 ustc 源；--mirror restore 恢复官方源

# 解析参数
MIRROR="ustc"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mirror)
            MIRROR="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: $0 [--mirror <tuna|ustc|aliyun|restore>]"
            exit 1
            ;;
    esac
done

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
        echo "已恢复官方源，请手动删除 ~/.zshrc 中的 HOMEBREW_NO_AUTO_UPDATE 和 HOMEBREW_BOTTLE_DOMAIN 配置"
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR"

# 1. 禁用自动更新
echo 'export HOMEBREW_NO_AUTO_UPDATE=1' >> ~/.zshrc

# 2. 替换所有核心镜像
git -C "$(brew --repo)" remote set-url origin "$BREW_GIT"
# git -C "$(brew --repo homebrew/core)" remote set-url origin "$CORE_GIT"
# git -C "$(brew --repo homebrew/cask)" remote set-url origin "$CASK_GIT"

# 3. 启用国内二进制包源
echo "export HOMEBREW_BOTTLE_DOMAIN=$BOTTLE" >> ~/.zshrc

# 4. 修复 services 仓库，该仓库已经废弃
# cd /opt/homebrew/Library/Taps/homebrew/homebrew-services
# git remote add origin https://github.com/Homebrew/homebrew-services.git
# git fetch origin && git reset --hard origin/main

# 5. 生效配置
source ~/.zshrc
