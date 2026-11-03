#!/bin/bash

# 要删除的任务关键字（例如同步脚本的路径）
TASK_KEYWORD="sync_to_sftp.sh"

# 如果传入参数，则使用参数作为关键字
if [ "$#" -gt 0 ]; then
    TASK_KEYWORD="$1"
fi

if [ -z "$TASK_KEYWORD" ]; then
    echo "请设置要删除的任务关键字"
    exit 1
fi

# 检查任务是否存在
if crontab -l 2>/dev/null | grep -qF "$TASK_KEYWORD"; then
    # 移除包含关键字的任务行
    (crontab -l 2>/dev/null | grep -vF "$TASK_KEYWORD") | crontab -
    echo "已成功删除包含 '$TASK_KEYWORD' 的定时任务"
else
    echo "未找到包含 '$TASK_KEYWORD' 的定时任务"
fi

# 显示当前剩余的任务
echo "当前剩余的定时任务："
crontab -l