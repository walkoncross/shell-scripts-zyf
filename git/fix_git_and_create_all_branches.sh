#!/bin/bash

set -u

echo "============================================="
echo " Git 单分支修复 + 批量创建所有本地分支"
echo " 作用：修复 --depth / --single-branch"
echo "       并自动创建本地所有远端分支"
echo "============================================="
echo

for dir in */; do
    dir_name="${dir%/}"
    echo -e "\n=================================================="
    echo "处理目录：$dir_name"

    if [ ! -d "$dir/.git" ]; then
        echo "❌ 不是 Git 仓库，跳过"
        continue
    fi

    (
        cd "$dir" || exit 1
        echo "✅ 是 Git 仓库"

        # 检查 origin URL 是否包含 caijj，不含则跳过
        origin_url=$(git config --get remote.origin.url || true)
        if [[ "$origin_url" != *"caijj"* ]]; then
            echo "⏭️  origin 不含 caijj，跳过（$origin_url）"
            exit 0
        fi

        # 修复单分支配置
        fetch_cfg=$(git config --get remote.origin.fetch || true)
        if [[ "$fetch_cfg" != *'*'* ]]; then
            echo "⚠️  单分支仓库，开始修复..."
            git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        fi

        # 解除浅克隆
        if [ -f ".git/shallow" ]; then
            echo "📥 浅克隆仓库，执行 unshallow..."
            if ! git fetch --unshallow --quiet 2>&1; then
                echo "   ⚠️  unshallow 失败（网络问题或仓库不可访问），跳过"
            fi
        fi

        # 拉全部分支信息
        echo "🔄 拉取所有远端分支..."
        if ! git fetch --all --prune --quiet 2>&1; then
            echo "   ⚠️  fetch 失败（网络问题或仓库不可访问），跳过分支创建"
            exit 0
        fi

        # 获取所有远端分支
        echo "🌱 自动创建本地缺失的分支..."
        git branch -r | grep -v '\->' | while read -r remote_branch; do
            local_branch="${remote_branch#origin/}"
            if ! git show-ref --verify --quiet "refs/heads/$local_branch"; then
                git branch --track "$local_branch" "$remote_branch"
                echo "   ✅ 创建本地分支：$local_branch"
            fi
        done

        echo "🎉 完成：$dir_name"
    )
done

echo -e "\n============================================="
echo "✅ 所有仓库处理完成！"
echo "现在你本地已经拥有远端全部分支啦！"
echo "============================================="
