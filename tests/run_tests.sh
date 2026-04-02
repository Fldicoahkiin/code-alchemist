#!/usr/bin/env bash
# Test runner for Code Alchemist

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running Code Alchemist tests..."
echo ""

# Run smoke tests
if [[ -f "$SCRIPT_DIR/smoke_test.sh" ]]; then
    bash "$SCRIPT_DIR/smoke_test.sh"
else
    echo "[ERROR] smoke_test.sh not found"
    exit 1
fi

# Run validator regression tests
if [[ -f "$SCRIPT_DIR/validator_regression_test.sh" ]]; then
    bash "$SCRIPT_DIR/validator_regression_test.sh"
else
    echo "[ERROR] validator_regression_test.sh not found"
    exit 1
fi
