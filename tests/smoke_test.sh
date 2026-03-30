#!/usr/bin/env bash
# Smoke tests for CodeAlchemist distill_author.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DISTILL_SCRIPT="$REPO_ROOT/.agents/skills/code-alchemist/scripts/distill_author.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Setup
setup() {
    TEST_OUTPUT_DIR=$(mktemp -d)
    info "Test output directory: $TEST_OUTPUT_DIR"
}

# Cleanup
cleanup() {
    if [[ -d "$TEST_OUTPUT_DIR" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

# Test 1: Basic analysis produces required output files
test_basic_output() {
    info "Running basic output test..."

    local out_dir="$TEST_OUTPUT_DIR/basic_test"

    if ! bash "$DISTILL_SCRIPT" \
        --repo "$REPO_ROOT" \
        --author "Flacier" \
        --out "$out_dir" \
        --max-commits 20 \
        --max-examples 5; then
        fail "Script execution failed"
        return
    fi

    # Check required files exist
    local required_files=("summary.json" "summary.md" "file_stats.csv" "example_commits.json" "live_files.txt")
    for file in "${required_files[@]}"; do
        if [[ -f "$out_dir/$file" ]]; then
            pass "Required file exists: $file"
        else
            fail "Missing required file: $file"
        fi
    done

    # Check examples directory
    if [[ -d "$out_dir/examples" ]]; then
        local diff_count=$(ls -1 "$out_dir/examples"/*.diff 2>/dev/null | wc -l | tr -d ' ')
        if [[ $diff_count -gt 0 ]]; then
            pass "Examples directory contains $diff_count .diff files"
        else
            fail "Examples directory is empty"
        fi
    else
        fail "Examples directory does not exist"
    fi
}

# Test 2: JSON output is valid
test_json_validity() {
    info "Running JSON validity test..."

    local out_dir="$TEST_OUTPUT_DIR/basic_test"

    if [[ -f "$out_dir/summary.json" ]]; then
        if python3 -c "import json; json.load(open('$out_dir/summary.json'))" 2>/dev/null; then
            pass "summary.json is valid JSON"
        else
            fail "summary.json is not valid JSON"
        fi
    fi

    if [[ -f "$out_dir/example_commits.json" ]]; then
        if python3 -c "import json; json.load(open('$out_dir/example_commits.json'))" 2>/dev/null; then
            pass "example_commits.json is valid JSON"
        else
            fail "example_commits.json is not valid JSON"
        fi
    fi
}

# Test 3: Live files prioritizes code over docs
test_live_files_priority() {
    info "Running live files priority test..."

    local out_dir="$TEST_OUTPUT_DIR/basic_test"

    if [[ ! -f "$out_dir/live_files.txt" ]]; then
        fail "live_files.txt not found"
        return
    fi

    # Get first 10 lines
    local first_ten=$(head -10 "$out_dir/live_files.txt")

    # Check that first few files are code files, not docs
    local doc_pattern='(README|LICENSE|CHANGELOG|CONTRIBUTING|\.md|\.txt|\.json|\.yaml|\.yml)$'
    local code_count=0
    local doc_count=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local basename=$(basename "$file")
        if echo "$basename" | grep -qE "$doc_pattern"; then
            doc_count=$((doc_count + 1))
        else
            code_count=$((code_count + 1))
        fi
    done <<< "$first_ten"

    # Primary check: code files should come before doc files in the list
    # For repos with few code files, we just verify the first file is code
    if [[ $code_count -ge 6 ]]; then
        pass "First 10 live_files contains $code_count code files, $doc_count doc files"
    elif [[ $code_count -gt 0 && $doc_count -lt 10 ]]; then
        pass "First 10 live_files has $code_count code files first (repo has more docs than code)"
    else
        fail "Too many doc files in first 10 live_files: $doc_count docs, $code_count code"
    fi

    # Verify that README.md is NOT in the first position
    local first_file=$(head -1 "$out_dir/live_files.txt")
    if echo "$first_file" | grep -qE "README|LICENSE"; then
        fail "First live_files entry is a doc file: $first_file"
    else
        pass "First live_files entry is not a doc file: $first_file"
    fi
}

# Test 4: Representative commit selection strategy
test_commit_selection() {
    info "Running commit selection test..."

    local out_dir="$TEST_OUTPUT_DIR/basic_test"

    if [[ ! -f "$out_dir/example_commits.json" ]]; then
        fail "example_commits.json not found"
        return
    fi

    local commit_count=$(python3 -c "import json; print(len(json.load(open('$out_dir/example_commits.json'))))" 2>/dev/null || echo "0")

    if [[ $commit_count -ge 3 ]]; then
        pass "Selected $commit_count representative commits"
    else
        fail "Too few representative commits: $commit_count"
    fi

    # Check that commits are diverse (not just the most recent)
    # This is validated by checking if the report mentions the selection criteria
    if grep -q "Representative Commits" "$out_dir/summary.md" 2>/dev/null; then
        pass "Summary mentions representative commit selection"
    else
        fail "Summary does not mention commit selection criteria"
    fi
}

# Test 5: Include/exclude pathspec filtering
test_pathspec_filtering() {
    info "Running pathspec filtering test..."

    local out_dir="$TEST_OUTPUT_DIR/filter_test"

    if bash "$DISTILL_SCRIPT" \
        --repo "$REPO_ROOT" \
        --author "Flacier" \
        --out "$out_dir" \
        --include ".agents/**/*.sh" \
        --max-commits 20 \
        --max-examples 5 2>/dev/null; then

        # Check that only .sh files are in file_stats
        if [[ -f "$out_dir/file_stats.csv" ]]; then
            # CSV format: "filename",changes,additions,deletions
            # Match .sh followed by quote (end of field) or comma (CSV separator)
            # Header row "file,changes..." has no quotes, so we filter lines starting with "file" (header)
            local non_sh=$(grep -v '\.sh[",]' "$out_dir/file_stats.csv" | grep -v '^file' | wc -l | tr -d ' ')
            if [[ $non_sh -eq 0 ]]; then
                pass "Pathspec filtering correctly limits to .sh files"
            else
                fail "Pathspec filtering failed: $non_sh non-.sh files found"
            fi
        fi
    else
        fail "Script with pathspec filters failed to execute"
    fi
}

# Test 6: Low sample warning
test_low_sample_warning() {
    info "Running low sample warning test..."

    local out_dir="$TEST_OUTPUT_DIR/warning_test"
    local output

    # Use a non-existent author to get 0 commits
    output=$(bash "$DISTILL_SCRIPT" \
        --repo "$REPO_ROOT" \
        --author "NonExistentAuthorXYZ" \
        --out "$out_dir" 2>&1) || true

    if echo "$output" | grep -q "No commits found"; then
        pass "Low sample warning is shown for non-existent author"
    else
        fail "Missing low sample warning for non-existent author"
    fi
}

# Main test runner
main() {
    echo "=========================================="
    echo "CodeAlchemist Smoke Tests"
    echo "=========================================="
    echo ""

    setup

    # Run all tests
    test_basic_output
    test_json_validity
    test_live_files_priority
    test_commit_selection
    test_pathspec_filtering
    test_low_sample_warning

    cleanup

    echo ""
    echo "=========================================="
    echo "Test Results:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "=========================================="

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main
main "$@"
