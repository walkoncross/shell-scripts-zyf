#!/bin/bash
# =============================================================
# compress_pdf_scan.sh — 压缩扫描 PDF（降采样 + JPEG 重编码）
#
# 适用场景: 400dpi 等高清扫描件（护照、证件、居留许可等）体积过大时，
#           用 Ghostscript 将内部图片降采样到目标 DPI 并提高压缩率。
#
# 用法:
#   compress_pdf_scan.sh <输入.pdf> [输出.pdf] [dpi=200] [jpeg质量=80]
#
# 示例:
#   compress_pdf_scan.sh scan-400dpi.pdf              # 默认 200dpi/q80
#   compress_pdf_scan.sh scan-400dpi.pdf out.pdf 150   # 150dpi
#   compress_pdf_scan.sh scan-400dpi.pdf out.pdf 300 60 # 300dpi, 低质量
#
# 注意:
#   - 依赖 Ghostscript (gs), macOS 可用 `brew install ghostscript`
#   - 必须加 -dPassThroughJPEGImages=false 和 -dImageDownsampleThreshold=1,
#     否则 gs 会对接近源分辨率的图直通复用原流, 导致压缩无效
# =============================================================
set -euo pipefail

# ---------- 参数解析 ----------
input="${1:-}"
dpi="${3:-200}"
jpeg_q="${4:-80}"
output="${2:-${input%.pdf}_${dpi}dpi.pdf}"

if [[ -z "$input" ]]; then
    echo "用法: $0 <输入.pdf> [输出.pdf] [dpi=200] [jpeg质量=80]"
    exit 1
fi

# ---------- 输入检查 ----------
if [[ ! -f "$input" ]]; then
    echo "错误: 输入文件不存在: $input"
    exit 1
fi

if ! command -v gs >/dev/null 2>&1; then
    echo "错误: 未找到 gs (Ghostscript), 请先安装: brew install ghostscript"
    exit 1
fi

# ---------- 压缩 ----------
echo "压缩中: $input -> $output (${dpi}dpi, JPEG质量${jpeg_q}) ..."
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
   -dPassThroughJPEGImages=false \
   -dImageDownsampleThreshold=1 \
   -dDownsampleColorImages=true \
   -dColorImageResolution="$dpi" \
   -dColorImageDownsampleType=/Bicubic \
   -dAutoFilterColorImages=false \
   -dColorImageFilter=/DCTEncode \
   -dJPEGQ="$jpeg_q" \
   -dNOPAUSE -dQUIET -dBATCH \
   -sOutputFile="$output" "$input"

# ---------- 结果 ----------
if [[ -f "$output" ]]; then
    echo "完成: $input -> $output"
    ls -lh "$output" | awk '{print "输出大小: " $5}'
else
    echo "错误: 压缩失败, 未生成输出文件"
    exit 1
fi
