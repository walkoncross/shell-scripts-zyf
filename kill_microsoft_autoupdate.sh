#!/bin/bash

# 脚本名称：kill_microsoft_autoupdate.sh
# 功能：搜索并选择性终止 Microsoft AutoUpdate 相关进程（修复大小写问题）

# 定义目标关键词（忽略大小写，匹配进程名/命令行）
TARGET_KEYWORDS=("microsoft autoupdate" "mau" "msupdate")

# 颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

# 清除终端并显示欢迎信息
clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}         Microsoft AutoUpdate 进程管理工具        ${NC}"
echo -e "${GREEN}=============================================${NC}\n"

# 搜索目标进程（忽略大小写，显示详细信息）
echo -e "${YELLOW}正在搜索 Microsoft AutoUpdate 相关进程（忽略大小写）...${NC}\n"

# 存储找到的进程 PID 列表（去重）
FOUND_PIDS=()

# 方法1：用 ps aux 模糊搜索（最可靠，忽略大小写）
# -i：忽略大小写，-w：全词匹配，-E：扩展正则
PROCESS_LIST=$(ps aux | grep -iEw --color=never "microsoft.*autoupdate|mau|msupdate" | grep -v grep)

if [ -n "$PROCESS_LIST" ]; then
    echo -e "${GREEN}找到相关进程：${NC}"
    echo "$PROCESS_LIST" | awk '{print "PID:", $2, "| 用户名:", $1, "| 进程名:", $11, "| 启动时间:", $9, "| 完整命令:", substr($0, index($0, $11))}'
    echo "----------------------------------------"
    
    # 提取 PID 并去重
    PIDS=$(echo "$PROCESS_LIST" | awk '{print $2}' | sort -u)
    for PID in $PIDS; do
        FOUND_PIDS+=("$PID")
    done
fi

# 检查是否找到进程
if [ ${#FOUND_PIDS[@]} -eq 0 ]; then
    echo -e "\n${YELLOW}未找到 Microsoft AutoUpdate 相关进程，脚本退出。${NC}"
    exit 0
fi

# 显示总结信息
echo -e "\n${RED}=============================================${NC}"
echo -e "${RED}找到 ${#FOUND_PIDS[@]} 个相关进程，PID 列表：${FOUND_PIDS[*]}${NC}"
echo -e "${RED}=============================================${NC}\n"

# 询问用户是否终止进程
read -p "是否终止以上所有进程？(y/N) " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]') # 转为小写

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "yes" ]; then
    echo -e "\n${YELLOW}用户取消操作，进程未终止。${NC}"
    exit 0
fi

# 执行终止进程操作
echo -e "\n${YELLOW}正在终止进程...${NC}"
SUCCESS=0
FAILURE=0

for PID in "${FOUND_PIDS[@]}"; do
    # 先尝试优雅终止（SIGTERM），失败则强制终止（SIGKILL）
    if kill -15 "$PID" 2>/dev/null; then
        sleep 1
        if ! ps -p "$PID" >/dev/null 2>&1; then
            echo -e "✅ PID $PID 已成功终止"
            ((SUCCESS++))
        else
            # 优雅终止失败，尝试强制终止
            if kill -9 "$PID" 2>/dev/null; then
                echo -e "✅ PID $PID 已强制终止"
                ((SUCCESS++))
            else
                echo -e "❌ PID $PID 终止失败"
                ((FAILURE++))
            fi
        fi
    else
        echo -e "❌ PID $PID 终止失败（进程不存在或无权限）"
        ((FAILURE++))
    fi
done

# 输出执行结果总结
echo -e "\n${GREEN}=============================================${NC}"
echo -e "执行结果总结："
echo -e "总进程数：${#FOUND_PIDS[@]}"
echo -e "成功终止：$SUCCESS 个"
echo -e "终止失败：$FAILURE 个"
echo -e "${GREEN}=============================================${NC}"

exit 0