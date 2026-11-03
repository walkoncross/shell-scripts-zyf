#!/bin/bash

# 文件列表作为参数传入
file_list=("$@")

# 循环处理每个文件
for file in "${file_list[@]}"; do
    # 获取文件的绝对路径
    abs_path=$(realpath "$file")
    
    # 检查文件是否存在
    if [ ! -e "$abs_path" ]; then
        echo "文件不存在: $file"
        continue
    fi

    # 获取文件名
    filename=$(basename "$abs_path")

    # 创建软链接到home目录
    ln -s "$abs_path" "$HOME/$filename"

    # 显示软链接创建的信息
    echo "已创建软链接: $HOME/$filename -> $abs_path"
done
