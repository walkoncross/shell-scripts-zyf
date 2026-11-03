#!/bin/bash

# 获取 root_dir 参数，默认为当前目录
root_dir="${1:-.}"

# 检查目录是否存在
if [ ! -d "$root_dir" ]; then
    echo "Error: Directory '$root_dir' does not exist."
    exit 1
fi

# 遍历指定目录及其子目录
find "$root_dir" -type f -name "*.ipynb" ! -name "*copy.ipynb" | while read -r file; do
    echo "Cleaning: $file"
    # 使用 nbstripout 清理
    nbstripout "$file"
    if [ $? -ne 0 ]; then
        echo "Error cleaning $file"
    fi
done