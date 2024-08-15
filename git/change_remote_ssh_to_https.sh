#!/bin/bash

# 获取当前目录下的所有文件夹
for dir in */; do
    echo "===================================================="
    # 跳过包含 "zyf" 的文件夹
    if [[ "$dir" == *zyf* ]]; then
        echo "Skipping directory: $dir (contains 'zyf')"
        continue
    fi

    # 检查该目录是否为git仓库
    if [ -d "$dir/.git" ]; then
        echo "Processing directory: $dir"
        
        # 切换到该目录
        cd "$dir"

        # 获取当前的remote URL
        current_url=$(git remote get-url origin)
        echo "Current URL: $current_url"

        # https_url=$(echo $current_url | sed 's/com:/com\//g')
        # https_url=$(echo $current_url | sed 's/https\//https:/g')

        # git remote set-url origin "$https_url" 

        # 如果remote URL是SSH格式
        if [[ $current_url == git@* ]]; then
            echo "Current SSH URL: $current_url"

            # 将SSH格式的URL替换为HTTPS格式
            https_url=$(echo "$current_url" | sed  -e 's/:/\//' -e 's/git@/https:\/\//')
            # https_url=$(echo "$current_url" | sed -e 's/git@/https:\/\//' -e 's/:/\//')
            # https_url=$(echo $current_url | sed 's/:/\//g')


            echo "New HTTPS URL: $https_url"

            # 更新remote URL
            git remote set-url origin "$https_url"
            echo "Remote URL updated to HTTPS."

        else
            echo "Remote URL is already in HTTPS format or unrecognized."
        fi

        # 返回上一层目录
        cd ..
    fi
done

echo "All done!"
