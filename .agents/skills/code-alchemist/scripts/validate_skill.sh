#!/usr/bin/env bash
# Validate SKILL.md against Agent Skills specification

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_FILE="$SKILL_DIR/SKILL.md"

SPEC_ERRORS=0
WARNINGS=0

echo "Validating CodeAlchemist SKILL.md..."
echo ""

# Check file exists
if [[ ! -f "$SKILL_FILE" ]]; then
    echo "[SPEC ERROR] SKILL.md not found at $SKILL_FILE"
    exit 1
fi

echo "[OK] SKILL.md exists"

# Check frontmatter exists
if ! head -1 "$SKILL_FILE" | grep -q '^---$'; then
    echo "[SPEC ERROR] Missing YAML frontmatter (---)"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
else
    echo "[OK] YAML frontmatter present"
fi

# Extract and validate name (first occurrence after first ---)
NAME=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep '^name:' | head -1 | cut -d: -f2 | tr -d ' ')
if [[ -z "$NAME" ]]; then
    echo "[SPEC ERROR] Missing 'name' field in frontmatter"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
elif [[ "$NAME" =~ [^a-z0-9-] ]]; then
    echo "[SPEC ERROR] Name '$NAME' contains invalid characters (only lowercase letters, numbers, and hyphens allowed)"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
else
    echo "[OK] Name field valid: $NAME"
fi

# Check description exists and length
DESCRIPTION=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep '^description:' | cut -d: -f2- | sed "s/^[\"' ]*//;s/[\"' ]*$//")
DESC_LEN=${#DESCRIPTION}
if [[ -z "$DESCRIPTION" ]]; then
    echo "[SPEC ERROR] Missing 'description' field in frontmatter"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
elif [[ $DESC_LEN -lt 10 ]]; then
    echo "[SPEC ERROR] Description too short ($DESC_LEN chars, minimum 10)"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
elif [[ $DESC_LEN -gt 1024 ]]; then
    echo "[SPEC ERROR] Description too long ($DESC_LEN chars, maximum 1024)"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
else
    echo "[OK] Description valid ($DESC_LEN chars)"
fi

# Check description is quoted
if ! sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep '^description:' | grep -q "['\"]"; then
    echo "[WARNING] Description should be wrapped in single or double quotes"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for required sections
if ! grep -q '^# ' "$SKILL_FILE"; then
    echo "[SPEC ERROR] Missing H1 title (# Title)"
    SPEC_ERRORS=$((SPEC_ERRORS + 1))
else
    echo "[OK] H1 title present"
fi

# When to Use section is best practice, not spec requirement
if ! grep -qi '## Use.*When\|## When.*Use\|## 使用\|## 何时' "$SKILL_FILE"; then
    echo "[WARNING] Missing 'When to Use' section (recommended for better trigger accuracy)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "[OK] 'When to Use' section present"
fi

# Check body content line count (excluding frontmatter)
# Find the second '---' (end of frontmatter) and count lines after it
SEPARATOR_LINES=$(grep -n '^---$' "$SKILL_FILE" | head -2 | tail -1 | cut -d: -f1)
if [[ -n "$SEPARATOR_LINES" ]]; then
    BODY_LINES=$(tail -n +$((SEPARATOR_LINES + 1)) "$SKILL_FILE" | wc -l | tr -d ' ')
else
    # Fallback: count all lines if no frontmatter found
    BODY_LINES=$(wc -l < "$SKILL_FILE" | tr -d ' ')
fi
if [[ $BODY_LINES -gt 500 ]]; then
    echo "[WARNING] Body content is $BODY_LINES lines (recommended under 500)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "[OK] Body content is $BODY_LINES lines"
fi

# Check for evals directory
if [[ -d "$SKILL_DIR/evals" ]]; then
    if [[ -f "$SKILL_DIR/evals/evals.json" ]]; then
        echo "[OK] evals/evals.json present"
        # Validate JSON
        if python3 -c "import json; json.load(open('$SKILL_DIR/evals/evals.json'))" 2>/dev/null; then
            echo "[OK] evals.json is valid JSON"
        else
            echo "[WARNING] evals.json is not valid JSON"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "[WARNING] evals/ directory exists but evals.json not found"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "[WARNING] evals/ directory not found (recommended for testing)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for references
if [[ -d "$SKILL_DIR/references" ]]; then
    REF_COUNT=$(find "$SKILL_DIR/references" -type f | wc -l)
    echo "[OK] references/ directory present ($REF_COUNT files)"
else
    echo "[INFO] references/ directory not found (optional)"
fi

# Check for scripts
if [[ -d "$SKILL_DIR/scripts" ]]; then
    SCRIPT_COUNT=$(find "$SKILL_DIR/scripts" -type f | wc -l)
    echo "[OK] scripts/ directory present ($SCRIPT_COUNT files)"
else
    echo "[INFO] scripts/ directory not found (optional)"
fi

echo ""
if [[ $SPEC_ERRORS -eq 0 ]]; then
    echo "[PASS] Spec validation passed! SKILL.md conforms to Agent Skills specification."
    if [[ $WARNINGS -gt 0 ]]; then
        echo "[INFO] $WARNINGS best-practice warning(s) found (optional improvements)."
    fi
    exit 0
else
    echo "[FAIL] Validation failed with $SPEC_ERRORS spec error(s)."
    if [[ $WARNINGS -gt 0 ]]; then
        echo "[INFO] Also found $WARNINGS warning(s)."
    fi
    exit 1
fi
