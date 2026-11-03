#!/bin/bash
#
# 拉取指定远端的所有分支，并对本地分支做快进更新
# - 本地缺失的分支：创建跟踪分支
# - 本地已存在的分支：仅在可快进时更新，不改写历史
# - 非当前分支：直接快进引用，不切换工作区
# - 当前分支：git merge --ff-only（工作区有冲突改动时跳过）
# 分叉、本地领先、工作区改动导致失败的分支都会被跳过并汇总
# 默认远端：origin
# 默认仓库：当前工作目录
#
# 用法: ./git_pull_all_branches.sh [选项] [仓库目录]

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
    echo "  $0                          # 更新当前仓库 origin 的所有分支"
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

# 当前分支（分离 HEAD 时为空）
current_branch=$(git -C "$REPO_DIR" symbolic-ref --quiet --short HEAD 2>/dev/null || true)

# ======================== 逐分支快进 ========================
created=0
updated=0
uptodate=0
ahead=0
diverged=0
skipped=0
failed=0

created_list=()
updated_list=()
ahead_list=()
diverged_list=()
skipped_list=()
failed_list=()

while IFS= read -r ref; do
    [ -n "$ref" ] || continue

    # refs/remotes/origin/feature/x -> feature/x
    local_branch="${ref#refs/remotes/$REMOTE/}"

    # 跳过远端 HEAD 符号引用
    [ "$local_branch" = "HEAD" ] && continue

    remote_sha=$(git -C "$REPO_DIR" rev-parse --verify --quiet "$ref") || continue

    # 本地不存在：创建跟踪分支
    if ! git -C "$REPO_DIR" show-ref --verify --quiet "refs/heads/$local_branch"; then
        if git -C "$REPO_DIR" branch --track "$local_branch" "$ref" >/dev/null 2>&1; then
            echo "  新建: $local_branch <- $REMOTE/$local_branch"
            created=$((created + 1))
            created_list+=("$local_branch")
        else
            echo "  创建失败: $local_branch"
            failed=$((failed + 1))
            failed_list+=("$local_branch")
        fi
        continue
    fi

    local_sha=$(git -C "$REPO_DIR" rev-parse --verify "refs/heads/$local_branch")

    # 已是最新
    if [ "$local_sha" = "$remote_sha" ]; then
        uptodate=$((uptodate + 1))
        continue
    fi

    # 本地领先远端：不回退，仅提示
    if git -C "$REPO_DIR" merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null; then
        echo "  本地领先，跳过: $local_branch"
        ahead=$((ahead + 1))
        ahead_list+=("$local_branch")
        continue
    fi

    # 历史分叉：不做合并/变基，避免改历史
    if ! git -C "$REPO_DIR" merge-base --is-ancestor "$local_sha" "$remote_sha" 2>/dev/null; then
        echo "  历史分叉，跳过: $local_branch"
        diverged=$((diverged + 1))
        diverged_list+=("$local_branch")
        continue
    fi

    # 可快进
    if [ "$local_branch" = "$current_branch" ]; then
        # 当前分支：需要动工作区，脏工作区可能失败
        if git -C "$REPO_DIR" merge --ff-only "$remote_sha" >/dev/null 2>&1; then
            echo "  快进(当前分支): $local_branch"
            updated=$((updated + 1))
            updated_list+=("$local_branch")
        else
            echo "  快进失败(工作区有改动)，跳过: $local_branch"
            skipped=$((skipped + 1))
            skipped_list+=("$local_branch")
        fi
    else
        # 非当前分支：直接移动引用，不切分支、不碰工作区
        if git -C "$REPO_DIR" update-ref "refs/heads/$local_branch" "$remote_sha" "$local_sha" 2>/dev/null; then
            echo "  快进: $local_branch"
            updated=$((updated + 1))
            updated_list+=("$local_branch")
        else
            echo "  快进失败: $local_branch"
            failed=$((failed + 1))
            failed_list+=("$local_branch")
        fi
    fi
done < <(git -C "$REPO_DIR" for-each-ref --format='%(refname)' "refs/remotes/$REMOTE")

# ======================== 结果汇总 ========================
echo ""
echo "完成：新建 $created 个，快进 $updated 个，已最新 $uptodate 个"
echo "      本地领先 $ahead 个，分叉跳过 $diverged 个，快进失败 $skipped 个，其他失败 $failed 个"

print_list() {
    local title="$1"
    shift
    [ $# -gt 0 ] || return 0
    echo ""
    echo "$title:"
    printf '  - %s\n' "$@"
}

print_list "本地领先（未推送的提交）" "${ahead_list[@]+"${ahead_list[@]}"}"
print_list "历史分叉（需手动处理）" "${diverged_list[@]+"${diverged_list[@]}"}"
print_list "工作区改动导致快进失败" "${skipped_list[@]+"${skipped_list[@]}"}"
print_list "失败" "${failed_list[@]+"${failed_list[@]}"}"

[ "$failed" -eq 0 ]
