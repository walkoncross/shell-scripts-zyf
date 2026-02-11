#!/bin/bash
# 脚本功能：初始化 AI 项目的 GitDocs 仓库
# 用途：创建标准化的项目目录结构，用于跟踪需求、分析、设计方案和开发过程
# 使用方法：./init-gitdocs-repo.sh [root_dir]
#   - root_dir: 目标目录路径（可选，默认为当前目录）

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
ROOT_DIR="${1:-.}"  # 第一个参数作为 root_dir，默认为当前目录

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查并准备目标目录
check_and_prepare_directory() {
    log_step "检查目标目录: $ROOT_DIR"

    # 转换为绝对路径
    if [[ "$ROOT_DIR" != /* ]]; then
        ROOT_DIR="$(pwd)/$ROOT_DIR"
    fi

    # 检查目录是否存在
    if [ -d "$ROOT_DIR" ]; then
        # 目录已存在，检查是否为空
        if [ "$(ls -A "$ROOT_DIR" 2>/dev/null)" ]; then
            log_warn "目录 $ROOT_DIR 已存在且不为空"
            echo -e "${YELLOW}目录内容：${NC}"
            ls -la "$ROOT_DIR" | head -n 10
            if [ $(ls -A "$ROOT_DIR" | wc -l) -gt 10 ]; then
                echo "... (还有更多文件)"
            fi
            echo
            read -p "是否继续在此目录初始化 GitDocs 仓库？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "用户取消操作"
                exit 1
            fi
        else
            log_info "目录 $ROOT_DIR 已存在且为空"
        fi
    else
        log_info "目录 $ROOT_DIR 不存在，将创建..."
        mkdir -p "$ROOT_DIR"
        log_info "目录创建成功"
    fi

    # 切换到目标目录
    cd "$ROOT_DIR" || {
        log_error "无法切换到目录 $ROOT_DIR"
        exit 1
    }

    log_info "工作目录: $(pwd)"
    echo
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

    # 在空目录中创建 .gitkeep 文件，使其可被 Git 跟踪
    for dir in requirements analysis development issues solutions meetings knowledge-base notes docs; do
        touch "$dir/.gitkeep"
    done

    log_info "目录结构创建完成"
}

# 创建 .prompts/ 目录下的文件
create_prompts_files() {
    local date_string=$(date +"%Y-%m-%d")

    # 创建 prompts.md（个人日常记录，不提交）
    cat > .prompts/prompts.md <<'EOF'
# AI 提示词日常记录

本文件用于记录日常使用的 AI 提示词、实验和临时想法。

**注意**：此文件不会提交到 Git，仅供个人使用。

---

EOF

    cat >> .prompts/prompts.md <<EOF
## ${date_string}

### 提示词

-

### 效果评估

-

### 临时想法

-

EOF

    # 创建 best-practices.md（精选提示词，提交到 Git）
    cat > .prompts/best-practices.md <<'EOF'
# AI 提示词最佳实践

本文件记录经过验证的、有效的 AI 提示词模板和最佳实践，供团队参考和复用。

---

## 代码生成类

### 功能实现
```
请实现一个 [功能描述]，要求：
1. [需求点 1]
2. [需求点 2]
3. 考虑边界情况和错误处理
```

### 代码重构
```
请重构以下代码，优化目标：
1. 提高可读性
2. 减少重复代码
3. 遵循 [语言/框架] 最佳实践

[代码片段]
```

---

## 文档编写类

### 技术文档
```
请编写 [功能/模块] 的技术文档，包括：
1. 功能概述
2. 使用方法
3. 参数说明
4. 示例代码
5. 注意事项
```

### API 文档
```
请为以下 API 生成文档：
- 端点：[URL]
- 方法：[GET/POST/etc]
- 功能：[描述]
- 参数：[列表]
- 返回值：[格式]
```

---

## 问题分析类

### Bug 诊断
```
遇到以下错误，请帮助分析：
- 错误信息：[error message]
- 复现步骤：[steps]
- 环境信息：[environment]
- 相关代码：[code]
```

### 性能优化
```
以下代码存在性能问题，请分析并提供优化方案：
- 当前问题：[描述]
- 性能指标：[metrics]
- 代码：[code]
```

---

## 使用技巧

### 有效提示词的特征
1. **明确目标**：清晰说明期望的输出
2. **提供上下文**：给出必要的背景信息
3. **结构化描述**：使用列表、分点说明
4. **包含约束**：说明限制条件和边界
5. **示例引导**：提供期望格式的示例

### 迭代优化策略
1. 从简单提示词开始
2. 根据输出结果调整
3. 添加具体要求和约束
4. 记录有效的模板

---

*持续更新中...*
EOF

    # 创建 README.md 说明
    cat > .prompts/README.md <<'EOF'
# .prompts 目录说明

本目录用于管理 AI 提示词相关内容。

## 文件说明

### prompts.md（不提交）
- **用途**：日常记录 AI 交互的提示词
- **内容**：实验性提示词、临时想法、调试记录
- **管理**：仅本地保存，不提交到 Git
- **建议**：随时记录，定期整理

### best-practices.md（提交到 Git）
- **用途**：记录验证有效的提示词模板
- **内容**：经过测试的最佳实践、可复用的模板
- **管理**：提交到 Git，团队共享
- **建议**：精选有价值的内容，定期更新

## 使用流程

1. **日常记录** → 在 `prompts.md` 中快速记录
2. **验证效果** → 测试提示词的实际效果
3. **提炼精华** → 将有效的提示词整理到 `best-practices.md`
4. **团队共享** → 提交 `best-practices.md` 供他人参考

## 注意事项

- ⚠️ 不要在 `prompts.md` 中记录敏感信息
- ⚠️ 提交 `best-practices.md` 前检查是否包含敏感内容
- ✅ 定期回顾和更新最佳实践
- ✅ 为提示词模板添加使用场景说明
EOF

    log_info "创建 .prompts/ 目录文件完成"
}

# 创建 .prompts/.gitignore
create_prompts_gitignore() {
    cat > .prompts/.gitignore <<'EOF'
# 忽略所有文件
*

# 但保留以下文件
!.gitignore
!best-practices.md
!README.md
EOF

    log_info "创建 .prompts/.gitignore 完成"
}

# 创建 README.md
create_readme() {
    cat > README.md <<'EOF'
# AI 项目 GitDocs 仓库

本仓库采用 GitDocs 理念管理 AI 项目的**文档和流程**，包括需求跟踪、技术方案、会议记录、问题跟踪等内容。

> **GitDocs** 是将 GitOps 理念应用于文档管理的方法论，以 Git 作为文档的单一事实来源。

> **重要说明**：本仓库仅用于管理项目文档、需求、设计方案等内容，**不包含开发代码**。代码应存放在独立的代码仓库中。

## 仓库定位

### 本仓库包含
✅ 需求文档和变更记录
✅ 技术方案和架构设计
✅ 会议记录和决策文档
✅ 问题跟踪和解决方案
✅ 知识库和最佳实践
✅ 项目文档和使用手册

### 本仓库不包含
❌ 源代码（应在代码仓库）
❌ 构建产物和编译文件
❌ 第三方依赖库
❌ 运行时配置文件

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
存储 AI 提示词相关内容：
- `prompts.md` - 日常提示词记录（不提交到 Git）
- `best-practices.md` - 精选提示词模板（提交到 Git，团队共享）
- `README.md` - 目录使用说明

此目录采用分离管理策略，既保护个人隐私，又能积累团队知识。

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
- 开发日志（进度、里程碑）
- 技术决策记录（ADR - Architecture Decision Records）
- 代码审查总结（不包含代码本身）
- 重构计划和记录

> **注意**：此目录记录开发过程中的决策和总结，不存放源代码。

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
存放团队 Wiki（如 Confluence）上与本项目相关的页面 URL：
- `wiki_url_list.txt` - 记录相关 Wiki 页面的 URL 列表
- 通过 MCP 工具可以按需拉取这些页面内容到本地
- ⚠️ 拉取的 Wiki 页面内容不提交到 Git（已在 .gitignore 中配置）
- 仅提交 URL 列表，保持仓库轻量化

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

### 与代码仓库的关系

本仓库与代码仓库是**独立分离**的：

- **本仓库（文档仓库）**：管理需求、方案、文档、会议记录
- **代码仓库**：存放源代码、测试代码、构建脚本

**推荐实践**：
1. 在代码仓库的 README 中链接到本文档仓库
2. 在本仓库的设计文档中引用代码仓库的 PR/Issue
3. 重要的技术决策在本仓库记录，在代码仓库实施

### 日常记录

1. 每天在 `.prompts/prompts.md` 中记录使用的 AI 提示词（个人记录）
2. 验证有效的提示词整理到 `.prompts/best-practices.md`（团队共享）
3. 在 `development/` 目录下记录开发决策和进度（不包含代码）
4. 遇到问题时在 `issues/` 目录创建问题记录
5. 解决问题后在 `solutions/` 目录记录解决方案

### 版本控制

- 使用 Git 跟踪所有文档变更
- 提交信息遵循规范：`<type>: <description>`
- 类型包括：docs（文档）、feat（新功能）、fix（修复）、refactor（重构）等

### 协作流程

1. 需求提出 → `requirements/`
2. 需求分析 → `analysis/`
3. 方案设计 → `design/`
4. 开发实施 → 在代码仓库进行
5. 过程记录 → `development/`（记录决策和里程碑）
6. 问题追踪 → `issues/` + `solutions/`
7. 会议沟通 → `meetings/`

## 维护建议

- 定期整理和归档文档
- 及时更新 Wiki 和知识库
- 保持目录结构清晰
- 使用有意义的文件命名

---

*Created by init-gitdocs-repo.sh*
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

# 创建目录说明文件
create_directory_readmes() {
    log_info "创建目录说明文件..."

    # design 目录说明
    cat > design/README.md <<'EOF'
# 设计方案目录

本目录用于存放项目的各类设计方案文档。

## 📋 目录组织规范

### 方案命名规范

每个设计方案应创建独立的子目录，按以下格式命名：

```
design/
├── README.md                      # 本文件
├── user-authentication/           # 方案目录（使用小写+连字符）
│   ├── README.md                  # 方案说明文档（必需）
│   ├── design_v1.0.md            # 设计方案 v1.0
│   ├── design_v2.0.md            # 设计方案 v2.0
│   ├── architecture.png           # 架构图
│   └── api-spec.yaml             # API 规范
├── payment-gateway/
│   ├── README.md
│   ├── design_v1.0.md
│   └── sequence-diagram.png
└── ...
```

### 版本命名规范

对于重要的设计方案迭代，使用版本号后缀：

- `design_v1.0.md` - 第一个正式版本
- `design_v2.0.md` - 第二个大版本
- `design_v2.1.md` - 小版本迭代
- `design_draft.md` - 草稿版本（可选）

**版本管理原则：**
- 保留关键版本，便于回溯和对比
- 使用 Git 版本控制跟踪所有变更
- 重大架构调整时创建新的大版本号
- 小优化使用小版本号递增

## 📝 方案 README.md 必需内容

每个设计方案目录下的 `README.md` 必须包含以下信息：

### 1. 方案概述
- **方案名称**：简洁的方案名称
- **方案编号**：DESIGN-YYYYMMDD-XXX（可选）
- **提出日期**：首次提出的日期
- **当前状态**：草稿/评审中/已批准/已实施/已废弃
- **负责人**：方案设计负责人

### 2. 背景与目的
- **业务背景**：为什么需要这个方案
- **现状分析**：当前存在的问题或挑战
- **设计目标**：方案要达成的目标
- **预期收益**：方案实施后的预期效果

### 3. 方案内容
- **架构设计**：整体架构说明
- **核心模块**：主要模块和组件
- **技术选型**：使用的技术栈和工具
- **接口设计**：API/接口规范
- **数据设计**：数据库设计、数据流
- **安全设计**：安全措施和考虑

### 4. 方案评估
- **可行性分析**：技术可行性评估
- **风险评估**：潜在风险和应对措施
- **成本评估**：开发成本、维护成本
- **性能评估**：预期性能指标

### 5. 版本历史
记录主要版本的变更：
```markdown
| 版本 | 日期 | 变更说明 | 作者 |
|-----|------|---------|------|
| v2.0 | 2026-02-15 | 重构认证流程，采用 JWT | 张三 |
| v1.0 | 2026-01-10 | 初始版本，基于 Session | 李四 |
```

### 6. 相关文档
- 相关需求文档链接
- 相关分析文档链接
- 实施代码仓库链接
- 其他参考资料

## 📖 方案模板

创建新方案时，可使用以下模板：

```markdown
# [方案名称] 设计方案

## 基本信息
- **方案编号**: DESIGN-YYYYMMDD-001
- **提出日期**: YYYY-MM-DD
- **当前版本**: v1.0
- **当前状态**: 草稿/评审中/已批准/已实施
- **负责人**: [姓名]

## 背景与目的

### 业务背景
[描述业务背景和需求来源]

### 现状分析
[分析当前存在的问题]

### 设计目标
1. 目标 1
2. 目标 2

### 预期收益
- 收益 1
- 收益 2

## 方案内容

### 架构设计
[整体架构说明，配合架构图]

### 核心模块
#### 模块 1
[模块说明]

#### 模块 2
[模块说明]

### 技术选型
| 技术领域 | 选型 | 理由 |
|---------|------|------|
| 框架 | XXX | YYY |

### 接口设计
[API 设计说明]

### 数据设计
[数据库设计、数据流说明]

### 安全设计
[安全措施和考虑]

## 方案评估

### 可行性分析
- 技术可行性: ✅/⚠️/❌
- 资源可行性: ✅/⚠️/❌
- 时间可行性: ✅/⚠️/❌

### 风险评估
| 风险项 | 影响程度 | 应对措施 |
|-------|---------|---------|
| 风险1 | 高/中/低 | 措施 |

### 成本评估
- 开发成本: [人天]
- 维护成本: [说明]

### 性能评估
- QPS: [指标]
- 响应时间: [指标]
- 其他指标: [说明]

## 版本历史

| 版本 | 日期 | 变更说明 | 作者 |
|-----|------|---------|------|
| v1.0 | YYYY-MM-DD | 初始版本 | [姓名] |

## 相关文档
- 需求文档: [链接]
- 分析文档: [链接]
- 代码仓库: [链接]
- 参考资料: [链接]
```

## ✅ 最佳实践

### 1. 方案评审流程
1. **草稿阶段**：设计人员编写初稿
2. **内部评审**：团队内部讨论和优化
3. **正式评审**：相关方评审并给出意见
4. **批准**：评审通过，方案定稿
5. **实施**：按方案进行开发

### 2. 文档维护
- 方案变更时及时更新文档
- 重大调整创建新版本
- 保留历史版本便于回溯
- 定期回顾和优化

### 3. 图表管理

#### 推荐工具
- **Mermaid**（推荐）：代码化图表，便于版本控制和维护
  - 直接嵌入 Markdown 文档
  - 支持流程图、时序图、类图、状态图等
  - GitHub 原生支持渲染
- **PlantUML**：适合复杂的 UML 图
- **draw.io**：适合自由设计的架构图

#### Mermaid 示例

**流程图：**
\`\`\`mermaid
graph TD
    A[开始] --> B{判断条件}
    B -->|是| C[执行操作1]
    B -->|否| D[执行操作2]
    C --> E[结束]
    D --> E
\`\`\`

**时序图：**
\`\`\`mermaid
sequenceDiagram
    participant 客户端
    participant 服务器
    participant 数据库
    客户端->>服务器: 请求数据
    服务器->>数据库: 查询
    数据库-->>服务器: 返回结果
    服务器-->>客户端: 响应数据
\`\`\`

**架构图：**
\`\`\`mermaid
graph LR
    A[前端] --> B[API网关]
    B --> C[认证服务]
    B --> D[业务服务]
    D --> E[数据库]
    D --> F[缓存]
\`\`\`

#### 图表组织规范
- 简单图表直接嵌入 Markdown（使用 Mermaid）
- 复杂图表存为独立文件（PNG/SVG）
- 图片文件与方案文档放在同一目录
- 图片命名清晰（如 `architecture.png`、`sequence-diagram.png`）
- Mermaid 源码可保存为 `.mmd` 文件便于编辑

### 4. 协作规范
- 使用 Git 分支进行方案编写
- 重要方案通过 PR 进行评审
- 在 PR 中讨论方案细节
- 批准后合并到主分支

## 📚 参考资料

更多模板和示例，请参考：
- `../templates/` - 文档模板目录
- 项目 README.md - 整体目录结构说明

---

*最后更新: $(date +"%Y-%m-%d")*
EOF

    # wiki 目录说明
    cat > wiki/README.md <<'EOF'
# Wiki 页面 URL 管理目录

本目录用于管理团队 Wiki（如 Confluence）上与本项目相关的页面 URL。

## 📋 目录用途

### wiki_url_list.txt
存放项目相关的 Wiki 页面 URL 列表，每行一个 URL。

**示例格式：**
```
# 项目文档
https://wiki.company.com/display/PROJECT/Architecture-Design
https://wiki.company.com/display/PROJECT/API-Documentation

# 需求文档
https://wiki.company.com/display/PROJECT/Requirements-Overview
https://wiki.company.com/display/PROJECT/User-Stories

# 技术方案
https://wiki.company.com/display/PROJECT/Technical-Proposal
```

### 拉取的 Wiki 内容
通过 MCP 工具拉取的 Wiki 页面内容会保存在本目录，但**不会提交到 Git**。

## 🚀 使用方式

### 1. 添加 Wiki 页面 URL

在 `wiki_url_list.txt` 中添加项目相关的 Wiki 页面链接：

```bash
# 编辑 URL 列表
vim wiki/wiki_url_list.txt

# 或使用 echo 追加
echo "https://wiki.company.com/display/PROJECT/NewPage" >> wiki/wiki_url_list.txt
```

### 2. 通过 MCP 工具拉取内容

使用 MCP（Model Context Protocol）工具按需拉取 Wiki 页面内容到本地查看：

```bash
# 使用 Claude Code 或其他 MCP 客户端
# MCP 工具会读取 wiki_url_list.txt 中的 URL
# 并将页面内容拉取到本地
```

**MCP 工具支持：**
- 批量拉取多个页面
- 保持页面格式（Markdown 或 HTML）
- 自动处理认证（如 Confluence API Token）

### 3. 本地查看和使用

拉取的内容可用于：
- 离线查看和参考
- 配合 AI 工具进行文档分析
- 与本地文档交叉引用
- 提取关键信息到本地文档

## ⚠️ 重要说明

### Git 版本控制策略

```
wiki/
├── README.md              ✅ 提交到 Git（本文件）
├── wiki_url_list.txt     ✅ 提交到 Git（URL 列表）
├── page-1.md             ❌ 不提交（拉取的内容）
├── page-2.html           ❌ 不提交（拉取的内容）
└── attachments/          ❌ 不提交（拉取的附件）
```

**原因：**
1. **避免重复**：Wiki 页面已在团队 Wiki 平台维护，无需在 Git 中重复存储
2. **保持同步**：避免本地内容与 Wiki 平台不一致
3. **减少仓库体积**：拉取的内容可能很大，不适合版本控制
4. **按需获取**：团队成员可根据需要随时拉取最新内容

### .gitignore 配置

项目的 `.gitignore` 已配置忽略 wiki 目录下的所有内容，仅保留：
- `wiki_url_list.txt` - URL 列表
- `wiki/.gitkeep` - 目录占位符
- `wiki/README.md` - 本说明文件

## 💡 最佳实践

### 1. URL 分类管理

使用注释对 URL 进行分类：

```
# === 架构设计 ===
https://wiki.company.com/display/PROJECT/Architecture
https://wiki.company.com/display/PROJECT/System-Design

# === API 文档 ===
https://wiki.company.com/display/PROJECT/API-v1
https://wiki.company.com/display/PROJECT/API-v2

# === 需求文档 ===
https://wiki.company.com/display/PROJECT/Requirements
```

### 2. 定期更新 URL 列表

- 新增重要 Wiki 页面时及时添加 URL
- 删除已废弃页面的 URL
- 在提交时说明添加或删除的原因

### 3. 拉取策略

- **按需拉取**：仅在需要时拉取特定页面
- **定期刷新**：重要参考文档可定期重新拉取保持最新
- **临时使用**：拉取的内容仅作临时参考，不依赖本地副本

### 4. 与本地文档的关系

- **Wiki 作为参考**：详细的背景资料、历史记录
- **本地文档为主**：设计方案、技术决策、实施记录
- **交叉引用**：在本地文档中引用 Wiki 页面 URL

## 🔧 MCP 工具配置示例

如果使用 Confluence，可配置 MCP 工具的认证信息（不提交到 Git）：

```yaml
# .env.local（不提交）
CONFLUENCE_URL=https://wiki.company.com
CONFLUENCE_EMAIL=your.email@company.com
CONFLUENCE_API_TOKEN=your-api-token
```

## 📚 相关文档

- 项目 `.gitignore` - Wiki 忽略规则配置
- MCP 工具文档 - 如何拉取 Wiki 内容
- Confluence API 文档 - API 使用说明

---

*创建日期: $(date +"%Y-%m-%d")*
*维护者: 请保持 URL 列表及时更新*
EOF

    # wiki URL 列表文件
    cat > wiki/wiki_url_list.txt <<'EOF'
# Wiki 页面 URL 列表
#
# 说明：
# 1. 每行一个 URL，记录项目相关的 Wiki 页面链接
# 2. 使用 # 开头的行作为注释和分类标识
# 3. 通过 MCP 工具可按需拉取这些页面内容到本地
# 4. 拉取的内容不会提交到 Git，仅 URL 列表被版本控制
#
# 格式示例：
# # === 分类名称 ===
# https://wiki.company.com/display/PROJECT/PageName
#

# === 项目文档 ===
# https://wiki.company.com/display/PROJECT/Overview

# === 架构设计 ===
# https://wiki.company.com/display/PROJECT/Architecture

# === API 文档 ===
# https://wiki.company.com/display/PROJECT/API-Documentation

# === 需求文档 ===
# https://wiki.company.com/display/PROJECT/Requirements

# === 技术方案 ===
# https://wiki.company.com/display/PROJECT/Technical-Proposal

# 请在下方添加项目相关的 Wiki 页面 URL
EOF

    log_info "目录说明文件创建完成"
}


# 创建初始 Git 提交
create_initial_commit() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_warn "未初始化 Git 仓库，跳过提交"
        return
    fi

    git add .
    git commit -m "docs: 初始化 AI 项目 GitDocs 仓库

- 创建标准化目录结构
- 添加 README 和使用说明
- 创建文档模板
- 配置 .gitignore

Co-Authored-By: init-gitdocs-repo.sh" || log_warn "提交失败（可能已存在提交）"

    log_info "创建初始 Git 提交完成"
}

# 主函数
main() {
    echo
    log_info "=========================================="
    log_info "  AI 项目 GitDocs 仓库初始化工具"
    log_info "=========================================="
    echo

    # 检查并准备目标目录
    check_and_prepare_directory

    # 执行初始化步骤
    init_git_repo
    create_directories
    create_prompts_files
    create_prompts_gitignore
    create_readme
    create_gitignore
    create_templates
    create_directory_readmes

    echo
    log_info "✨ AI 项目 GitDocs 仓库初始化完成！"
    log_info "仓库位置: $(pwd)"
    echo
    log_info "接下来你可以："
    echo "  1. 查看 README.md 了解目录结构"
    echo "  2. 查看 .prompts/README.md 了解提示词管理方式"
    echo "  3. 在 .prompts/prompts.md 中记录每日 AI 提示词（个人记录）"
    echo "  4. 在 .prompts/best-practices.md 中整理有效的提示词模板（团队共享）"
    echo "  5. 在相应目录下创建需求、分析、设计等文档"
    echo "  6. 使用 templates/ 目录中的模板快速创建文档"
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