#!/bin/bash
# OSS 同步上传脚本
# 用法: ./ossutil_sync_up.sh <本地目录> <远程目录|完整OSS路径>

set -euo pipefail

# 参数验证
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "错误: 参数数量不正确"
    echo ""
    echo "用法: $0 <本地目录> [远程目录|完整OSS路径]"
    echo ""
    echo "示例 1 - 同步到 bucket 根目录（省略第二个参数）:"
    echo "  $0 /path/to/local/folder"
    echo "  → 同步到: oss://lattebank-aigc-bigdataprod/"
    echo ""
    echo "示例 2 - 同步到指定子目录:"
    echo "  $0 /path/to/local/folder remote/folder"
    echo "  → 同步到: oss://lattebank-aigc-bigdataprod/remote/folder/"
    echo ""
    echo "示例 3 - 使用完整 OSS 路径:"
    echo "  $0 /path/to/local/folder oss://another-bucket/remote/folder"
    echo "  → 同步到: oss://another-bucket/remote/folder/"
    echo ""
    echo "注意:"
    echo "  - 第二个参数可选，默认同步到 bucket 根目录"
    echo "  - 脚本会自动移除路径末尾的斜杠"
    echo "  - 同步的是目录内容，不会创建同名子目录"
    echo ""
    echo "环境变量:"
    echo "  OSS_BUCKET - 自定义默认 bucket (默认: oss://lattebank-aigc-bigdataprod)"
    exit 1
fi

local_folder="$1"
remote_folder="${2:-.}"  # 如果第二个参数为空，默认使用 "."

# 移除路径末尾的斜杠（如果有）
# 原因：ossutil sync 对末尾斜杠敏感
# - 源路径有 /：同步目录本身（会创建同名子目录）
# - 源路径无 /：同步目录内容（推荐）
local_folder="${local_folder%/}"
remote_folder="${remote_folder%/}"

# 验证本地目录是否存在
if [ ! -d "$local_folder" ]; then
    echo "错误: 本地目录不存在: $local_folder"
    exit 1
fi

# 判断 remote_folder 是否已经是完整的 OSS 路径
if [[ "$remote_folder" =~ ^oss:// ]]; then
    # 已经是完整路径，直接使用
    full_remote_folder="$remote_folder"
    echo "检测到完整 OSS 路径，直接使用"
elif [[ "$remote_folder" == "." ]]; then
    # 使用 . 表示 bucket 根目录
    oss_bucket="${OSS_BUCKET:-oss://lattebank-aigc-bigdataprod}"
    full_remote_folder="$oss_bucket"
    echo "同步到 bucket 根目录"
else
    # 配置 OSS bucket（可通过环境变量覆盖）
    oss_bucket="${OSS_BUCKET:-oss://lattebank-aigc-bigdataprod}"
    # 相对路径，需要拼接 bucket
    full_remote_folder="${oss_bucket}/${remote_folder}"
fi

# 检查 ossutil 是否安装
if ! command -v ossutil &> /dev/null; then
    echo "错误: ossutil 未安装或不在 PATH 中"
    exit 1
fi

# 显示同步信息
echo "=========================================="
echo "OSS 同步上传"
echo "=========================================="
echo "本地目录: $local_folder"
echo "远程路径: $full_remote_folder"
echo "同步模式: 仅上传新文件（--ignore-existing）"
echo "同步内容: 目录内容（不创建同名子目录）"
echo "=========================================="

# 执行同步
# 构建命令并执行（避免 eval，保留参数安全）
sync_cmd=(ossutil sync --ignore-existing "$local_folder" "$full_remote_folder")
echo "执行命令:"
echo "${sync_cmd[*]}"
echo "=========================================="
if "${sync_cmd[@]}"; then
    echo "✓ 同步完成"
    exit 0
else
    echo "✗ 同步失败"
    exit 1
fi