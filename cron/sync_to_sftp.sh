#!/bin/bash

# LFTP_PATH=$(which lftp)
# LFTP_PATH="/opt/homebrew/Cellar/lftp/4.9.3/bin/lftp"
LFTP_PATH="/opt/homebrew/bin/lftp"
# LFTP_PATH="$(readlink -f $LFTP_PATH)"

# 日志文件路径
LOG_FILE="$HOME/logs/sync_to_sftp.log"

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 配置信息
LOCAL_DIR="/path/to/your/local_dir"  # 本地文件夹路径
SFTP_HOST="sftp.example.com"         # SFTP服务器地址
SFTP_PORT="22"                       # SFTP端口，通常是22
SFTP_USER="your_username"            # SFTP用户名
SFTP_PASS="your_password"            # SFTP密码
REMOTE_DIR="/path/to/remote/dir"     # 远程服务器目标路径

# 日志文件路径
LOG_FILE="/var/log/sync_to_sftp.log"

# 获取当前日期（格式：YYYY-MM-DD）
CURRENT_DATE=$(date +"%Y-%m-%d")

echo "----------------------------------------"  | tee -a "$LOG_FILE"

# 记录开始时间
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 开始同步检查..."  | tee -a "$LOG_FILE"

echo "log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "lftp path: $LFTP_PATH" | tee -a "$LOG_FILE"
echo "local dir: $LOCAL_DIR" | tee -a "$LOG_FILE"
echo "remote dir: $REMOTE_DIR" | tee -a "$LOG_FILE"

# 检查lftp是否安装
if [[ ! -f "$LFTP_PATH" ]]; then
    echo "错误：lftp未安装。请先安装lftp或设置lftp的绝对路径。"  | tee -a "$LOG_FILE"
    exit 1
fi

# 执行同步操作
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 执行同步..."  | tee -a "$LOG_FILE"
echo "lftp path: $LFTP_PATH"  | tee -a "$LOG_FILE"

# 在执行 lftp 之前添加调试信息
echo "[Debug] Expanded LOCAL_DIR: $LOCAL_DIR" >> "$LOG_FILE"
echo "[Debug] Current working directory: $(pwd)" >> "$LOG_FILE"
ls -l "$LOCAL_DIR" >> "$LOG_FILE" 2>&1

$LFTP_PATH -u $SFTP_USER,$SFTP_PASS sftp://$SFTP_HOST:$SFTP_PORT << EOF >> $LOG_FILE 2>&1
set sftp:auto-confirm yes
lcd "$LOCAL_DIR"  # 添加引号避免路径中的空格问题
cd "$REMOTE_DIR"  # 添加引号避免路径中的空格问题
mirror --reverse --verbose
bye
EOF

# 记录结束时间和状态
if [ $? -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 同步完成成功"  | tee -a "$LOG_FILE"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 同步失败"  | tee -a "$LOG_FILE"
fi

echo "----------------------------------------"  | tee -a "$LOG_FILE"
