<div align="center">

# Code Alchemist

> The departed colleague hasn't truly left—they've been distilled into tokens, continuing to guide you in a new form.

**Code Alchemist is a Claude Code Skill that learns a developer's coding style from Git commit history and distills it into an installable Skill. Instantly distilled.**

<br>

[![License](https://img.shields.io/badge/License-MIT-f7c948?style=for-the-badge&labelColor=333333)](LICENSE) [![Bash](https://img.shields.io/badge/Bash-3.2%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white&labelColor=333333)](https://www.gnu.org/software/bash/) [![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-D97757?style=for-the-badge&labelColor=333333&logo=anthropic&logoColor=white)](https://claude.ai/code) [![npm](https://img.shields.io/badge/npm-installable-CB3837?style=for-the-badge&logo=npm&logoColor=white&labelColor=333333)](https://www.npmjs.com/)

[中文文档](README.md)

</div>

---

## Overview

Every engineering team has members whose coding wisdom is invaluable—their naming conventions, architectural instincts, and testing habits shape the codebase. When they move on, that knowledge often leaves with them.

Code Alchemist captures these repeatable engineering habits from Git history, preserving them as an actionable Skill that can be installed in any project.

## Features

- **One-Command Distillation**: `analyze → synthesize → install` in a single workflow
- **Interactive Installation**: Choose location (project/global) and skill name
- **Evidence Extraction**: Script automatically extracts commit stats, file hotspots, directory distribution, diff samples, and live files
- **Model Synthesis**: Based on extracted evidence, AI reads representative source files and synthesizes style rules across:
  - Naming & vocabulary, structure & boundaries, data & control flow
  - Error handling, testing habits, comment style
  - Commit granularity, anti-patterns

## Quick Start

### Installation

#### Option 1: npx skills add (Recommended)

```bash
npx skills add Fldicoahkiin/code-alchemist
```

Common options:

```bash
# Install globally
npx skills add Fldicoahkiin/code-alchemist -g

# Target a specific agent
npx skills add Fldicoahkiin/code-alchemist -a claude-code

# List available skills
npx skills add Fldicoahkiin/code-alchemist --list
```

#### Option 2: Manual Clone

```bash
cd .agents/skills
git clone https://github.com/Fldicoahkiin/code-alchemist.git code-alchemist
```

### One-Command Usage (Recommended)

Simply tell Claude Code:

```
把张三炼成 skill
分析 senior-dev 的代码风格并生成 skill
把 senior-dev 的习惯保存成 skill
```

Claude will:
1. Run the analysis script
2. Read representative code samples
3. Generate a complete Skill
4. Install to current project (default)
5. Confirm completion

> **Note**: By default, installs directly to the current project. To customize installation location, explicitly state "install globally" or "ask before installing" in your instruction.

### Manual Analysis (Advanced)

If you prefer to run analysis separately:

```bash
bash .agents/skills/code-alchemist/scripts/distill_author.sh \
  --repo /path/to/target/repo \
  --author "Developer Name" \
  --since "6 months ago" \
  --out ./analysis-output
```

Then in Claude Code:

```
基于 ./analysis-output 生成 skill
```

### Script Options

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

## Output Files

| File | Description |
|------|-------------|
| `summary.md` | Human-readable analysis report |
| `summary.json` | Structured statistics |
| `file_stats.csv` | File-level modification statistics |
| `example_commits.json` | Index of representative commits |
| `examples/*.diff` | Patch files of representative commits |
| `live_files.txt` | List of representative files that still exist |

## Why Shell?

The core analysis script `distill_author.sh` is written in Bash (compatible with 3.2+, the macOS default) because:

1. **Zero Dependencies**: Uses only standard Unix tools (git, grep, sed, awk)
2. **Universal Availability**: Works on any system with Bash 3.2+ (including macOS default)
3. **Git Native**: Direct integration with git commands via subprocess
4. **Performance**: Efficient text processing for large repositories
5. **Simplicity**: Single file, no package management needed

## Interactive Installation

When generating a Skill, Claude Code will ask:

> **Analysis complete. Ready to install the skill. Please confirm:**
>
> **1. Install Location** - default: current project
> - [x] Current project ./.agents/skills/
> - [ ] Claude global ~/.claude/skills/
> - [ ] Other path _____________
>
> **2. Skill Name** - default: `<author>-style`
> _____________

After confirmation, the Skill is installed and ready to use:

```
使用 <author>-style 创建一个用户列表组件
按照 <author> 的习惯重构这段代码
```

## Generated Skill Structure

A generated Skill contains:

```
.agents/skills/<author>-style/
├── SKILL.md              # Style rules and patterns
└── evals/
    └── evals.json        # Test cases for validation
```

## Use Cases

### Preserving Expert Knowledge

When a key team member departs, extract their engineering style to help new members learn the team's implicit conventions.

### Standardizing Team Style

Analyze the most senior member's commit history to generate team coding standards, ensuring newcomers write code that fits the team's habits.

### Creating Personal Coding Assistants

Distill your own coding style into a skill that Claude Code can use to maintain consistency across your personal projects.

### Cross-Project Consistency

Install the same Skill in multiple projects to maintain consistent coding style across your entire codebase.

## Project Structure

```
code-alchemist/
├── .agents/skills/code-alchemist/
│   ├── SKILL.md                              # Skill definition
│   ├── scripts/
│   │   ├── distill_author.sh                 # Core analysis script (Bash 3.2+)
│   │   └── validate_skill.sh                 # Skill validation script
│   ├── references/
│   │   ├── distillation-dimensions.md        # 8-dimension extraction checklist
│   │   └── output-contract.md                # Output format specifications
│   ├── templates/
│   │   ├── skill-template.md                 # Template for generated skills
│   │   └── agents-snippet.md                 # Template for AGENTS.md snippets
│   └── evals/
│       └── evals.json                        # Evaluation test cases
├── installer/                                # npx installer package
│   ├── install.js                            # Interactive installer script
│   ├── package.json                          # npm package manifest
│   └── README.md                             # Installer documentation
├── LICENSE                                   # MIT License
├── README.md                                 # Chinese documentation
└── README.en.md                              # This file (English)
```

## Distillation Dimensions

Based on `references/distillation-dimensions.md`, we extract developer style across 8 dimensions:

1. **Naming & Vocabulary** - Domain terms, variable name length, naming suffixes
2. **Structure & Boundaries** - File responsibilities, inline vs extracted logic
3. **Data & Control Flow** - State management, pure function preference
4. **Error Handling & Observability** - Error patterns, logging, tracing
5. **Testing Habits** - Test density, test types, regression coverage
6. **Comments & Documentation** - Comment style, magic number handling
7. **Change Granularity** - Commit size, refactoring separation, verb usage
8. **Explicit Anti-Patterns** - Patterns the author consistently avoids

## Notes

- Result reliability depends on the target author's commit count and consistency
- Recommend analyzing 20+ commits for reliable results
- Trust repeated patterns over one-off events
- Avoid capturing personal tone or emotional expressions
- When historical code conflicts with current code, follow the current codebase
- Generated Skills should be reviewed before team-wide deployment

## Example

### Analyzing a Senior React Developer's Style

```bash
bash scripts/distill_author.sh \
  --repo ~/projects/awesome-react-app \
  --author "senior-dev@company.com" \
  --include "src/components/**" \
  --include "src/hooks/**" \
  --since "12 months ago" \
  --out ./senior-dev-style
```

Then in Claude Code:

```
使用 code-alchemist skill 基于 ./senior-dev-style 分析结果生成 skill
```

Or simply:

```
把 senior-dev 炼成 skill
```

## For Developers

Users install via `npx skills add Fldicoahkiin/code-alchemist`, which pulls skill files from this GitHub repository.

Keep the `.agents/skills/code-alchemist/` directory up to date with the latest skill files.

## License

[MIT](LICENSE)

---

<div align="center">

**Preserve every great engineer as transferable tokens of wisdom.**

</div>
