#!/usr/bin/env bash
# 用途：批量注册公司内部 MCP 服务到 Claude Code（user 作用域）
#
# 用法：
#   export SH_MCP_API_KEY=xxxxx
#   ./set_sh_mcp.sh            # 仅注册尚不存在的服务（已存在则跳过）
#   ./set_sh_mcp.sh --force    # 先移除再重新注册（用于更新 key）
#   ./set_sh_mcp.sh --dry-run  # 只打印命令，不实际执行
#
# 可选环境变量：
#   MCP_BASE_URL  MCP 服务根地址，默认 http://mcp.dmz.prod.caijj.net/mcp

set -euo pipefail

MCP_BASE_URL="${MCP_BASE_URL:-http://mcp.dmz.prod.caijj.net/mcp}"
FORCE=0
DRY_RUN=0

usage() {
    cat <<'EOF'
用法: set_sh_mcp.sh [--force] [--dry-run] [--help]
  --force    先移除已注册的服务再重新注册
  --dry-run  只打印将要执行的命令
  --help     显示帮助

需要先设置环境变量 SH_MCP_API_KEY
EOF
}

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        *) echo "未知参数: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

# 前置检查
if ! command -v claude >/dev/null 2>&1; then
    echo "未找到 claude 命令，请先安装 Claude Code" >&2
    exit 1
fi

if [[ -z "${SH_MCP_API_KEY:-}" ]]; then
    echo "环境变量 SH_MCP_API_KEY 未设置，请先 export SH_MCP_API_KEY=xxxxx" >&2
    exit 1
fi

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

failed=0

while IFS='|' read -r name transport extra; do
    # 去掉首尾空白和行内注释
    name="$(echo "$name" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    transport="$(echo "$transport" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    extra="$(echo "$extra" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    [[ -z "$name" ]] && continue

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
