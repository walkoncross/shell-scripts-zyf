# 1. 禁用自动更新
echo 'export HOMEBREW_NO_AUTO_UPDATE=1' >> ~/.zshrc

# 2. 替换所有核心镜像
git -C "$(brew --repo)" remote set-url origin https://mirrors.ustc.edu.cn/brew.git
# git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
# git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

# 3. 启用国内二进制包源
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.zshrc

# 4. 修复 services 仓库，该仓库已经废弃
# cd /opt/homebrew/Library/Taps/homebrew/homebrew-services
# git remote add origin https://github.com/Homebrew/homebrew-services.git
# git fetch origin && git reset --hard origin/main

# 5. 生效配置
source ~/.zshrc