#!/bin/bash

# 配置信息
LOCAL_DIR="/path/to/your/local_dir"  # 本地文件夹路径
SFTP_HOST="sftp.example.com"         # SFTP服务器地址
SFTP_PORT="22"                       # SFTP端口，通常是22
SFTP_USER="your_username"            # SFTP用户名
SFTP_PASS="your_password"            # SFTP密码
REMOTE_DIR="/path/to/remote/dir"     # 远程服务器目标路径
END_DATE="2025-12-31"                # 同步结束日期（格式：YYYY-MM-DD），到达此日期后停止同步

# 日志文件路径
LOG_FILE="/var/log/sync_from_sftp.log"

# 获取当前日期（格式：YYYY-MM-DD）
CURRENT_DATE=$(date +"%Y-%m-%d")

# 记录开始时间
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 开始同步检查..." >> $LOG_FILE

# 检查是否已超过结束日期
if [ "$CURRENT_DATE" \> "$END_DATE" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 已超过结束日期 $END_DATE，停止同步" >> $LOG_FILE
    echo "----------------------------------------" >> $LOG_FILE
    exit 0
fi

# 执行同步操作
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 执行同步..." >> $LOG_FILE

lftp -u $SFTP_USER,$SFTP_PASS sftp://$SFTP_HOST:$SFTP_PORT << EOF >> $LOG_FILE 2>&1
set sftp:auto-confirm yes
lcd $LOCAL_DIR
cd $REMOTE_DIR
mirror --verbose
bye
EOF

# 记录结束时间和状态
if [ $? -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 同步完成成功" >> $LOG_FILE
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 同步失败" >> $LOG_FILE
fi

echo "----------------------------------------" >> $LOG_FILE
