---
name: skill-authoring
description: 'Create, validate, and maintain Claude Code Skills. Use when writing a new skill, reviewing skill structure, or debugging skill-related issues.'
license: MIT
metadata:
  author: Flacier
  version: 1.0.0
  tags: "claude-code, skills, agent-skills, development-tools"
---

# Skill Authoring Guide

编写符合 Agent Skills 规范的 Claude Code Skill。

## Use This Skill When

- 创建新的 Claude Code Skill
- 审查现有 Skill 的结构和规范性
- 调试 Skill 验证失败的问题
- 理解 Skill 文件组织和最佳实践

## Skill 结构

一个标准的 Skill 目录结构：

```
.agents/skills/<skill-name>/
├── SKILL.md              # 主文件（必需）
├── skill.lock.json       # 锁定文件（推荐）
├── evals/
│   └── evals.json        # 测试用例（推荐）
├── references/           # 参考资料（可选）
│   └── spec.md
├── scripts/              # 辅助脚本（可选）
│   └── validate.sh
└── templates/            # 模板文件（可选）
    └── snippet.md
```

## SKILL.md 格式

### Frontmatter（必需）

```yaml
---
name: skill-name                          # 小写字母、数字、连字符
description: '简短描述，说明用途和触发时机。'  # 10-1024 字符，需引号
license: MIT                              # 开源许可证
metadata:
  author: Your Name
  version: 1.0.0
  tags: "tag1, tag2, tag3"
  repository: https://github.com/...
---
```

**关键规则**：
- `name`：只能使用小写字母、数字、连字符
- `description`：必须加引号，长度 10-1024 字符，清晰说明何时使用该 skill
- `description` 是第一段 frontmatter 的 description，不要被示例代码中的 frontmatter 干扰

### Body 内容

```markdown
# Skill 标题

## When to Use / 何时使用

- 触发条件 1
- 触发条件 2

## 核心工作流

1. 步骤一
2. 步骤二
3. 步骤三

## 规则 / Patterns

### 分类一
- 规则 1
- 规则 2

### 分类二
```bash
# 代码示例
```

## Anti-Patterns（禁止做的事）

- 不要做 X
- 避免 Y

## Scope（适用范围）

Apply to:
- `path/pattern/**/*`

Do not over-apply to:
- `excluded/pattern/**/*`
```

## 验证 Skill

运行验证脚本检查规范符合度：

```bash
bash .agents/skills/skill-authoring/scripts/validate_skill.sh
```

验证项：
- Frontmatter 格式正确
- Name 字段合法
- Description 长度和引号
- H1 标题存在
- Body 行数不超过 500（推荐）
- evals.json 存在且合法

## 常见错误

| 错误 | 原因 | 修复 |
|------|------|------|
| Description 长度异常 | 脚本读取了示例代码中的 frontmatter | 使用只提取第一段 frontmatter 的 awk 命令 |
| Name 包含非法字符 | 使用了大写字母或下划线 | 改为小写和连字符 |
| 缺少 H1 标题 | 没有 `# Title` | 添加一级标题 |
| evals.json 格式错误 | JSON 语法错误 | 用 python3 -m json.tool 检查 |

## skill.lock.json 格式

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "lockfileVersion": 1,
  "skill": {
    "name": "skill-name",
    "version": "1.0.0",
    "entry": "SKILL.md",
    "files": [
      "SKILL.md",
      "scripts/helper.sh"
    ],
    "dependencies": {
      "git": ">=2.0.0"
    },
    "checksums": {
      "SKILL.md": "sha256...",
      "scripts/helper.sh": "sha256..."
    }
  },
  "generated": "2026-03-31T00:00:00Z"
}
```

## evals.json 格式

```json
{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 1,
      "prompt": "测试 prompt",
      "expected_output": "预期输出描述",
      "assertions": ["检查点 1", "检查点 2"]
    }
  ]
}
```

## 最佳实践

### Do
- 保持 body 在 500 行以内
- 使用具体的文件路径模式
- 提供清晰的代码示例
- 包含 When to Use 章节
- 声明 Anti-Patterns

### Don't
- 在 frontmatter 中放代码示例
- 使用过长的 description
- 遗漏 H1 标题
- 创建没有测试用例的 skill

## 调试技巧

1. **验证脚本报告 description 长度错误**：
   ```bash
   # 手动计算真实 description 长度
   awk '/^---$/ {found++} found==1 && /^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' SKILL.md | sed "s/^[\\\"']*//;s/[\\\"']*$//" | wc -c
   ```

2. **检查 frontmatter 解析问题**：
   ```bash
   # 确认只提取了第一段 frontmatter
   awk '/^---$/ {found++} found<=2' SKILL.md
   ```

3. **生成 checksum**：
   ```bash
   sha256sum SKILL.md
   ```

---
*参考: https://agentskills.io/specification*
