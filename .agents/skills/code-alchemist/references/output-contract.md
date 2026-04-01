# Output Contract

Code Alchemist should produce one primary deliverable at a time. Pick the format that best matches the user's goal instead of emitting everything at once.

## 1. Author Profile

Suggested file: `style-profile.md`

Minimum structure:

```markdown
# Author Engineering Profile

## Scope
- repo:
- author:
- since:
- until:

## High-Confidence Rules
- ...

## Tentative Observations
- ...

## Anti-Patterns
- ...

## Evidence Index
- files:
- commits:
```

## 2. AGENTS Snippet

Use this when the distilled rules should become repository collaboration guidance.

Minimum structure:

```markdown
## Code Alchemist Author Style Rules

- Naming:
- Structure:
- Error handling:
- Testing:
- Anti-patterns:
```

## 3. Copilot Instructions Snippet

Use this when the rules should be added to `.github/copilot-instructions.md`.

Minimum structure:

```markdown
## Apply the <author> style in these areas

- Scope:
- Naming:
- Module boundaries:
- Error handling:
- Testing:
- Do not over-apply:
```

## 4. Skill Draft

Use this when one author's style should become a reusable derivative skill.

Minimum structure:

```markdown
---
name:
description:
---

# <skill name>

## Use This Skill When
- ...

## Workflow
- ...

## Rules
- ...

## Anti-Patterns
- ...
```

## Global Rules

- Do not paste large code excerpts
- Do not turn the result into a personality imitation
- Do not promote one-off historical decisions into permanent rules
- Make every conclusion traceable to `summary.json`, `example_commits.json`, `examples/*.diff`, or `live_files.txt`
