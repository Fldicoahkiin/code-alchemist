#!/usr/bin/env bash
# Test runner for CodeAlchemist

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running CodeAlchemist tests..."
echo ""

# Run smoke tests
if [[ -f "$SCRIPT_DIR/smoke_test.sh" ]]; then
    bash "$SCRIPT_DIR/smoke_test.sh"
else
    echo "[ERROR] smoke_test.sh not found"
    exit 1
fi
