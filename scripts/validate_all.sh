#!/usr/bin/env bash
# Validate all skills in the repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILLS=(
    ".agents/skills/code-alchemist"
    ".agents/skills/skill-authoring"
)

FAILED=0
PASSED=0

echo "=========================================="
echo "Validating All Skills"
echo "=========================================="
echo ""

for skill_path in "${SKILLS[@]}"; do
    skill_name=$(basename "$skill_path")
    validator="$REPO_ROOT/$skill_path/scripts/validate_skill.sh"

    echo "Validating: $skill_name"
    if [[ -x "$validator" ]]; then
        if bash "$validator"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    else
        echo "  [ERROR] Validator not found: $validator"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "=========================================="
echo "Validation Results:"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "=========================================="

if [[ $FAILED -eq 0 ]]; then
    echo "[PASS] All skills passed validation!"
    exit 0
else
    echo "[FAIL] $FAILED skill(s) failed validation"
    exit 1
fi
