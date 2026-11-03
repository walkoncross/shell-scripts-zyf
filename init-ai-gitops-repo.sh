#!/bin/bash
# 脚本功能：初始化 AI 项目的 GitOps 仓库
# 用途：创建标准化的项目目录结构，用于跟踪需求、分析、设计方案和开发过程

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在 Git 仓库中
check_git_repo() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        log_warn "当前目录已经是 Git 仓库"
        return 0
    else
        log_info "当前目录不是 Git 仓库，将初始化..."
        return 1
    fi
}

# 初始化 Git 仓库
init_git_repo() {
    if ! check_git_repo; then
        git init
        log_info "Git 仓库初始化完成"
    fi
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."

    # 核心目录
    mkdir -p .prompts
    mkdir -p requirements          # 需求文档
    mkdir -p analysis              # 需求分析
    mkdir -p design                # 设计方案
    mkdir -p development           # 开发记录
    mkdir -p issues                # 问题跟踪
    mkdir -p solutions             # 解决方案
    mkdir -p meetings              # 会议记录
    mkdir -p wiki                  # 项目 Wiki
    mkdir -p knowledge-base        # 知识库
    mkdir -p notes                 # 笔记
    mkdir -p docs                  # 文档
    mkdir -p templates             # 模板文件

    log_info "目录结构创建完成"
}

# 创建 .prompts/prompts.md
create_prompts_file() {
    local date_string=$(date +"%Y-%m-%d")

    cat > .prompts/prompts.md <<'EOF'
# AI 提示词记录

本文件用于记录项目开发过程中使用的 AI 提示词、想法和经验总结。

---

EOF

    cat >> .prompts/prompts.md <<EOF
## ${date_string}

### 提示词

-

### 效果评估

-

### 经验总结

-

EOF

    log_info "创建 .prompts/prompts.md 完成"
}

# 创建 .prompts/.gitignore
create_prompts_gitignore() {
    cat > .prompts/.gitignore <<'EOF'
*
!.gitignore
# !prompts.md
EOF

    log_info "创建 .prompts/.gitignore 完成"
}

# 创建 README.md
create_readme() {
    cat > README.md <<'EOF'
# AI 项目 GitOps 仓库

本仓库采用 GitOps 理念管理 AI 项目的全生命周期，包括需求跟踪、分析、设计、开发过程记录等。

## 目录结构

```
.
├── .prompts/           # AI 提示词记录（不提交到远程仓库）
├── requirements/       # 需求文档
├── analysis/           # 需求分析文档
├── design/             # 设计方案
├── development/        # 开发过程记录
├── issues/             # 问题跟踪
├── solutions/          # 解决方案文档
├── meetings/           # 会议记录
├── wiki/               # 项目 Wiki
├── knowledge-base/     # 知识库（技术文章、参考资料）
├── notes/              # 个人笔记
├── docs/               # 项目文档
└── templates/          # 模板文件
```

## 目录说明

### .prompts/
存储每日使用的 AI 提示词、效果评估和经验总结。此目录默认不提交到远程仓库。

### requirements/
存放项目需求文档，包括：
- 功能需求
- 非功能需求
- 用户故事
- 需求变更记录

### analysis/
需求分析文档，包括：
- 业务分析
- 技术可行性分析
- 风险评估
- 资源评估

### design/
设计方案文档，包括：
- 架构设计
- 接口设计
- 数据库设计
- UI/UX 设计

### development/
开发过程记录，包括：
- 开发日志
- 技术决策
- 代码审查记录
- 重构记录

### issues/
问题跟踪，包括：
- Bug 记录
- 性能问题
- 安全问题
- 技术债务

### solutions/
解决方案文档，记录问题的解决过程和方案。

### meetings/
会议记录，包括：
- 项目启动会
- 需求评审会
- 设计评审会
- 迭代回顾会

### wiki/
项目 Wiki，维护项目相关的知识和文档。

### knowledge-base/
知识库，存储技术文章、论文、参考资料等。

### notes/
个人笔记和观察记录。

### docs/
项目文档，包括：
- 用户手册
- 开发文档
- 部署文档
- API 文档

### templates/
模板文件，包括：
- 需求文档模板
- 设计文档模板
- 会议记录模板
- 问题报告模板

## 使用指南

### 日常记录

1. 每天在 `.prompts/prompts.md` 中记录使用的 AI 提示词
2. 在 `development/` 目录下记录开发过程
3. 遇到问题时在 `issues/` 目录创建问题记录
4. 解决问题后在 `solutions/` 目录记录解决方案

### 版本控制

- 使用 Git 跟踪所有文档变更
- 提交信息遵循规范：`<type>: <description>`
- 类型包括：docs（文档）、feat（新功能）、fix（修复）、refactor（重构）等

### 协作流程

1. 需求提出 → `requirements/`
2. 需求分析 → `analysis/`
3. 方案设计 → `design/`
4. 开发实现 → `development/`
5. 问题追踪 → `issues/` + `solutions/`
6. 会议沟通 → `meetings/`

## 维护建议

- 定期整理和归档文档
- 及时更新 Wiki 和知识库
- 保持目录结构清晰
- 使用有意义的文件命名

---

*Created by init-ai-gitops-repo.sh*
EOF

    log_info "创建 README.md 完成"
}

# 创建 .gitignore
create_gitignore() {
    if [ -f .gitignore ]; then
        log_warn ".gitignore 已存在，跳过创建"
        return
    fi

    cat > .gitignore <<'EOF'
# 操作系统
.DS_Store
Thumbs.db

# 编辑器
.vscode/
.idea/
*.swp
*.swo
*~

# 临时文件
*.tmp
*.log
.temp/

# 敏感信息
.env
.env.local
secrets/
credentials/
EOF

    log_info "创建 .gitignore 完成"
}

# 创建模板文件
create_templates() {
    log_info "创建模板文件..."

    # 需求文档模板
    cat > templates/requirement-template.md <<'EOF'
# 需求文档 - [功能名称]

## 基本信息
- **需求编号**: REQ-YYYYMMDD-001
- **提出日期**: YYYY-MM-DD
- **提出人**:
- **优先级**: 高/中/低
- **状态**: 待分析/已分析/已设计/开发中/已完成

## 需求描述

### 背景
描述需求产生的背景和原因。

### 目标
描述需求要达到的目标。

### 用户故事
作为 [角色]，我想要 [功能]，以便 [价值]。

## 功能需求

### 功能点 1
- 描述

### 功能点 2
- 描述

## 非功能需求
- 性能要求
- 安全要求
- 可用性要求

## 验收标准
- [ ] 标准 1
- [ ] 标准 2

## 相关文档
- 分析文档:
- 设计文档:
EOF

    # 问题报告模板
    cat > templates/issue-template.md <<'EOF'
# 问题报告 - [问题简述]

## 基本信息
- **问题编号**: ISSUE-YYYYMMDD-001
- **发现日期**: YYYY-MM-DD
- **发现人**:
- **严重程度**: 致命/严重/一般/轻微
- **状态**: 待处理/处理中/已解决/已关闭

## 问题描述

### 现象
详细描述问题的表现形式。

### 复现步骤
1. 步骤 1
2. 步骤 2
3. 步骤 3

### 预期结果
描述正确的预期行为。

### 实际结果
描述实际发生的错误行为。

## 环境信息
- 操作系统:
- 相关版本:
- 其他信息:

## 分析
- 可能的原因:
- 影响范围:

## 解决方案
- 方案链接: solutions/

## 相关记录
- 相关需求:
- 相关代码:
EOF

    log_info "模板文件创建完成"
}

# 创建初始 Git 提交
create_initial_commit() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_warn "未初始化 Git 仓库，跳过提交"
        return
    fi

    git add .
    git commit -m "docs: 初始化 AI 项目 GitOps 仓库

- 创建标准化目录结构
- 添加 README 和使用说明
- 创建文档模板
- 配置 .gitignore

Co-Authored-By: init-ai-gitops-repo.sh" || log_warn "提交失败（可能已存在提交）"

    log_info "创建初始 Git 提交完成"
}

# 主函数
main() {
    log_info "开始初始化 AI 项目 GitOps 仓库..."
    echo

    # 执行初始化步骤
    init_git_repo
    create_directories
    create_prompts_file
    create_prompts_gitignore
    create_readme
    create_gitignore
    create_templates

    echo
    log_info "✨ AI 项目 GitOps 仓库初始化完成！"
    echo
    log_info "接下来你可以："
    echo "  1. 查看 README.md 了解目录结构"
    echo "  2. 在 .prompts/prompts.md 中记录每日 AI 提示词"
    echo "  3. 在相应目录下创建需求、分析、设计等文档"
    echo "  4. 使用 templates/ 目录中的模板快速创建文档"
    echo

    # 可选：创建初始提交
    read -p "是否创建初始 Git 提交？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_initial_commit
    fi
}

# 执行主函数
main "$@"