# CodeAlchemist

> 被毕业的同事其实并没有消失，他们只是被蒸馏成了 Token，换成另一种形式陪伴你。

CodeAlchemist 是一个 Claude Code Skill，用于从 Git 提交历史中学习开发者的编码习惯，并将其提炼成可安装的 Skill。一键完成分析、生成和安装，立即可用。

<div align="center">

[![Bash 3.2+](https://img.shields.io/badge/Bash-3.2%2B-1a1a2e?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-16213e?style=flat-square)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-e94560?style=flat-square)](https://claude.ai/code)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-installable-0f3460?style=flat-square&logo=npm&logoColor=white)](https://agentskills.io)

[English Documentation](README.en.md)

</div>

## 项目介绍

每个工程团队都有成员，他们的编码智慧是无价的——命名约定、架构直觉、测试习惯，这些都塑造了代码库。当他们离开时，这些知识往往也随之而去。

CodeAlchemist 从 Git 历史中捕获这些可重复的工程习惯，将其保存为可操作的 Skill，可以在任何项目中安装使用。

## 功能特点

- **一键炼成**: 在一个工作流中完成 `分析 → 归纳 → 安装`
- **交互式安装**: 可选择安装位置（项目/全局）和 Skill 名称
- **证据提取**: 脚本自动提取提交统计、文件热度、目录分布、diff 样本和存活文件
- **模型归纳**: 基于提取的证据，由 AI 读取代表性源码并归纳以下维度的风格规则：
  - 命名与词汇、结构与边界、数据与控制流
  - 错误处理、测试习惯、注释风格
  - 提交粒度、反模式

## 快速开始

### 安装

#### 方式 1: npx skills add (推荐)

```bash
npx skills add Fldicoahkiin/code-alchemist
```

常用选项：

```bash
# 安装到全局
npx skills add Fldicoahkiin/code-alchemist -g

# 指定 agent
npx skills add Fldicoahkiin/code-alchemist -a claude-code

# 列出可用 skill
npx skills add Fldicoahkiin/code-alchemist --list
```

#### 方式 2: 手动克隆

```bash
cd .agents/skills
git clone https://github.com/Fldicoahkiin/code-alchemist.git code-alchemist
```

### 一键用法 (推荐)

直接告诉 Claude Code：

```
把张三炼成 skill
分析 senior-dev 的代码风格并生成 skill
把 senior-dev 的习惯保存成 skill
```

Claude 将会：
1. 运行分析脚本
2. 读取代表性代码样本
3. 生成完整的 Skill
4. 询问安装偏好
5. 安装并确认

### 手动分析 (高级)

如果你希望单独运行分析：

```bash
bash .agents/skills/code-alchemist/scripts/distill_author.sh \
  --repo /path/to/target/repo \
  --author "Developer Name" \
  --since "6 months ago" \
  --out ./analysis-output
```

然后在 Claude Code 中：

```
基于 ./analysis-output 生成 skill
```

### 脚本选项

```bash
bash .agents/skills/code-alchemist/scripts/distill_author.sh \
  --repo /path/to/repo \          # 必需: 目标仓库
  --author "name|email" \          # 必需: 作者标识
  --since "6 months ago" \         # 可选: 开始日期
  --until "1 month ago" \          # 可选: 结束日期
  --include "src/**" \             # 可选: 包含路径 (可重复)
  --exclude "src/generated/**" \   # 可选: 排除路径 (可重复)
  --max-commits 100 \              # 可选: 限制提交数 (默认: 100)
  --max-examples 10 \              # 可选: 示例提交数 (默认: 10)
  --out /path/to/output            # 必需: 输出目录
```

## 输出文件

| 文件 | 说明 |
|------|------|
| `summary.md` | 人类可读的分析报告 |
| `summary.json` | 结构化统计数据 |
| `file_stats.csv` | 文件级别的修改统计 |
| `example_commits.json` | 代表性提交索引 |
| `examples/*.diff` | 代表性提交的补丁文件 |
| `live_files.txt` | 当前仍存在的代表性文件列表 |

## 为什么用 Shell？

核心分析脚本 `distill_author.sh` 使用 Bash 编写（兼容 3.2+，即 macOS 默认版本），原因如下：

1. **零依赖**: 仅使用标准 Unix 工具 (git, grep, sed, awk)
2. **普遍可用**: 兼容任何有 Bash 3.2+ 的系统（包括 macOS 默认版本）
3. **Git 原生**: 通过子进程直接集成 git 命令
4. **性能**: 对大型仓库进行高效的文本处理
5. **简洁**: 单文件，无需包管理

## 交互式安装

生成 Skill 时，Claude Code 会询问：

> **分析完成。准备安装 skill，请确认：**
>
> **1. 安装位置** - 默认: 当前项目
> - [x] 当前项目 ./.agents/skills/
> - [ ] Claude 全局 ~/.claude/skills/
> - [ ] 其他路径 _____________
>
> **2. Skill 名称** - 默认: `<author>-style`
> _____________

确认后，Skill 即安装完成，可立即使用：

```
使用 <author>-style 创建一个用户列表组件
按照 <author> 的习惯重构这段代码
```

## 生成的 Skill 结构

生成的 Skill 包含：

```
.agents/skills/<author>-style/
├── SKILL.md              # 风格规则和模式
├── evals/
│   └── evals.json        # 验证测试用例
└── README.md             # 使用指南
```

## 使用场景

### 保留专家知识

当核心团队成员离职时，提取他们的工程风格，帮助新成员快速学习团队的「隐形规范」。

### 统一团队代码风格

分析团队中最资深成员的提交历史，生成团队代码规范，确保新人代码符合团队习惯。

### 创建个人编码助手

将自己的代码风格提炼成 skill，让 Claude Code 在你的个人项目中保持一致的编码风格。

### 跨项目一致性

在多个项目中安装相同的 Skill，在整个代码库中保持一致的编码风格。

## 项目结构

```
code-alchemist/
├── .agents/skills/code-alchemist/
│   ├── SKILL.md                              # Skill 定义文件
│   ├── scripts/
│   │   ├── distill_author.sh                 # 核心分析脚本 (POSIX Shell)
│   │   └── validate_skill.sh                 # Skill 验证脚本
│   ├── references/
│   │   ├── distillation-dimensions.md        # 8 维度提取清单
│   │   └── output-contract.md                # 输出格式规范
│   ├── templates/
│   │   ├── skill-template.md                 # Skill 生成模板
│   │   └── agents-snippet.md                 # AGENTS.md 片段模板
│   └── evals/
│       └── evals.json                        # 评估测试用例
├── installer/                                # npx 安装器包
│   ├── install.js                            # 交互式安装脚本
│   ├── package.json                          # npm 包清单
│   └── README.md                             # 安装器文档
├── LICENSE                                   # MIT 许可证
├── README.md                                 # 本文档（中文）
└── README.en.md                              # 英文文档
```

## 提取维度

根据 `references/distillation-dimensions.md`，我们从以下 8 个维度提取开发者风格：

1. **命名与词汇** - 领域术语、变量命名长度、命名后缀
2. **结构与边界** - 文件职责、逻辑内联 vs 提取
3. **数据与控制流** - 状态管理、纯函数偏好
4. **错误处理与可观测性** - 错误模式、日志、追踪
5. **测试习惯** - 测试密度、测试类型、回归覆盖
6. **注释与文档** - 注释风格、魔法数字处理
7. **提交粒度** - 提交大小、重构分离、动词使用
8. **显式反模式** - 作者一贯避免的模式

## 注意事项

- 分析结果的可信度取决于目标作者的提交数量和一致性
- 建议至少分析 20+ 个提交以获得可靠结果
- 优先信任重复出现的模式，而非一次性事件
- 避免捕获个人语气或情绪表达
- 当历史代码与当前代码冲突时，以当前代码为准
- 生成的 Skill 在团队部署前应经过审核

## 示例

### 分析 React 项目资深开发者的风格

```bash
bash scripts/distill_author.sh \
  --repo ~/projects/awesome-react-app \
  --author "senior-dev@company.com" \
  --include "src/components/**" \
  --include "src/hooks/**" \
  --since "12 months ago" \
  --out ./senior-dev-style
```

然后在 Claude Code 中：

```
使用 code-alchemist skill 基于 ./senior-dev-style 分析结果生成 skill
```

或简单地说：

```
把 senior-dev 炼成 skill
```

## 开发者信息

用户通过 `npx skills add Fldicoahkiin/code-alchemist` 安装，skill 文件从 GitHub 仓库下载。

确保 `.agents/skills/code-alchemist/` 目录下的 skill 文件保持最新即可。

## 许可证

[MIT](LICENSE)

---

<div align="center">

**将每一位优秀的工程师，都变成可传承的智慧 Token。**

</div>
