---
name: code-alchemist
description: 'Distill developer coding style from git history into Author Profile, AGENTS snippet, Copilot instructions, or reusable Skill. Use when analyzing code patterns, preserving engineering habits, or creating shareable style guides.'
license: MIT
metadata:
  author: Flacier
  version: 1.2.0
  tags: "git, code-style, developer-tools, claude-code"
  repository: https://github.com/Fldicoahkiin/code-alchemist
---

# Code Alchemist

Turn one developer's repeatable engineering habits into an installable Claude Code Skill.

## When to Use

Use this skill when you want to:

- ** distill coding style**: "把张三炼成 skill", "analyze senior-dev's coding style", "preserve someone's habits"
- **Generate style guides**: Create Author Profile, AGENTS.md snippet, Copilot instructions, or reusable Skill
- **Analyze code patterns**: Understand how a developer structures code, names variables, handles errors
- **Preserve engineering habits**: Capture repeatable patterns from an experienced developer
- **Create shareable artifacts**: Turn personal coding conventions into team standards

Do not use this skill when:
- You just need general code review (no specific author's style to emulate)
- The repository has too few commits from the target author (< 10 commits)
- You need real-time analysis of code not yet committed

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
From `live_files.txt`, read 3-5 representative files based on:
- Top 2-3 most modified files (highest change frequency)
- 1 file from the most active directory
- 1 test file if present in the stats

Look for: naming patterns, import order, state management, error handling, file organization.

### Step 4: Generate Skill
Create a complete, installable skill with these files:

#### 4.1 Determine Installation Preferences

**Default behavior (use without asking):**
- **Location**: Current project `.agents/skills/`
- **Name**: `<author>-style`

Only ask the user if they explicitly mention wanting a different location (global) or a custom name. Otherwise, proceed directly with the defaults.

#### 4.2 Create Directory Structure (Staging)

First generate the skill to a staging directory, then install to the target location:

```
/tmp/<author>-skill/          # Staging directory (temporary)
├── SKILL.md
└── evals/
    └── evals.json
```

The staging directory allows review before final installation.

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

Install using the default method (copy) at the default location. Only use symlink if the user explicitly requests it.

**Default (复制):**
```bash
mkdir -p .agents/skills/<skill-name>
cp -r /tmp/<author>-skill/* .agents/skills/<skill-name>/
```

**Alternative (软链接) - only if user requests:**
```bash
mkdir -p $(dirname .agents/skills/<skill-name>)
ln -s /tmp/<author>-skill .agents/skills/<skill-name>
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
