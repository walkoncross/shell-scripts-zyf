#!/bin/bash

# 检查是否传入了两个参数
if [[ $# -ne 2 ]]; then
    echo "用法: $0 <folder1路径> <folder2路径>"
    exit 1
fi

# 从命令行参数获取文件夹路径
folder1="$1"
folder2="$2"

# 检查文件夹是否存在
if [[ ! -d "$folder1" ]]; then
    echo "文件夹 $folder1 不存在"
    exit 1
fi

if [[ ! -d "$folder2" ]]; then
    echo "文件夹 $folder2 不存在"
    exit 1
fi

# 根据系统平台获取 md5 命令
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    md5_command="md5sum"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    md5_command="md5"
else
    echo "不支持的操作系统: $OSTYPE"
    exit 1
fi

# 遍历 folder1 中的文件
for file1 in "$folder1"/*; do
    # 获取文件名
    filename=$(basename "$file1")
    file2="$folder2/$filename"

    # 检查 folder2 中是否存在相同文件名的文件
    if [[ -f "$file2" ]]; then
        # 计算两个文件的 MD5 值
        if [[ "$md5_command" == "md5sum" ]]; then
            md5_file1=$(md5sum "$file1" | awk '{ print $1 }')
            md5_file2=$(md5sum "$file2" | awk '{ print $1 }')
        else
            md5_file1=$(md5 -q "$file1")
            md5_file2=$(md5 -q "$file2")
        fi

        # 比较 MD5 值
        if [[ "$md5_file1" == "$md5_file2" ]]; then
            echo "文件 $filename 的 MD5 值一致"
        else
            echo "文件 $filename 的 MD5 值不一致"
        fi
    else
        echo "文件 $filename 不存在于 $folder2"
    fi
done
