#!/usr/bin/env bash
# Generate SHA-256 checksums for skill files and update skill.lock.json

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$SKILL_DIR/skill.lock.json"

echo "Generating checksums for skill-authoring..."

# Read current lock file to get files list
if [[ ! -f "$LOCK_FILE" ]]; then
    echo "[ERROR] skill.lock.json not found at $LOCK_FILE"
    exit 1
fi

# Use Python to generate checksums for all files in skill.lock.json
python3 << EOF
import json
import hashlib
import os
import sys

with open('$LOCK_FILE', 'r') as f:
    data = json.load(f)

files = data['skill']['files']
checksums = {}

for file_path in files:
    full_path = os.path.join('$SKILL_DIR', file_path)
    if os.path.exists(full_path):
        with open(full_path, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()
            checksums[file_path] = file_hash
            print(f"  {file_path}: {file_hash}")
    else:
        print(f"  [WARN] {file_path} not found, skipping")

# Also include the scripts that are tracked but may not be in files list
script_files = ['scripts/validate_skill.sh', 'scripts/generate_checksums.sh']
for script in script_files:
    if script not in checksums:
        full_path = os.path.join('$SKILL_DIR', script)
        if os.path.exists(full_path):
            with open(full_path, 'rb') as f:
                file_hash = hashlib.sha256(f.read()).hexdigest()
                checksums[script] = file_hash
                print(f"  {script}: {file_hash}")

data['skill']['checksums'] = checksums
data['generated'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'

with open('$LOCK_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')

print('[OK] skill.lock.json updated successfully')
print(f'[INFO] Generated {len(checksums)} checksums')
EOF
