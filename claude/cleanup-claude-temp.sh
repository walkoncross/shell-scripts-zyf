#!/bin/bash
# 清理 ~/claude-temp 下超过 N 天未修改的文件和空目录
# 用法:
#   ./cleanup-claude-temp.sh              # 默认清理 30 天以前的文件
#   ./cleanup-claude-temp.sh 60           # 自定义天数
#   ./cleanup-claude-temp.sh --dry-run    # 仅预览,不实际删除

set -euo pipefail

# 目标目录(绝对路径,避免误操作)
TARGET_DIR="$HOME/claude-temp"

# 是否仅预览不删除
DRY_RUN=false
# 默认清理 30 天以前的文件
DAYS=30

for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN=true
  elif [[ "$arg" =~ ^[0-9]+$ ]]; then
    DAYS="$arg"
  else
    echo "错误:无法识别的参数: $arg" >&2
    exit 1
  fi
done

# 安全检查:目标目录必须存在
if [ ! -d "$TARGET_DIR" ]; then
  echo "错误:目录不存在: $TARGET_DIR" >&2
  exit 1
fi

# 预览模式:仅列出将被删除的文件和空目录
if [ "$DRY_RUN" = true ]; then
  echo "[DRY-RUN] 以下文件和目录将超过 $DAYS 天被清理:"
  find "$TARGET_DIR" -type f -mtime "+$DAYS"
  find "$TARGET_DIR" -type d -mtime "+$DAYS" -empty
  exit 0
fi

# 第一步:删除超过 DAYS 天未修改的文件
echo "删除超过 $DAYS 天未修改的文件..."
find "$TARGET_DIR" -type f -mtime "+$DAYS" -delete
echo "文件删除完成。"

# 第二步:删除因此变空的旧目录(只删空目录,避免误伤含新文件的目录)
echo "删除空目录..."
find "$TARGET_DIR" -type d -mtime "+$DAYS" -empty -delete
echo "目录清理完成。"

# 第三步:输出清理后统计
echo "=== 清理结果 ==="
echo "剩余旧文件数: $(find "$TARGET_DIR" -type f -mtime "+$DAYS" 2>/dev/null | wc -l | tr -d ' ')"
echo "目录总大小: $(du -sh "$TARGET_DIR" 2>/dev/null | cut -f1)"
