#!/bin/bash

# 检查是否提供了至少一个参数
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 url_list_path [output_dir] [url_prefix]"
    exit 1
fi

# 第一个参数是必需的，是URL列表文件的路径
url_list_path="$1"

# 第二个参数是可选的，是输出目录
output_dir="${2:-$(pwd)}"  # 如果未提供output_dir，使用当前目录

# 第三个参数是可选的，是URL前缀
url_prefix="${3:-}"

# 检查输出目录是否存在，不存在则创建
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

# 从url_list_path文件读取URL，并逐个下载
while IFS= read -r url; do
    echo "---------------------------------------"
    echo "Process url: $url"
    echo "---------------------------------------"

    # 如果提供了URL前缀，则将其与URL拼接
    full_url="${url_prefix}${url}"

    echo "full url: $full_url"

    # 使用wget --spider模式检查URL是否有效（文件是否存在）
    wget --spider "$full_url"
    if [ $? -ne 0 ]; then
        echo "Error: URL does not exist - $full_url"
        continue
    fi

    # 提取URL中的文件名
    file_name=$(basename "$url")

    # 检查文件是否已经存在
    if [ -f "$output_dir/$file_name" ]; then
        echo "Skipping: $file_name already exists."
        continue
    fi

    # 使用wget --spider模式获取文件大小信息
    file_size=$(wget -S --spider "$full_url" 2>&1 | grep Length | awk '{print $2}')
    echo "file size: $file_size"
    file_size=$(($file_size/1024))
    echo "file size: $file_size KB"

    # 获取可用磁盘空间
    available_space=$(df -k "$output_dir" | tail -1 | awk '{print $4}')
    echo "available_space: $available_space KB"

    # 比较文件大小和可用磁盘空间（均以kB为单位）
    if [ "$file_size" -gt "$available_space" ]; then
        echo "Error: Not enough disk space for $file_name"
        exit 1
    fi

    echo "Downloading from: $full_url"

    # 使用wget下载文件到指定的输出目录
    wget -c -q -P "$output_dir" "$full_url"
    if [ $? -eq 0 ]; then
        echo "Downloaded: $full_url"
    else
        echo "Failed to download: $full_url"
    fi
done < "$url_list_path"