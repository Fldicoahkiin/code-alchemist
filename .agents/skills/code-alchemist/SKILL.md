---
name: code-alchemist
description: 'Distill one developer''s code style from git commit history into a reusable Claude Code Skill. Use when asked to "炼成skill", "analyze coding style", "preserve someone''s habits", or when you need to turn a developer''s patterns into a shareable skill that can be installed in any project.'
license: MIT
metadata:
  author: Flacier
  version: 1.0.0
  tags: "git, code-style, developer-tools, claude-code"
  repository: https://github.com/Fldicoahkiin/code-alchemist
---

# CodeAlchemist

Turn one developer's repeatable engineering habits into an installable Claude Code Skill.

## One-Command Workflow

**The user can say:**
> "把张三炼成 skill"
> "分析 senior-dev 的代码风格并生成 skill"
> "把李四的习惯保存成 skill"

**You (Claude) will:**

### Step 1: Run Analysis
Execute the extraction script automatically:

```bash
bash .agents/skills/code-alchemist/scripts/distill_author.sh \
  --repo <repo-path> \
  --author "<author-name-or-email>" \
  --since "6 months ago" \
  --out /tmp/<author>-analysis
```

If the user didn't specify a repo, ask for it. If they didn't specify an author, ask for it.

### Step 2: Read Analysis Results
Read these files to understand the author's patterns:
- `/tmp/<author>-analysis/summary.md` - overview
- `/tmp/<author>-analysis/summary.json` - structured data
- `/tmp/<author>-analysis/live_files.txt` - files that still exist
- `/tmp/<author>-analysis/example_commits.json` - sample commits

### Step 3: Deep Dive Code Samples
From `live_files.txt`, read 3-5 representative files:
- 1-2 most modified components
- 1 hook file
- 1 utility/lib file

Look for: naming patterns, import order, state management, error handling, file organization.

### Step 4: Generate Skill
Create a complete, installable skill with these files:

#### 4.1 Ask User for Installation Preferences

**Present options in the user's current language.** If the conversation is in Chinese, ask in Chinese. If English, ask in English.

**Example prompts:**

Chinese:
> "分析完成。准备安装 skill，请确认："
>
> **1. 安装位置** - 默认: 当前项目
> - [x] 当前项目 ./.agents/skills/
> - [ ] Claude 全局 ~/.claude/skills/
> - [ ] 其他路径 _____________
>
> **2. Skill 名称** - 默认: `<author>-style`
> _____________

English:
> "Analysis complete. Ready to install the skill. Please confirm:"
>
> **1. Install Location** - default: current project
> - [x] Current project ./.agents/skills/
> - [ ] Claude global ~/.claude/skills/
> - [ ] Other path _____________
>
> **2. Skill Name** - default: `<author>-style`
> _____________

Wait for user confirmation before proceeding.

#### 4.2 Create Directory Structure
Based on user choices:

```
[selected-location]/<skill-name>/
├── SKILL.md
└── evals/
    └── evals.json
```

#### 4.3 Generate SKILL.md
Use this template (adapt content based on analysis):

```markdown
---
name: <skill-name>
description: 'Code like <author> - [brief description of their style]. Use when writing [language/framework] code that should match their conventions in [project type].'
---

# <author> Coding Style

## Naming Conventions

### [Components/Functions/Types]
- [Pattern 1 with example]
- [Pattern 2 with example]

## Code Organization

### Imports
1. [Import order rule]
2. [Import order rule]

### File Structure
- [Rule 1]
- [Rule 2]

## Patterns

### [Category]
```[language]
// Example code showing the pattern
```

## Anti-Patterns

- Do not [anti-pattern 1]
- Do not [anti-pattern 2]

## Applicability

Apply to:
- `path/pattern/**/*`

Do not over-apply to:
- `excluded/pattern/**/*`

---
*Distilled from [N] commits ([+additions]/-[deletions]) in [repo]*
```

#### 4.4 Generate evals.json
Create at least 3 test cases:

```json
{
  "skill_name": "<skill-name>",
  "evals": [
    {
      "id": 1,
      "prompt": "Write a [component type] that [does something] following <author>'s style",
      "expected_output": "Component uses [pattern 1], [pattern 2]",
      "assertions": ["Uses naming convention X", "Follows import order Y"]
    }
  ]
}
```

#### 4.5 (Optional) Generate README.md
If the user explicitly requests it, create a brief usage guide for the generated skill. Otherwise, skip this step.

### Step 5: Install the Skill

Based on user's installation choice:

#### Option A: Copy (默认)
```bash
mkdir -p [target-dir]
cp -r [generated-skill]/* [target-dir]/
```

#### Option B: Symlink
```bash
mkdir -p $(dirname [target-dir])
ln -s [generated-skill] [target-dir]
```

Confirm success with details in user's language:

Chinese:
> "已成功将 <author> 炼成 skill"
> "安装位置: [full-path]"
> "安装方式: [复制/软链接]"
> "使用: 直接说'使用 <skill-name> 风格写代码'"

English:
> "Successfully distilled <author> into a skill"
> "Installed at: [full-path]"
> "Method: [copy/symlink]"
> "Usage: Say 'write code in <skill-name> style'"

## Manual Workflow (Advanced)

If the user wants more control:

```bash
# 1. Run analysis manually
bash .agents/skills/code-alchemist/scripts/distill_author.sh \
  --repo /path/to/repo \
  --author "name" \
  --out ./analysis

# 2. Then ask Claude
"基于 ./analysis 生成 skill"
```

## Analysis Script Options

```bash
bash .agents/skills/code-alchemist/scripts/distill_author.sh \
  --repo /path/to/repo \          # Required: target repository
  --author "name|email" \          # Required: author identifier
  --since "6 months ago" \         # Optional: start date
  --until "1 month ago" \          # Optional: end date
  --include "src/**" \             # Optional: include paths (repeatable)
  --exclude "src/generated/**" \   # Optional: exclude paths (repeatable)
  --max-commits 100 \              # Optional: limit commits (default: 100)
  --max-examples 10 \              # Optional: example commits (default: 10)
  --out /path/to/output            # Required: output directory
```

## What Makes a Good Skill

### High-Confidence Rules (keep these)
- Naming patterns seen across multiple files
- Consistent import organization
- Repeated architectural patterns
- Stable file structure preferences

### Tentative Observations (mark as low confidence)
- Patterns from < 3 files
- One-off naming exceptions
- Experimental code patterns
- Formatting-only changes

### Anti-Patterns (explicitly forbid)
- Patterns the author consistently replaces in refactor commits
- Styles seen in old commits but not recent ones
- Copy-pasted patterns from external sources

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No commits found | Check author spelling or try email instead of name |
| Analysis too slow | Use `--include` to narrow to specific directories |
| Generated skill doesn't match | Read more sample files from different time periods |
| Author uses inconsistent styles | Note this in "Do not over-apply" section |

## References

- `references/distillation-dimensions.md`: 8 dimensions to analyze
- `references/output-contract.md`: Output format specifications
- Official skill spec: https://agentskills.io/specification
