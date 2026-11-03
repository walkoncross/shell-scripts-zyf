#!/bin/bash

SYNC_SCRIPT_PATH="$(dirname "$0")/sync_to_sftp.sh"

if [ $# -gt 0 ]; then
    SYNC_SCRIPT_PATH="$1"
fi

# 检查sync_to_sftp.sh脚本是否存在
if [ ! -f "$SYNC_SCRIPT_PATH" ]; then
    echo "错误：未找到同步脚本 $SYNC_SCRIPT_PATH"
    exit 1
fi

# 检查脚本是否有执行权限
if [ ! -x "$SYNC_SCRIPT_PATH" ]; then
    echo "为同步脚本添加执行权限..."
    chmod +x "$SYNC_SCRIPT_PATH"
fi

# 定义要添加的cron任务
CRON_JOB="0 40/30 * * * $SYNC_SCRIPT_PATH"

# 检查该任务是否已存在于crontab中
if crontab -l 2>/dev/null | grep -qF "$CRON_JOB"; then
    echo "定时任务已存在，无需重复添加"
else
    # 添加任务到crontab
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "定时任务已成功添加"
fi

# 显示当前的crontab配置
echo "当前的定时任务配置："
crontab -l | grep "$SYNC_SCRIPT_PATH"
