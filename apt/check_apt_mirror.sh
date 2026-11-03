#!/bin/bash
# 查看 apt 当前镜像源配置
#
# 关注点：Ubuntu 24.04 / Debian 12+ 默认源在 DEB822 格式的
#         /etc/apt/sources.list.d/*.sources，传统 sources.list 可能为空。
#         两处都要看，才知道实际生效的源。

echo "========== 1) /etc/apt/sources.list(传统格式) =========="
if [[ -f /etc/apt/sources.list ]]; then
    content="$(grep -vE '^\s*(#|$)' /etc/apt/sources.list 2>/dev/null)"
    if [[ -n "$content" ]]; then
        echo "$content" | sed 's/^/  /'
    else
        echo "  (文件存在但无有效条目)"
    fi
else
    echo "  (文件不存在)"
fi
echo ""

echo "========== 2) /etc/apt/sources.list.d/(含 DEB822 .sources) =========="
shopt -s nullglob
files=(/etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list)
if [[ ${#files[@]} -gt 0 ]]; then
    for f in "${files[@]}"; do
        echo "  [$f]"
        grep -vE '^\s*(#|$)' "$f" 2>/dev/null | sed 's/^/    /'
        echo ""
    done
else
    echo "  (无 .sources / .list 文件)"
fi
