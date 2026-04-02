#!/usr/bin/env bash
# Validator regression tests - ensure validator correctly catches spec violations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$REPO_ROOT/.agents/skills/code-alchemist/scripts/validate_skill.sh"

PASSED=0
FAILED=0

echo "=========================================="
echo "Validator Regression Tests"
echo "=========================================="
echo ""

# Create temp directory for test skills
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Test helper function
run_test() {
    local test_name="$1"
    local skill_name="$2"
    local frontmatter="$3"
    local should_pass="$4"  # "pass" or "fail"

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
    cp "$VALIDATOR" "$TEST_SKILL_DIR/scripts/validate_skill.sh"

    # Run validation
    if bash "$TEST_SKILL_DIR/scripts/validate_skill.sh" > /dev/null 2>&1; then
        actual_result="pass"
    else
        actual_result="fail"
    fi

    if [[ "$actual_result" == "$should_pass" ]]; then
        echo "[PASS] $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] $test_name (expected $should_pass, got $actual_result)"
        FAILED=$((FAILED + 1))
    fi
}

echo "Testing name validation rules..."
echo ""

# Test: Valid name
run_test "Valid name (lowercase-with-hyphens)" "valid-name" \
    "name: valid-name
description: 'A valid test skill'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "pass"

# Test: Name starting with hyphen
run_test "Invalid: name starting with hyphen" "-bad-name" \
    "name: -bad-name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Name ending with hyphen
run_test "Invalid: name ending with hyphen" "bad-name-" \
    "name: bad-name-
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Name with consecutive hyphens
run_test "Invalid: name with consecutive hyphens" "bad--name" \
    "name: bad--name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Name with uppercase
run_test "Invalid: name with uppercase" "Bad-Name" \
    "name: Bad-Name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Name with underscore
run_test "Invalid: name with underscore" "bad_name" \
    "name: bad_name
description: 'Invalid name'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

echo ""
echo "Testing description validation rules..."
echo ""

# Test: Short description (1 char - should pass now)
run_test "Valid: short description (1 char)" "short-desc" \
    "name: short-desc
description: 'X'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "pass"

# Test: Empty description
run_test "Invalid: empty description" "empty-desc" \
    "name: empty-desc
description: ''
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Long description (>1024 chars)
LONG_DESC=$(python3 -c "print('A' * 1025)")
run_test "Invalid: description >1024 chars" "long-desc" \
    "name: long-desc
description: '$LONG_DESC'
license: MIT
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

echo ""
echo "Testing required fields..."
echo ""

# Test: Missing license
run_test "Invalid: missing license" "no-license" \
    "name: no-license
description: 'No license'
metadata:
  author: Test
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Missing metadata.author
run_test "Invalid: missing metadata.author" "no-author" \
    "name: no-author
description: 'No author'
license: MIT
metadata:
  version: 1.0.0
  tags: test" \
    "fail"

# Test: Missing metadata.version
run_test "Invalid: missing metadata.version" "no-version" \
    "name: no-version
description: 'No version'
license: MIT
metadata:
  author: Test
  tags: test" \
    "fail"

# Test: Missing metadata.tags
run_test "Invalid: missing metadata.tags" "no-tags" \
    "name: no-tags
description: 'No tags'
license: MIT
metadata:
  author: Test
  version: 1.0.0" \
    "fail"

echo ""
echo "Testing directory name matching..."
echo ""

# Create a test where skill name doesn't match directory
TEST_SKILL_DIR="$TEMP_DIR/name-mismatch"
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
cp "$VALIDATOR" "$TEST_SKILL_DIR/scripts/validate_skill.sh"

if bash "$TEST_SKILL_DIR/scripts/validate_skill.sh" > /dev/null 2>&1; then
    echo "[FAIL] Invalid: name not matching directory (expected fail, got pass)"
    FAILED=$((FAILED + 1))
else
    echo "[PASS] Invalid: name not matching directory"
    PASSED=$((PASSED + 1))
fi

echo ""
echo "=========================================="
echo "Test Results:"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "=========================================="

if [[ $FAILED -eq 0 ]]; then
    echo "[PASS] All regression tests passed!"
    exit 0
else
    echo "[FAIL] $FAILED test(s) failed"
    exit 1
fi
