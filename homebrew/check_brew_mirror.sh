#!/bin/bash
# 查看 Homebrew 当前镜像源配置
#
# 关注点：brew update 实际使用的源由环境变量 HOMEBREW_BREW_GIT_REMOTE /
#         HOMEBREW_CORE_GIT_REMOTE 决定（每次 update 会按它们重置 git remote）。
#         所以诊断时「当前 shell 的环境变量」才是权威，git remote 仅供参考。

echo "========== 1) 当前 shell 生效的 Homebrew 镜像环境变量(权威) =========="
found=0
for v in HOMEBREW_BREW_GIT_REMOTE HOMEBREW_CORE_GIT_REMOTE \
         HOMEBREW_API_DOMAIN HOMEBREW_BOTTLE_DOMAIN HOMEBREW_NO_AUTO_UPDATE; do
    val="${!v}"
    if [ -n "$val" ]; then
        echo "  $v=$val"
        found=1
    fi
done
[ "$found" -eq 0 ] && echo "  (未设置，brew update 将使用官方源)"
echo ""

echo "========== 2) git remote 实际地址(仅参考，会被上面的环境变量覆盖) =========="
echo "  brew  : $(git -C "$(brew --repo)" remote get-url origin 2>/dev/null || echo '获取失败')"
core_repo="$(brew --repo homebrew/core 2>/dev/null)"
if [ -n "$core_repo" ] && [ -d "$core_repo/.git" ]; then
    echo "  core  : $(git -C "$core_repo" remote get-url origin 2>/dev/null || echo '获取失败')"
else
    echo "  core  : (未 clone，新版 brew 改用 JSON API)"
fi
echo ""

echo "========== 3) 各 rc 文件中的 Homebrew 镜像配置(排查冲突来源) =========="
# 扫描所有可能写入镜像配置的文件，把散落在标记块外的硬编码项也暴露出来，
# 避免出现「标记块是 A，但某文件硬编码了 B 并覆盖生效」的隐蔽冲突。
for f in "$HOME/.zprofile" "$HOME/.profile" "$HOME/.bash_profile" \
         "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$f" ] || continue
    hits="$(grep -n '^[[:space:]]*export HOMEBREW_\(BREW_GIT_REMOTE\|CORE_GIT_REMOTE\|API_DOMAIN\|BOTTLE_DOMAIN\|NO_AUTO_UPDATE\)=' "$f" 2>/dev/null)"
    if [ -n "$hits" ]; then
        echo "  [$f]"
        echo "$hits" | sed 's/^/    /'
    fi
done
echo ""
echo "提示：若第 3 节中多个文件出现同名变量，靠后加载的文件会覆盖前者；"
echo "      .zprofile 在登录时早于 .zshrc 加载，是常见的隐蔽覆盖来源。"
