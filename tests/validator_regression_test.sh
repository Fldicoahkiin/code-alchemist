#!/usr/bin/env bash
# Validator regression tests - ensure validators correctly catch spec violations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Validators to test
VALIDATORS=(
    "$REPO_ROOT/.agents/skills/code-alchemist/scripts/validate_skill.sh"
    "$REPO_ROOT/.agents/skills/skill-authoring/scripts/validate_skill.sh"
)

TOTAL_PASSED=0
TOTAL_FAILED=0

# Create temp directory for test skills
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Test helper function
run_test() {
    local validator="$1"
    local test_name="$2"
    local skill_name="$3"
    local frontmatter="$4"
    local should_pass="$5"  # "pass" or "fail"

    # Create test skill structure
    TEST_SKILL_DIR="$TEMP_DIR/$skill_name"
    mkdir -p "$TEST_SKILL_DIR/scripts" "$TEST_SKILL_DIR/evals"

    # Create SKILL.md
    cat > "$TEST_SKILL_DIR/SKILL.md" << EOF
---
$frontmatter
---

# Test Skill

## When to Use

Test description.

## Patterns

- Pattern 1
EOF

    # Create minimal evals.json
    echo '{"skill_name": "test", "evals": []}' > "$TEST_SKILL_DIR/evals/evals.json"

    # Copy validator to test location
    cp "$validator" "$TEST_SKILL_DIR/scripts/validate_skill.sh"

    # Run validation
    if bash "$TEST_SKILL_DIR/scripts/validate_skill.sh" > /dev/null 2>&1; then
        actual_result="pass"
    else
        actual_result="fail"
    fi

    if [[ "$actual_result" == "$should_pass" ]]; then
        echo "[PASS] $test_name"
        return 0
    else
        echo "[FAIL] $test_name (expected $should_pass, got $actual_result)"
        return 1
    fi
}

# Run all tests for a specific validator
test_validator() {
    local validator="$1"
    local validator_name=$(basename $(dirname $(dirname "$validator")))
    local PASSED=0
    local FAILED=0

    echo "=========================================="
    echo "Testing: $validator_name"
    echo "=========================================="
    echo ""

    echo "Testing name validation rules..."
    echo ""

    # Test: Valid name
    if run_test "$validator" "Valid name (lowercase-with-hyphens)" "valid-name" \
        "name: valid-name
description: 'A valid test skill'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "pass"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Name starting with hyphen
    if run_test "$validator" "Invalid: name starting with hyphen" "-bad-name" \
        "name: -bad-name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Name ending with hyphen
    if run_test "$validator" "Invalid: name ending with hyphen" "bad-name-" \
        "name: bad-name-
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Name with consecutive hyphens
    if run_test "$validator" "Invalid: name with consecutive hyphens" "bad--name" \
        "name: bad--name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Name with uppercase
    if run_test "$validator" "Invalid: name with uppercase" "Bad-Name" \
        "name: Bad-Name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Name with underscore
    if run_test "$validator" "Invalid: name with underscore" "bad_name" \
        "name: bad_name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    echo ""
    echo "Testing description validation rules..."
    echo ""

    # Test: Short description (1 char - should pass now)
    if run_test "$validator" "Valid: short description (1 char)" "short-desc" \
        "name: short-desc
description: 'X'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "pass"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Empty description
    if run_test "$validator" "Invalid: empty description" "empty-desc" \
        "name: empty-desc
description: ''
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Long description (>1024 chars)
    LONG_DESC=$(python3 -c "print('A' * 1025)")
    if run_test "$validator" "Invalid: description >1024 chars" "long-desc" \
        "name: long-desc
description: '$LONG_DESC'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    echo ""
    echo "Testing required fields..."
    echo ""

    # Test: Missing license
    if run_test "$validator" "Invalid: missing license" "no-license" \
        "name: no-license
description: 'No license'
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Missing metadata.author
    if run_test "$validator" "Invalid: missing metadata.author" "no-author" \
        "name: no-author
description: 'No author'
license: MIT
metadata:
  version: 1.0.0
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Missing metadata.version
    if run_test "$validator" "Invalid: missing metadata.version" "no-version" \
        "name: no-version
description: 'No version'
license: MIT
metadata:
  author: Test
  tags: test" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    # Test: Missing metadata.tags
    if run_test "$validator" "Invalid: missing metadata.tags" "no-tags" \
        "name: no-tags
description: 'No tags'
license: MIT
metadata:
  author: Test
  version: 1.0.0" \
        "fail"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    echo ""
    echo "Testing directory name matching..."
    echo ""

    # Create a test where skill name doesn't match directory
    TEST_SKILL_DIR="$TEMP_DIR/name-mismatch-$validator_name"
    mkdir -p "$TEST_SKILL_DIR/scripts" "$TEST_SKILL_DIR/evals"
    cat > "$TEST_SKILL_DIR/SKILL.md" << 'EOF'
---
name: different-name
description: 'Name does not match directory'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test
---

# Test Skill

## When to Use

Test.
EOF
    echo '{"skill_name": "test", "evals": []}' > "$TEST_SKILL_DIR/evals/evals.json"
    cp "$validator" "$TEST_SKILL_DIR/scripts/validate_skill.sh"

    if bash "$TEST_SKILL_DIR/scripts/validate_skill.sh" > /dev/null 2>&1; then
        echo "[FAIL] Invalid: name not matching directory (expected fail, got pass)"
        FAILED=$((FAILED + 1))
    else
        echo "[PASS] Invalid: name not matching directory"
        PASSED=$((PASSED + 1))
    fi

    echo ""
    echo "------------------------------------------"
    echo "$validator_name Results:"
    echo "  Passed: $PASSED"
    echo "  Failed: $FAILED"
    echo "------------------------------------------"
    echo ""

    TOTAL_PASSED=$((TOTAL_PASSED + PASSED))
    TOTAL_FAILED=$((TOTAL_FAILED + FAILED))
}

# Run tests for all validators
for validator in "${VALIDATORS[@]}"; do
    if [[ -f "$validator" ]]; then
        test_validator "$validator"
    else
        echo "[ERROR] Validator not found: $validator"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
done

echo "=========================================="
echo "Overall Test Results:"
echo "  Passed: $TOTAL_PASSED"
echo "  Failed: $TOTAL_FAILED"
echo "=========================================="

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo "[PASS] All regression tests passed for all validators!"
    exit 0
else
    echo "[FAIL] $TOTAL_FAILED test(s) failed"
    exit 1
fi
