#!/bin/bash

# ======================== 命令行参数解析 ========================
all_branches=false
root_dir="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all-branches)
            all_branches=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项] [目录]"
            echo "选项:"
            echo "  --all-branches  拉取远端所有分支（默认只拉取当前分支）"
            echo "  -h, --help      显示帮助信息"
            echo ""
            echo "参数:"
            echo "  目录            要处理的根目录（默认为当前目录）"
            exit 0
            ;;
        -*)
            echo "未知参数: $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
        *)
            root_dir="$1"
            shift
            ;;
    esac
done

if [ "${all_branches}" = true ]; then
    echo "模式：拉取所有远程分支"
fi

echo "要处理的目录为: $root_dir"

# 检查根目录是否存在并且是一个目录
if [ ! -d "$root_dir" ]; then
    echo "错误：$root_dir 不是一个有效的目录"
    exit 1
fi

# 遍历根目录下的所有子目录
for dir in "$root_dir"/*/; do
    # 检查是否为目录
    if [ -d "$dir" ]; then
        echo "进入目录: $dir"
        cd "$dir" || exit

        # 检查是否是git仓库
        if [ -d ".git" ]; then
            # 查找URL中包含gitlab的remote
            gitlab_remote=$(git remote -v | grep -i "gitlab" | grep "(fetch)" | head -n 1 | awk '{print $1}')

            if [ -n "$gitlab_remote" ]; then
                echo "找到 GitLab remote: $gitlab_remote"

                if [ "${all_branches}" = true ]; then
                    # 拉取所有分支模式
                    # 记录当前分支，以便操作完成后切回
                    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

                    echo "执行 git fetch $gitlab_remote"
                    git fetch "$gitlab_remote" || {
                        echo "错误：git fetch $gitlab_remote 执行失败，跳过该仓库"
                        cd - > /dev/null || exit
                        continue
                    }

                    # 为每个远程分支创建/更新本地跟踪分支
                    for remote_branch in $(git branch -r | grep "^  ${gitlab_remote}/" | grep -v '\->'); do
                        local_branch="${remote_branch#${gitlab_remote}/}"
                        # 去除前后空格
                        local_branch=$(echo "${local_branch}" | xargs)
                        remote_branch=$(echo "${remote_branch}" | xargs)
                        if ! git show-ref --verify --quiet "refs/heads/${local_branch}"; then
                            git branch --track "${local_branch}" "${remote_branch}" 2>/dev/null && \
                                echo "  创建本地分支：${local_branch} -> ${remote_branch}"
                        else
                            # 本地分支已存在，尝试快进合并
                            echo "  更新本地分支：${local_branch}"
                            git checkout "${local_branch}" 2>/dev/null && \
                                git merge --ff-only "${remote_branch}" 2>/dev/null
                        fi
                    done

                    # 切回之前的分支
                    if [ -n "${current_branch}" ]; then
                        git checkout "${current_branch}" 2>/dev/null
                    fi
                else
                    echo "执行 git pull $gitlab_remote"
                    git pull "$gitlab_remote"
                fi
            else
                echo "$dir 没有找到 GitLab remote，跳过"
            fi
        else
            echo "$dir 不是一个git仓库，跳过"
        fi

        # 返回上一层目录
        cd - > /dev/null || exit
    fi
done
