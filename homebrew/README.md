# Homebrew 安装和操作相关 tips

## 脚本说明

### switch_brew_mirror.sh — 换源 / 恢复官方源

```bash
# 默认使用 aliyun 源
./switch_brew_mirror.sh

# 指定镜像源（tuna / ustc / aliyun）
./switch_brew_mirror.sh tuna
./switch_brew_mirror.sh ustc
./switch_brew_mirror.sh aliyun

# 恢复官方源
./switch_brew_mirror.sh restore
```

| 镜像 | brew.git | Bottles |
|------|----------|---------|
| tuna | mirrors.tuna.tsinghua.edu.cn | mirrors.tuna.tsinghua.edu.cn/homebrew-bottles |
| ustc | mirrors.ustc.edu.cn | mirrors.ustc.edu.cn/homebrew-bottles |
| aliyun | mirrors.aliyun.com | mirrors.aliyun.com/homebrew/homebrew-bottles |

### brew_list_show_size.sh — 列出已安装包及占用大小

```bash
./brew_list_show_size.sh
```

### brew_list_show_size_sorted.sh — 列出已安装包并按大小排序

```bash
./brew_list_show_size_sorted.sh
```

---

## 参考：手动换源（清华镜像）

官方文档：https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/

```bash
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
for tap in core cask command-not-found; do
    brew tap --custom-remote --force-auto-update "homebrew/${tap}" "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git"
done
brew update
```
