#!/bin/bash

echo "开始切换 Homebrew 镜像源到清华源..."

# 切换 brew.git 仓库
git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

# 切换 homebrew-core.git 仓库
git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

# 切换 homebrew-cask.git 仓库
git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git

# 设置 bottles 镜像
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

echo "镜像源切换完成！"

echo "开始清理 Homebrew 缓存..."
rm -rf ~/Library/Caches/Homebrew/*
brew cleanup -s

echo "强制更新 Homebrew..."
brew update --force --verbose

echo "完成！Homebrew 镜像已切换到清华源，缓存已清理，brew update 已完成。"
