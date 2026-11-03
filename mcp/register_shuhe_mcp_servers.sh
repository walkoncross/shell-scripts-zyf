#!/usr/bin/env bash
# 用途：批量注册公司内部 MCP 服务到 Claude Code（user 作用域）
#
# 用法：
#   export SH_MCP_API_KEY=xxxxx   # 未设置时会提示手动输入（输入以 * 回显，可确认后重输）
#   ./register_shuhe_mcp_servers.sh                     # 交互式选择服务（终端下）
#   ./register_shuhe_mcp_servers.sh sh_wiki sh_jira     # 直接指定服务（也可写 sh_wiki,sh_jira）
#   ./register_shuhe_mcp_servers.sh --all               # 跳过交互，注册全部服务
#   ./register_shuhe_mcp_servers.sh --list              # 列出可选服务
#   ./register_shuhe_mcp_servers.sh --force             # 先移除再重新注册（用于更新 key）
#   ./register_shuhe_mcp_servers.sh --dry-run           # 只打印命令，不实际执行
#
# 可选环境变量：
#   MCP_BASE_URL  MCP 服务根地址，默认 http://mcp.dmz.prod.caijj.net/mcp

set -euo pipefail

MCP_BASE_URL="${MCP_BASE_URL:-http://mcp.dmz.prod.caijj.net/mcp}"
FORCE=0
DRY_RUN=0
LIST_ONLY=0
ALL=0
SELECTED_ARGS=()

# 终端状态备份：读取 key 期间关闭回显，退出/中断时恢复
STTY_SAVED=""
restore_tty() {
    if [[ -n "$STTY_SAVED" ]]; then
        stty "$STTY_SAVED" 2>/dev/null || true
        STTY_SAVED=""
    fi
}

# 服务清单：名称|传输方式|额外 header（可选）
# 拆成多行是为了保持可读，逐项含义见行尾注释
SERVICES="$(cat <<'EOF'
sh_wiki|http|                         # 阅读文档
sh_database_struct|http|              # 表结构访问
sh_database_design|http|              # 数据库设计
sh_knowledge_base_retrieval|http|     # 知识检索
sh_dp_mcp|http|                       # Dataphin(DP) 平台
sh_jira|http|                         # Jira 项目管理
sh_bocha_search|sse|x-cjj-mcp-name:sh_bocha_search   # 联网搜索
sh_metricplus|http|                   # 监控中心指标
sh_sql_optimizer_mcp|http|            # SQL 优化
sh_ocr|http|                          # PDF/PPT OCR
EOF
)"

# 去掉行内注释和首尾空白
trim() {
    echo "$1" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# 对 key 做脱敏：只保留首尾 4 位，便于核对是否输错
mask_key() {
    local len="${#1}"
    if (( len <= 8 )); then
        printf '%*s' "$len" '' | tr ' ' '*'
    else
        printf '%s****%s' "${1:0:4}" "${1: -4}"
    fi
}

# 解析服务清单为数组，便于列表展示和交互式选择
SERVICE_NAMES=()
SERVICE_DESCS=()
while IFS='|' read -r name transport rest; do
    name="$(trim "$name")"
    [[ -z "$name" ]] && continue
    SERVICE_NAMES+=("$name")
    SERVICE_DESCS+=("$(printf '%s' "$rest" | sed -e 's/^[^#]*#//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done <<< "$SERVICES"

print_services() {
    local i=0
    echo "可选服务："
    while [[ "$i" -lt "${#SERVICE_NAMES[@]}" ]]; do
        printf '  %-30s %s\n' "${SERVICE_NAMES[$i]}" "${SERVICE_DESCS[$i]}"
        i=$((i + 1))
    done
}

# 交互式多选：输入序号（逗号/空格分隔），直接回车 = 全部
interactive_select() {
    local i=0 answer n
    echo "请选择要安装的 MCP 服务："
    while [[ "$i" -lt "${#SERVICE_NAMES[@]}" ]]; do
        printf '  %2d) %-30s %s\n' "$((i + 1))" "${SERVICE_NAMES[$i]}" "${SERVICE_DESCS[$i]}"
        i=$((i + 1))
    done
    echo "输入序号（逗号或空格分隔，例如 1,3）；直接回车 = 全部；q = 取消"
    read -r -p "> " answer || { echo; echo "已取消" >&2; exit 1; }

    case "$answer" in
        q|Q) echo "已取消" >&2; exit 1 ;;
        "") SELECTED_ARGS=("${SERVICE_NAMES[@]}"); return ;;
    esac

    local picks=()
    local -a _picks
    IFS=', ' read -r -a _picks <<< "$answer"
    for n in "${_picks[@]}"; do
        [[ -z "$n" ]] && continue
        if ! [[ "$n" =~ ^[0-9]+$ ]] || [[ "$n" -lt 1 || "$n" -gt "${#SERVICE_NAMES[@]}" ]]; then
            echo "无效序号: $n（可选范围 1-${#SERVICE_NAMES[@]}）" >&2
            exit 1
        fi
        picks+=("${SERVICE_NAMES[$((n - 1))]}")
    done
    if [[ ${#picks[@]} -eq 0 ]]; then
        echo "未选择任何服务" >&2
        exit 1
    fi
    SELECTED_ARGS=("${picks[@]}")
}

usage() {
    cat <<'EOF'
用法: register_shuhe_mcp_servers.sh [服务名...] [选项]

选项:
  --all        跳过交互，注册全部服务
  --list       列出可选服务（无需设置 key）
  --force      先移除已注册的服务再重新注册（用于更新 key）
  --dry-run    只打印将要执行的命令，不实际执行
  -h, --help   显示本帮助

选择服务:
  不指定服务名时：终端下交互式输入序号（可多选，如 1,3；直接回车=全部）
  指定服务名时：可写多个，也可用逗号分隔，例如 sh_wiki sh_jira / sh_wiki,sh_jira
  非交互环境（如 cron、管道）下不提问，默认注册全部

环境变量:
  SH_MCP_API_KEY  必填；未设置时会在终端提示手动输入（输入以 * 回显）
  MCP_BASE_URL    MCP 服务根地址，默认 http://mcp.dmz.prod.caijj.net/mcp

示例:
  ./register_shuhe_mcp_servers.sh                  # 交互式选择
  ./register_shuhe_mcp_servers.sh sh_wiki sh_jira  # 只注册这两个服务
  ./register_shuhe_mcp_servers.sh --all --force    # 全部重新注册（更新 key）
  ./register_shuhe_mcp_servers.sh --dry-run sh_ocr # 只查看将执行的命令
EOF
}

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --list)    LIST_ONLY=1 ;;
        --all)     ALL=1 ;;
        --help|-h) usage; exit 0 ;;
        -*)        echo "未知参数: $arg" >&2; usage >&2; exit 1 ;;
        *)
            # 支持逗号分隔：sh_wiki,sh_jira
            IFS=',' read -r -a _parts <<< "$arg"
            SELECTED_ARGS+=("${_parts[@]}")
            ;;
    esac
done

if [[ "$LIST_ONLY" -eq 1 ]]; then
    print_services
    exit 0
fi

# 未指定服务名时：终端下交互式选择，非交互环境注册全部
if [[ ${#SELECTED_ARGS[@]} -eq 0 && "$ALL" -eq 0 && -t 0 ]]; then
    interactive_select
fi

# 未指定服务名时注册全部；指定时先校验名称并对齐成 " name1 name2 " 便于匹配
SELECTED=""
if [[ ${#SELECTED_ARGS[@]} -gt 0 ]]; then
    unknown=()
    for s in "${SELECTED_ARGS[@]}"; do
        s="$(echo "$s" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -z "$s" ]] && continue
        if grep -q "^${s}|" <<< "$SERVICES"; then
            SELECTED="$SELECTED $s "
        else
            unknown+=("$s")
        fi
    done
    if [[ ${#unknown[@]} -gt 0 ]]; then
        echo "未知服务: ${unknown[*]}" >&2
        print_services >&2
        exit 1
    fi
    if [[ -z "$SELECTED" ]]; then
        echo "未指定任何有效服务" >&2
        exit 1
    fi
fi

# 前置检查
if ! command -v claude >/dev/null 2>&1; then
    echo "未找到 claude 命令，请先安装 Claude Code" >&2
    exit 1
fi

# 逐字符读取 key：每输入一个字符回显一个 *，支持退格删除，回车结束
# 期间持续关闭终端回显，避免逐字符读取的间隙把明文打到屏幕上
read_masked() {
    local char
    STTY_SAVED="$(stty -g)"
    trap 'restore_tty' EXIT
    trap 'restore_tty; exit 130' INT TERM
    stty -echo

    printf '请输入 SH_MCP_API_KEY（输入时以 * 显示）: '
    SH_MCP_API_KEY=""
    while :; do
        IFS= read -rn1 char || {
            restore_tty
            echo; echo "已取消" >&2; exit 1
        }
        if [[ -z "$char" ]]; then
            break  # 回车结束输入
        fi
        case "$char" in
            $'\004')  # Ctrl-D 取消
                restore_tty
                echo; echo "已取消" >&2; exit 1
                ;;
            $'\177'|$'\b')  # 退格
                if [[ -n "$SH_MCP_API_KEY" ]]; then
                    SH_MCP_API_KEY="${SH_MCP_API_KEY%?}"
                    printf '\b \b'
                fi
                ;;
            *)
                SH_MCP_API_KEY+="$char"
                printf '*'
                ;;
        esac
    done
    restore_tty
    trap - EXIT INT TERM
    echo
}

# SH_MCP_API_KEY 未设置时，交互式提示用户手动输入（以 * 回显），并显示脱敏预览供核对
read_api_key() {
    local confirm
    while :; do
        read_masked
        if [[ -z "$SH_MCP_API_KEY" ]]; then
            echo "不能为空，请重新输入" >&2
            continue
        fi
        # 只显示首尾 4 位和长度，既能核对是否输错，又不把明文留在屏幕上/日志里
        printf '已输入: %s（长度 %d）\n' "$(mask_key "$SH_MCP_API_KEY")" "${#SH_MCP_API_KEY}"
        read -r -p "确认使用该 key? [Y/n]: " confirm || {
            echo; echo "已取消" >&2; exit 1
        }
        case "$confirm" in
            ""|y|Y|yes|YES) return 0 ;;
            *) echo "重新输入..." ;;
        esac
    done
}

if [[ -z "${SH_MCP_API_KEY:-}" ]]; then
    if [[ -t 0 ]]; then
        read_api_key
    else
        echo "环境变量 SH_MCP_API_KEY 未设置，且当前为非交互环境，请先 export SH_MCP_API_KEY=xxxxx" >&2
        exit 1
    fi
fi

failed=0

while IFS='|' read -r name transport extra; do
    # 去掉首尾空白和行内注释
    name="$(trim "$name")"
    transport="$(trim "$transport")"
    extra="$(trim "$extra")"

    [[ -z "$name" ]] && continue

    # 只处理选中的服务（SELECTED 为空表示全部）
    if [[ -n "$SELECTED" && "$SELECTED" != *" $name "* ]]; then
        continue
    fi

    url="$MCP_BASE_URL/$name"

    # 已注册则按需跳过或先移除
    if claude mcp get "$name" >/dev/null 2>&1; then
        if [[ "$FORCE" -eq 0 ]]; then
            echo "[跳过] $name 已注册（加 --force 可重新注册）"
            continue
        fi
        echo "[移除] $name"
        if [[ "$DRY_RUN" -eq 0 ]]; then
            claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
        fi
    fi

    # 组装注册命令参数（数组避免路径/空格拆分问题）
    cmd=(claude mcp add "$name" "$url"
         --transport "$transport"
         --scope user
         --header "X-CJJ-MCP-API-KEY:$SH_MCP_API_KEY")

    if [[ -n "$extra" ]]; then
        cmd+=(--header "$extra")
    fi

    echo "[注册] $name ($transport)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        # 打印时对 key 做脱敏
        printf '  '
        printf '%q ' "${cmd[@]}" | sed 's/X-CJJ-MCP-API-KEY:[^[:space:]]*/X-CJJ-MCP-API-KEY:***/'
        echo
        continue
    fi

    if ! "${cmd[@]}"; then
        echo "[失败] $name 注册失败" >&2
        failed=$((failed + 1))
    fi
done <<< "$SERVICES"

if [[ "$failed" -gt 0 ]]; then
    echo "完成，其中 $failed 个服务注册失败" >&2
    exit 1
fi

echo "全部完成"
