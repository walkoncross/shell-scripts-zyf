#!/bin/bash

# ======================== 命令行参数解析 ========================
all_branches=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all-branches)
            all_branches=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  --all-branches  拉取远端所有分支（默认只拉取当前分支）"
            echo "  -h, --help      显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

if [ "${all_branches}" = true ]; then
    echo "模式：拉取所有远程分支"
fi

# ======================== 配置项（请根据实际情况修改）========================
# 远程机器信息
remote_machine="remote_machine"          # 远程Mac主机名/IP
remote_account="remote_machine_account" # 远程机器账号
remote_work_dir="/path/to/remote/work/dir" # 远程工作目录（绝对路径）

# 本地机器信息
local_work_dir="/path/to/local/work/dir"   # 本地工作目录（绝对路径）
# =============================================================================

# 定义文件夹列表文件名
folder_list_file="${remote_work_dir//\//-}-folders.txt"
# 替换路径中的/为-，避免文件名包含/（例如 /data/work 变成 -data-work-folders.txt）
folder_list_file=${folder_list_file#-} # 移除开头的-

# 远程工作目录的 basename（用于在遍历时跳过根目录自身）
base_remote_dir=$(basename "${remote_work_dir}")

# SSH 选项
SSH_OPTS="-o ConnectTimeout=30 -o ServerAliveInterval=10 -o StrictHostKeyChecking=no"

# 构造 GIT_SSH_COMMAND
export GIT_SSH_COMMAND="ssh ${SSH_OPTS}"

# 函数：远程执行命令
remote_exec() {
    local cmd="$1"
    ssh ${SSH_OPTS} "${remote_machine}" "${cmd}"
}

# 步骤1：获取远程机器指定目录下的所有文件夹，保存为文件
echo "===== 开始获取远程目录 [${remote_work_dir}] 下的文件夹列表 ====="
# 远程执行：列出指定目录下的所有文件夹（仅一级），排除隐藏文件夹
remote_exec "ls -d ${remote_work_dir}/*/ 2>/dev/null | sed 's/\/$//' | xargs -n1 basename" > "${folder_list_file}"

# 检查是否获取到文件夹列表
if [ ! -s "${folder_list_file}" ]; then
    echo "警告：远程目录 [${remote_work_dir}] 下未找到任何文件夹，脚本退出"
    exit 1
fi

echo "===== 成功获取文件夹列表，共 $(wc -l < ${folder_list_file}) 个文件夹 ====="

# 步骤2：遍历文件夹列表，执行git pull/clone
echo "===== 开始处理每个文件夹 ====="
while IFS= read -r folder_name; do
    # 跳过空行
    if [ -z "${folder_name}" ]; then
        continue
    fi

    # 忽略根目录（例如 remote_work_dir 的 basename）或显式名为 "root" 的目录
    if [ "${folder_name}" = "${base_remote_dir}" ] || [ "${folder_name}" = "root" ]; then
        echo "跳过根目录：${folder_name}"
        continue
    fi

    # 忽略隐藏目录（以 '.' 开头）
    if [[ "${folder_name}" == .* ]]; then
        echo "跳过隐藏目录：${folder_name}"
        continue
    fi

    # 定义本地子目录和远程仓库路径
    local_sub_dir="${local_work_dir}/${folder_name}"
    # 使用 SSH 配置别名（会自动使用正确的密钥）
    remote_repo_path="${remote_machine}:${remote_work_dir}/${folder_name}"

    echo "----------------------------------------"
    echo "处理文件夹：${folder_name}"

    # 判断本地子目录是否存在
    if [ -d "${local_sub_dir}" ]; then
        echo "本地目录 [${local_sub_dir}] 已存在，执行 git pull"
        # 进入本地目录执行git pull
        cd "${local_sub_dir}" || {
            echo "错误：无法进入本地目录 [${local_sub_dir}]，跳过该文件夹"
            continue
        }
        if [ "${all_branches}" = true ]; then
            # 检查 origin URL 是否包含 remote_machine
            origin_url=$(git remote get-url origin 2>/dev/null)
            if [ -z "${origin_url}" ]; then
                # 未配置 origin，添加远程仓库
                git remote add origin "${remote_repo_path}"
                origin_url="${remote_repo_path}"
            fi
            if echo "${origin_url}" | grep -q "${remote_machine}"; then
                # 将 origin URL 统一为 SSH 配置别名格式，确保走 SSH config 的密钥认证
                if [ "${origin_url}" != "${remote_repo_path}" ]; then
                    echo "更新 origin URL: ${origin_url} -> ${remote_repo_path}"
                    git remote set-url origin "${remote_repo_path}"
                fi
                # fetch origin 的所有分支
                git fetch origin || {
                    echo "错误：git fetch origin 执行失败，跳过该文件夹"
                    continue
                }
                # 为 origin 的每个远程分支创建本地跟踪分支
                for remote_branch in $(git branch -r | grep '^  origin/' | grep -v '\->'); do
                    local_branch="${remote_branch#origin/}"
                    # 去除前后空格
                    local_branch=$(echo "${local_branch}" | xargs)
                    remote_branch=$(echo "${remote_branch}" | xargs)
                    if ! git show-ref --verify --quiet "refs/heads/${local_branch}"; then
                        git branch --track "${local_branch}" "${remote_branch}" 2>/dev/null && \
                            echo "创建本地分支：${local_branch} -> ${remote_branch}"
                    else
                        # 本地分支已存在，尝试快进合并
                        git checkout "${local_branch}" 2>/dev/null && \
                            git merge --ff-only "${remote_branch}" 2>/dev/null
                    fi
                done
                # 切回之前的分支
                git checkout - 2>/dev/null
            else
                echo "跳过：origin URL [${origin_url}] 不包含 ${remote_machine}，不执行 fetch"
            fi
        else
            git pull "${remote_repo_path}" || {
                echo "错误：git pull 执行失败，跳过该文件夹"
                continue
            }
        fi
    else
        echo "本地目录 [${local_sub_dir}] 不存在，执行 git clone"
        # 进入本地工作目录执行git clone
        cd "${local_work_dir}" || {
            echo "错误：无法进入本地工作目录 [${local_work_dir}]，跳过该文件夹"
            continue
        }
        git clone "${remote_repo_path}" || {
            echo "错误：git clone 执行失败，跳过该文件夹"
            continue
        }
        # clone 完成后，如果需要拉取所有分支，创建本地跟踪分支
        if [ "${all_branches}" = true ]; then
            cd "${local_sub_dir}" || continue
            for remote_branch in $(git branch -r | grep -v '\->'); do
                local_branch="${remote_branch#origin/}"
                if ! git show-ref --verify --quiet "refs/heads/${local_branch}"; then
                    git branch --track "${local_branch}" "${remote_branch}" 2>/dev/null && \
                        echo "创建本地分支：${local_branch} -> ${remote_branch}"
                fi
            done
        fi
    fi

    echo "文件夹 [${folder_name}] 处理完成"
done < "${folder_list_file}"

echo "===== 所有文件夹处理完毕 ====="
echo "文件夹列表文件已保存为：$(pwd)/${folder_list_file}"