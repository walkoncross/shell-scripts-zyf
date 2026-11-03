#!/bin/bash

# 如果有输入参数，使用该参数作为根目录，否则使用当前目录
root_dir="${1:-.}"

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
        
        pip install -e .

        if [ $? -ne 0 ]; then
            echo "pip install 失败，跳过"
        fi
        # 返回上一层目录
        cd - > /dev/null || exit
    fi
done
