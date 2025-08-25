#!/bin/bash

# ======================== 配置项（请根据实际情况修改）========================
# 远程机器信息
# 使用 ~/.ssh/config 中的 Host 别名（必须与 ~/.ssh/config 中定义的 Host 名称一致）
remote_machine="zyf-mbp-m3"          # SSH 配置别名（对应 ~/.ssh/config 中的 Host）
remote_account=""                    # 留空，使用 SSH 配置中的 User
remote_work_dir="/Users/admin/work"  # 远程工作目录（绝对路径）

# 本地机器信息
local_work_dir="/Users/zhaoyafei/work"   # 本地工作目录（绝对路径）
# =============================================================================

# 定义文件夹列表文件名
folder_list_file="${remote_work_dir//\//-}-folders.txt"
# 替换路径中的/为-，避免文件名包含/（例如 /data/work 变成 -data-work-folders.txt）
folder_list_file=${folder_list_file#-} # 移除开头的-

# 远程工作目录的 basename（用于在遍历时跳过根目录自身）
base_remote_dir=$(basename "${remote_work_dir}")

# 函数：使用 SSH（使用 ~/.ssh/config 的 IdentityFile/Host 配置，避免明文密码）
# 如果你确实需要 sshpass，请手动恢复此前实现
remote_exec() {
    local cmd="$1"
    # 使用 SSH 配置别名，自动加载正确的密钥和用户信息
    # 添加超时设置，适应网络延迟较高的情况
    ssh -o ConnectTimeout=30 -o ServerAliveInterval=10 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes "${remote_machine}" "${cmd}"
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
    remote_repo_path="zyf-mbp-m3:${remote_work_dir}/${folder_name}"

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
        GIT_SSH_COMMAND='ssh -o ConnectTimeout=30 -o ServerAliveInterval=10 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes' git pull "${remote_repo_path}" || {
            echo "错误：git pull 执行失败，跳过该文件夹"
            continue
        }
    else
        echo "本地目录 [${local_sub_dir}] 不存在，执行 git clone"
        # 进入本地工作目录执行git clone
        cd "${local_work_dir}" || {
            echo "错误：无法进入本地工作目录 [${local_work_dir}]，跳过该文件夹"
            continue
        }
        GIT_SSH_COMMAND='ssh -o ConnectTimeout=30 -o ServerAliveInterval=10 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes' git clone "${remote_repo_path}" || {
            echo "错误：git clone 执行失败，跳过该文件夹"
            continue
        }
    fi

    echo "文件夹 [${folder_name}] 处理完成"
done < "${folder_list_file}"

echo "===== 所有文件夹处理完毕 ====="
echo "文件夹列表文件已保存为：$(pwd)/${folder_list_file}"