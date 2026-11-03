#!/bin/bash
# Homebrew 换源脚本
# 用法: ./switch_brew_mirror.sh [tuna|ustc|aliyun|restore]
# 默认使用 aliyun 源；restore 恢复官方源
#
# 原理：brew update 每次都会按 HOMEBREW_BREW_GIT_REMOTE / HOMEBREW_CORE_GIT_REMOTE
#       环境变量重置 git remote。所以换源的关键是写对这些环境变量；
#       只用 git remote set-url 改地址，会被下一次 brew update 覆盖回去。

MIRROR="${1:-aliyun}"

# 检测 shell 类型，确定要写入的 rc 文件
case "$(basename "$SHELL")" in
    bash) RC_FILE="$HOME/.bash_profile" ;;
    *)    RC_FILE="$HOME/.zshrc" ;;
esac

BREW_REPO="$(brew --repo)"

# 标记块起止标记（统一来源，便于增删）
BEGIN_MARK='# >>> homebrew mirror >>>'
END_MARK='# <<< homebrew mirror <<<'

# 清理所有 rc 文件中的镜像配置：标记块 + 散落在外、未注释的 HOMEBREW 镜像变量。
# 目的是消除 .zprofile / .profile / .bash_profile 等处写死的旧值，
# 确保镜像配置只有「本脚本的标记块」这一处来源，避免互相覆盖。
clean_mirror_config() {
    for f in "$HOME/.zprofile" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$f" ] || continue
        # 删除标记块（兼容新旧两种格式）
        sed -i '' '/>>> homebrew mirror >>>/,/<<< homebrew mirror <<</d' "$f" 2>/dev/null
        # 删除散落在标记块外、未注释的镜像环境变量（^[[:space:]]*export 不会匹配 # 注释行）
        sed -i '' '/^[[:space:]]*export HOMEBREW_BREW_GIT_REMOTE=/d' "$f" 2>/dev/null
        sed -i '' '/^[[:space:]]*export HOMEBREW_CORE_GIT_REMOTE=/d' "$f" 2>/dev/null
        sed -i '' '/^[[:space:]]*export HOMEBREW_API_DOMAIN=/d' "$f" 2>/dev/null
        sed -i '' '/^[[:space:]]*export HOMEBREW_BOTTLE_DOMAIN=/d' "$f" 2>/dev/null
        sed -i '' '/^[[:space:]]*export HOMEBREW_NO_AUTO_UPDATE=/d' "$f" 2>/dev/null
    done
}

# 修改 git remote（仅作即时生效用；真正的持久化靠环境变量）
set_git_remote() {
    local brew_url="$1" core_url="$2"
    git -C "$BREW_REPO" remote set-url origin "$brew_url"
    # homebrew-core 在新版 brew 下可能未 clone（改用 JSON API），存在才改
    local core_repo
    core_repo="$(brew --repo homebrew/core 2>/dev/null)"
    if [ -n "$core_repo" ] && [ -d "$core_repo/.git" ]; then
        git -C "$core_repo" remote set-url origin "$core_url"
    fi
}

echo "当前 Homebrew 远程地址："
git -C "$BREW_REPO" remote get-url origin 2>/dev/null || echo "无法获取 Homebrew 远程地址"
echo ""

# 根据镜像选择地址（API 域名用于新版 brew 拉取 formula 元数据）
case "$MIRROR" in
    tuna)
        BREW_GIT="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
        CORE_GIT="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
        BOTTLE="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
        API="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
        ;;
    ustc)
        BREW_GIT="https://mirrors.ustc.edu.cn/brew.git"
        CORE_GIT="https://mirrors.ustc.edu.cn/homebrew-core.git"
        BOTTLE="https://mirrors.ustc.edu.cn/homebrew-bottles"
        API="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
        ;;
    aliyun)
        BREW_GIT="https://mirrors.aliyun.com/homebrew/brew.git"
        CORE_GIT="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
        BOTTLE="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
        API="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
        ;;
    restore)
        echo "恢复 Homebrew 官方源..."
        clean_mirror_config
        set_git_remote "https://github.com/Homebrew/brew.git" \
                       "https://github.com/Homebrew/homebrew-core.git"
        echo "已清理各 rc 文件中的 Homebrew 镜像环境变量"
        echo "注意：当前 shell 仍残留旧环境变量，请重启终端或执行 source $RC_FILE 后再使用"
        echo ""
        echo "验证当前 Homebrew 远程地址："
        git -C "$BREW_REPO" remote get-url origin
        exit 0
        ;;
    *)
        echo "不支持的镜像源: $MIRROR"
        echo "可选值: tuna, ustc, aliyun, restore"
        exit 1
        ;;
esac

echo "使用镜像源: $MIRROR"

# 1) 立即改 git remote（本次即时可见；因环境变量同步更新，下次 update 不会被改回）
set_git_remote "$BREW_GIT" "$CORE_GIT"

# 2) 清理旧配置后，写入统一的镜像环境变量标记块（单一来源）
clean_mirror_config
{
    echo "$BEGIN_MARK"
    echo "export HOMEBREW_BREW_GIT_REMOTE=$BREW_GIT"
    echo "export HOMEBREW_CORE_GIT_REMOTE=$CORE_GIT"
    echo "export HOMEBREW_API_DOMAIN=$API"
    echo "export HOMEBREW_BOTTLE_DOMAIN=$BOTTLE"
    echo "export HOMEBREW_NO_AUTO_UPDATE=1"
    echo "$END_MARK"
} >> "$RC_FILE"

echo "环境变量已写入 $RC_FILE ，执行 source $RC_FILE 使其生效"
echo ""
echo "验证当前 Homebrew 远程地址："
git -C "$BREW_REPO" remote get-url origin
