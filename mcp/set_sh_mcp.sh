#!/usr/bin/env bash
# 用途：批量注册公司内部 MCP 服务到 Claude Code（user 作用域）
#
# 用法：
#   export SH_MCP_API_KEY=xxxxx   # 未设置时会提示手动输入
#   ./set_sh_mcp.sh                     # 注册全部服务（已存在则跳过）
#   ./set_sh_mcp.sh sh_wiki sh_jira     # 只注册指定服务（也可写 sh_wiki,sh_jira）
#   ./set_sh_mcp.sh --list              # 列出可选服务
#   ./set_sh_mcp.sh --force             # 先移除再重新注册（用于更新 key）
#   ./set_sh_mcp.sh --dry-run           # 只打印命令，不实际执行
#
# 可选环境变量：
#   MCP_BASE_URL  MCP 服务根地址，默认 http://mcp.dmz.prod.caijj.net/mcp

set -euo pipefail

MCP_BASE_URL="${MCP_BASE_URL:-http://mcp.dmz.prod.caijj.net/mcp}"
FORCE=0
DRY_RUN=0
LIST_ONLY=0
SELECTED_ARGS=()

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

print_services() {
    echo "可选服务："
    while IFS='|' read -r name transport rest; do
        name="$(trim "$name")"
        [[ -z "$name" ]] && continue
        desc="$(printf '%s' "$rest" | sed -e 's/^[^#]*#//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        printf '  %-30s %s\n' "$name" "$desc"
    done <<< "$SERVICES"
}

usage() {
    cat <<'EOF'
用法: set_sh_mcp.sh [服务名...] [--force] [--dry-run] [--list] [--help]
  服务名     要注册的服务，可写多个或用逗号分隔；不写则注册全部
  --list     列出可选服务
  --force    先移除已注册的服务再重新注册
  --dry-run  只打印将要执行的命令
  --help     显示帮助

需要环境变量 SH_MCP_API_KEY；未设置时会提示手动输入
EOF
}

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --list)    LIST_ONLY=1 ;;
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

# SH_MCP_API_KEY 未设置时，交互式提示用户手动输入（不回显）
if [[ -z "${SH_MCP_API_KEY:-}" ]]; then
    if [[ -t 0 ]]; then
        read -r -s -p "请输入 SH_MCP_API_KEY（输入内容不回显）: " SH_MCP_API_KEY
        echo
    else
        echo "环境变量 SH_MCP_API_KEY 未设置，且当前为非交互环境，请先 export SH_MCP_API_KEY=xxxxx" >&2
        exit 1
    fi
    if [[ -z "${SH_MCP_API_KEY:-}" ]]; then
        echo "SH_MCP_API_KEY 不能为空" >&2
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
