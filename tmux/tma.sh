#!/usr/bin/env bash
# tma.sh — tmux attach session alias with tab completion
# 支持 macOS / Linux，支持 bash / zsh
#
# 用法：
#   bash tmux/tma.sh          # 安装：自动写入 ~/.bashrc 和 ~/.zshrc
#   source tmux/tma.sh        # 仅在当前 shell 中临时启用

# ── 核心内容（source 模式直接执行，安装模式写入配置文件）─────────────────────

TMA_SNIPPET='
# ── tma: tmux attach with tab completion ────────────────────────────────────
alias tma="tmux attach -t"

_tma_bash() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local sessions
    sessions=$(tmux ls -F "#S" 2>/dev/null | xargs)
    COMPREPLY=( $(compgen -W "$sessions" -- "$cur") )
}

_tma_zsh() {
    local sessions
    sessions=(${(f)"$(tmux ls -F "#S" 2>/dev/null)"})
    _describe "tmux sessions" sessions
}

if [ -n "$ZSH_VERSION" ]; then
    if (( ${+functions[compdef]} )); then
        compdef _tma_zsh tma
    else
        autoload -Uz compinit && compinit -u
        compdef _tma_zsh tma
    fi
else
    complete -F _tma_bash tma
fi
# ── end tma ─────────────────────────────────────────────────────────────────
'

MARKER='# ── tma: tmux attach with tab completion'

# ── source 模式：直接加载，不修改任何文件 ────────────────────────────────────
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] || [[ -n "$ZSH_VERSION" && "$ZSH_EVAL_CONTEXT" == *:file* ]]; then
    alias tma="tmux attach -t"

    _tma_bash() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local sessions
        sessions=$(tmux ls -F '#S' 2>/dev/null | xargs)
        COMPREPLY=( $(compgen -W "$sessions" -- "$cur") )
    }

    _tma_zsh() {
        local sessions
        sessions=(${(f)"$(tmux ls -F '#S' 2>/dev/null)"})
        _describe 'tmux sessions' sessions
    }

    if [ -n "$ZSH_VERSION" ]; then
        if (( ${+functions[compdef]} )); then
            compdef _tma_zsh tma
        else
            autoload -Uz compinit && compinit -u
            compdef _tma_zsh tma
        fi
    else
        complete -F _tma_bash tma
    fi
    return 0
fi

# ── 安装模式：写入配置文件 ────────────────────────────────────────────────────
install_to() {
    local rc_file="$1"
    local shell_name="$2"

    # 配置文件不存在则跳过
    if [[ ! -f "$rc_file" ]]; then
        echo "  跳过 $shell_name：$rc_file 不存在"
        return
    fi

    # 已安装则跳过
    if grep -qF "$MARKER" "$rc_file" 2>/dev/null; then
        echo "  跳过 $shell_name：已安装（$rc_file）"
        return
    fi

    printf '%s\n' "$TMA_SNIPPET" >> "$rc_file"
    echo "  已写入 $shell_name：$rc_file"
}

echo "安装 tma..."
install_to "$HOME/.bashrc" "bash"
install_to "$HOME/.zshrc"  "zsh"
echo "完成。请重新打开终端，或执行："
echo "  source ~/.bashrc   # bash"
echo "  source ~/.zshrc    # zsh"
