#!/usr/bin/env bash
# Generate SHA-256 checksums for skill files and update skill.lock.json

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$SKILL_DIR/skill.lock.json"

echo "Generating checksums for Code Alchemist..."

# Calculate checksums
SKILL_MD_HASH=$(shasum -a 256 "$SKILL_DIR/SKILL.md" | cut -d' ' -f1)
DISTILL_HASH=$(shasum -a 256 "$SKILL_DIR/scripts/distill_author.sh" | cut -d' ' -f1)
VALIDATE_HASH=$(shasum -a 256 "$SKILL_DIR/scripts/validate_skill.sh" | cut -d' ' -f1)

echo "  SKILL.md: $SKILL_MD_HASH"
echo "  scripts/distill_author.sh: $DISTILL_HASH"
echo "  scripts/validate_skill.sh: $VALIDATE_HASH"

# Read current lock file content
if [[ ! -f "$LOCK_FILE" ]]; then
    echo "[ERROR] skill.lock.json not found at $LOCK_FILE"
    exit 1
fi

# Use Python to update JSON (more reliable than sed for JSON)
python3 << EOF
import json
import sys

with open('$LOCK_FILE', 'r') as f:
    data = json.load(f)

data['skill']['checksums'] = {
    'SKILL.md': '$SKILL_MD_HASH',
    'scripts/distill_author.sh': '$DISTILL_HASH',
    'scripts/validate_skill.sh': '$VALIDATE_HASH'
}

data['generated'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'

with open('$LOCK_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')

print('[OK] skill.lock.json updated successfully')
EOF
