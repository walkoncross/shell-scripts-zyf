#!/usr/bin/env bash
# 使用 python -m json.tool 美化 JSON 文件
# 用法: pretty-json.sh <infile> [outfile]

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <infile> [outfile]" >&2
    exit 1
fi

infile="$1"

if [[ ! -f "$infile" ]]; then
    echo "错误: 文件不存在: $infile" >&2
    exit 1
fi

if [[ $# -ge 2 ]]; then
    outfile="$2"
else
    # 取 basename 去掉原扩展名，拼接 -pretty.json
    base=$(basename "$infile")
    base="${base%.*}"
    outfile="${base}-pretty.json"
fi

python3 -m json.tool "$infile" "$outfile"
echo "输出: $outfile"
