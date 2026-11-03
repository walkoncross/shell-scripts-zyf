#!/bin/bash
#
# 拉取指定远端的所有分支，并为本地缺失的分支创建跟踪分支
# 默认远端：origin
# 默认仓库：当前工作目录
#
# 用法: ./git_fetch_all_branches.sh [选项] [仓库目录]

set -u

REMOTE="origin"
REPO_DIR="."

usage() {
    echo "用法: $0 [选项] [仓库目录]"
    echo ""
    echo "选项:"
    echo "  -r, --remote <名称>  指定远端名称（默认: origin）"
    echo "  -d, --dir <目录>     指定 Git 仓库目录（默认: 当前工作目录）"
    echo "  -h, --help           显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                          # 拉取当前仓库 origin 的所有分支"
    echo "  $0 -r upstream              # 使用 upstream 远端"
    echo "  $0 -d /path/to/repo         # 处理指定仓库"
    echo "  $0 -r upstream /path/to/repo"
    exit 0
}

# ======================== 参数解析 ========================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--remote)
            if [ $# -lt 2 ]; then
                echo "错误：$1 需要一个远端名称"
                exit 1
            fi
            REMOTE="$2"
            shift 2
            ;;
        --remote=*)
            REMOTE="${1#*=}"
            shift
            ;;
        -d|--dir)
            if [ $# -lt 2 ]; then
                echo "错误：$1 需要一个目录"
                exit 1
            fi
            REPO_DIR="$2"
            shift 2
            ;;
        --dir=*)
            REPO_DIR="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "未知参数: $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
        *)
            REPO_DIR="$1"
            shift
            ;;
    esac
done

# ======================== 前置检查 ========================
if [ ! -d "$REPO_DIR" ]; then
    echo "错误：$REPO_DIR 不是一个有效的目录"
    exit 1
fi

if ! git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    echo "错误：$REPO_DIR 不是一个 Git 仓库"
    exit 1
fi

if ! git -C "$REPO_DIR" remote get-url "$REMOTE" >/dev/null 2>&1; then
    echo "错误：仓库中不存在远端 '$REMOTE'"
    echo "当前远端列表："
    git -C "$REPO_DIR" remote -v
    exit 1
fi

echo "仓库目录: $REPO_DIR"
echo "远端名称: $REMOTE"
echo ""

# ======================== 修复单分支配置 ========================
# 使用 --single-branch / --depth 克隆的仓库，fetch 配置只包含当前分支，
# 这里改为拉取所有分支，否则无法发现其他远端分支
fetch_refspec=$(git -C "$REPO_DIR" config --get "remote.$REMOTE.fetch" || true)
if [[ "$fetch_refspec" != *'*'* ]]; then
    echo "检测到单分支配置，修复为拉取所有分支..."
    git -C "$REPO_DIR" config "remote.$REMOTE.fetch" "+refs/heads/*:refs/remotes/$REMOTE/*"
fi

# ======================== 拉取远端分支 ========================
echo "拉取远端分支..."
if ! git -C "$REPO_DIR" fetch "$REMOTE" --prune; then
    echo "错误：git fetch $REMOTE 执行失败"
    exit 1
fi

# ======================== 创建缺失的本地分支 ========================
created=0
existing=0
failed=0

while IFS= read -r ref; do
    [ -n "$ref" ] || continue

    # refs/remotes/origin/feature/x -> feature/x
    local_branch="${ref#refs/remotes/$REMOTE/}"

    # 跳过远端 HEAD 符号引用
    [ "$local_branch" = "HEAD" ] && continue

    # 本地已存在则跳过（不覆盖本地分支）
    if git -C "$REPO_DIR" show-ref --verify --quiet "refs/heads/$local_branch"; then
        existing=$((existing + 1))
        continue
    fi

    if git -C "$REPO_DIR" branch --track "$local_branch" "refs/remotes/$REMOTE/$local_branch" >/dev/null 2>&1; then
        echo "  创建本地分支: $local_branch -> $REMOTE/$local_branch"
        created=$((created + 1))
    else
        echo "  创建失败: $local_branch"
        failed=$((failed + 1))
    fi
done < <(git -C "$REPO_DIR" for-each-ref --format='%(refname)' "refs/remotes/$REMOTE")

# ======================== 结果汇总 ========================
echo ""
echo "完成：新建本地分支 $created 个，本地已存在 $existing 个，失败 $failed 个"

[ "$failed" -eq 0 ]
