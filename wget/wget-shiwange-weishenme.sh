#!/bin/bash

# 创建保存 PDF 文件的文件夹
download_folder="pdf_files"
mkdir -p "$download_folder"

# 基本的 URL 格式
base_url="https://yaya.csoci.com:1314/toys/ending/%E5%8D%81%E4%B8%87%E4%B8%AA%E4%B8%BA%E4%BB%80%E4%B9%88wg%E7%89%88/%E5%8D%81%E4%B8%87%E4%B8%AA%E4%B8%BA%E4%BB%80%E4%B9%88"

# 循环下载从 01 到 21 的 PDF 文件
for vol in $(seq -f "%02g" 1 21); do
    # 构建文件的完整 URL
    url="${base_url}(${vol}).pdf"
    
    # 使用 wget 下载 PDF 文件
    wget -P "$download_folder" "$url"
    
    # 检查 wget 是否成功
    if [ $? -eq 0 ]; then
        echo "Downloaded: ${vol}.pdf"
    else
        echo "Failed to download: ${vol}.pdf"
    fi
done
