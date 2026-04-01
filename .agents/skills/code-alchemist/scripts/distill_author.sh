#!/usr/bin/env bash
# distill_author.sh - Pure shell implementation of author style analysis
# Compatible with Bash 3.2+ (macOS default) and Bash 4+
# Usage: ./distill_author.sh --repo /path/to/repo --author "Name" --since "6 months ago" --out ./output

set -e

# Default values
REPO=""
AUTHORS=()  # Array to support multiple author patterns
SINCE=""
UNTIL=""
MAX_COMMITS=100
MAX_EXAMPLES=10
OUT_DIR=""
INCLUDE_PATTERNS=()
EXCLUDE_PATTERNS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Analyze a developer's coding style from Git history (POSIX shell version)

Required:
  --repo PATH           Path to Git repository
  --author PATTERN      Author name or email pattern (repeatable, supports multiple names)
  --out DIR             Output directory for analysis results

Optional:
  --since DATE          Start date (e.g., "6 months ago", "2024-01-01")
  --until DATE          End date
  --max-commits N       Maximum commits to analyze (default: 100)
  --max-examples N      Maximum example commits to extract (default: 10)
  --include PATTERN     Include paths matching pattern (repeatable)
  --exclude PATTERN     Exclude paths matching pattern (repeatable)
  -h, --help            Show this help message

Examples:
  $0 --repo ~/myproject --author "John Doe" --out ./analysis
  $0 --repo ~/myproject --author "john@example.com" --since "1 year ago" --include "src/**" --out ./analysis
  $0 --repo ~/myproject --author "John" --author "john@example.com" --out ./analysis

EOF
    exit 0
}

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO="$2"
            shift 2
            ;;
        --author)
            AUTHORS+=("$2")
            shift 2
            ;;
        --since)
            SINCE="$2"
            shift 2
            ;;
        --until)
            UNTIL="$2"
            shift 2
            ;;
        --max-commits)
            MAX_COMMITS="$2"
            shift 2
            ;;
        --max-examples)
            MAX_EXAMPLES="$2"
            shift 2
            ;;
        --out)
            OUT_DIR="$2"
            shift 2
            ;;
        --include)
            INCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        --exclude)
            EXCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required args
if [[ -z "$REPO" || ${#AUTHORS[@]} -eq 0 || -z "$OUT_DIR" ]]; then
    log_error "Missing required arguments: --repo, --author, and --out are required"
    usage
    exit 1
fi

# Validate repo exists and is git repo
if [[ ! -d "$REPO" ]]; then
    log_error "Repository directory does not exist: $REPO"
    exit 1
fi

if [[ ! -d "$REPO/.git" && ! -f "$REPO/HEAD" ]]; then
    if ! (cd "$REPO" && git rev-parse --git-dir > /dev/null 2>&1); then
        log_error "Not a valid Git repository: $REPO"
        exit 1
    fi
fi

# Create output directory
mkdir -p "$OUT_DIR"
mkdir -p "$OUT_DIR/examples"

# Join authors for display
AUTHOR_DISPLAY="${AUTHORS[0]}"
for ((i=1; i<${#AUTHORS[@]}; i++)); do
    AUTHOR_DISPLAY="${AUTHOR_DISPLAY}, ${AUTHORS[$i]}"
done

log_info "Analyzing commits by: $AUTHOR_DISPLAY"
log_info "Repository: $REPO"
log_info "Output: $OUT_DIR"

# Build git log command with multiple author support
# Add each author as a separate --author flag (git treats multiple --author as OR)
git_log_opts=()
for author in "${AUTHORS[@]}"; do
    git_log_opts+=("--author=$author")
done
git_log_opts+=("--pretty=format:%H|%an|%ae|%ad|%s")
git_log_opts+=("--date=unix")

if [[ -n "$SINCE" ]]; then
    git_log_opts+=("--since=$SINCE")
fi

if [[ -n "$UNTIL" ]]; then
    git_log_opts+=("--until=$UNTIL")
fi

# Build pathspec filters
pathspec_args=()
for pattern in "${INCLUDE_PATTERNS[@]}"; do
    pathspec_args+=(":(glob)$pattern")
done

for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    pathspec_args+=(":(exclude,glob)$pattern")
done

# Get commits
cd "$REPO"
log_info "Fetching commits..."

commits_all="$OUT_DIR/.commits_all.txt"
commits_file="$OUT_DIR/.commits_raw.txt"

if [[ ${#pathspec_args[@]} -gt 0 ]]; then
    git log "${git_log_opts[@]}" -- "${pathspec_args[@]}" 2>/dev/null > "$commits_all" || true
else
    git log "${git_log_opts[@]}" 2>/dev/null > "$commits_all" || true
fi

# Get list of files in the repository, filtered by pathspec
if [[ ${#pathspec_args[@]} -gt 0 ]]; then
    git ls-files -- "${pathspec_args[@]}" 2>/dev/null > "$OUT_DIR/.repo_files.tmp" || true
else
    git ls-files 2>/dev/null > "$OUT_DIR/.repo_files.tmp" || true
fi

# Filter empty lines (cross-platform compatible, works with both BSD and GNU sed)
grep -v '^$' "$commits_all" > "$commits_all.filtered" && mv "$commits_all.filtered" "$commits_all"

total_commits=$(grep -c '.' "$commits_all" 2>/dev/null) || total_commits=0

if [[ "$total_commits" -eq 0 ]]; then
    log_error "No commits found for author(s): $AUTHOR_DISPLAY"
    rm -f "$commits_all"
    exit 1
fi

head -n "$MAX_COMMITS" "$commits_all" > "$commits_file"
rm -f "$commits_all"

log_info "Found $total_commits commits (Analyzed up to $MAX_COMMITS)"

LOW_SAMPLE_THRESHOLD=10
if [[ "$total_commits" -lt "$LOW_SAMPLE_THRESHOLD" ]]; then
    log_warn "Low sample size: only $total_commits commits found (< $LOW_SAMPLE_THRESHOLD)"
    log_warn "Style conclusions may be unreliable. Consider expanding --since or adding more --author patterns."
fi

# Use temp files instead of associative arrays for Bash 3.2 compatibility
email_list_tmp="$OUT_DIR/.emails.tmp"
date_list_tmp="$OUT_DIR/.dates.tmp"
raw_stats_stream="$OUT_DIR/.raw_stats_stream.tmp"

# Initialize/clear temp files
> "$email_list_tmp"
> "$date_list_tmp"
> "$raw_stats_stream"

commit_count=0
total_additions=0
total_deletions=0

# Read commits and analyze
while IFS='|' read -r hash name email date subject || [[ -n "$hash" ]]; do
    [[ -z "$hash" ]] && continue

    commit_count=$((commit_count + 1))

    # Track emails and dates
    echo "$email" >> "$email_list_tmp"
    echo "$date" >> "$date_list_tmp"

    # Get numstat for this commit
    if [[ ${#pathspec_args[@]} -gt 0 ]]; then
        numstat=$(git diff-tree --root --no-commit-id --numstat -r "$hash" -- "${pathspec_args[@]}" 2>/dev/null || true)
    else
        numstat=$(git diff-tree --root --no-commit-id --numstat -r "$hash" 2>/dev/null || true)
    fi

    while IFS=$'\t' read -r added deleted file; do
        [[ -z "$file" ]] && continue
        [[ "$added" == "-" ]] && continue

        echo "$file|$added|$deleted" >> "$raw_stats_stream"

        total_additions=$((total_additions + added))
        total_deletions=$((total_deletions + deleted))
    done <<< "$numstat"

done < "$commits_file"

log_info "Analyzed $commit_count commits"
log_info "Total changes: +$total_additions -$total_deletions"

# Process raw stats with awk to avoid regex injections and improve performance
file_stats_tmp="$OUT_DIR/.file_stats.tmp"
dir_stats_tmp="$OUT_DIR/.dir_stats.tmp"
ext_stats_tmp="$OUT_DIR/.ext_stats.tmp"

awk -F'|' '{
    file=$1; added=$2; deleted=$3;
    counts[file]++
    adds[file]+=added
    dels[file]+=deleted
} END {
    for (f in counts) {
        print f "|" counts[f] "|" adds[f] "|" dels[f]
    }
}' "$raw_stats_stream" > "$file_stats_tmp"

awk -F'|' '{
    file=$1;
    n = split(file, parts, "/");
    if (n > 1) {
        dir = "";
        for(i=1; i<n; i++) {
            dir = dir (i>1?"/":"") parts[i];
        }
    } else {
        dir = "."
    }
    dir_counts[dir]++
} END {
    for (d in dir_counts) {
        print d "|" dir_counts[d]
    }
}' "$raw_stats_stream" > "$dir_stats_tmp"

awk -F'|' '{
    file=$1;
    n = split(file, parts, "/");
    filename = parts[n];
    
    idx = index(filename, ".");
    if (idx == 0 || (idx == 1 && index(substr(filename, 2), ".") == 0)) {
        ext = "(none)"
    } else {
        m = split(filename, fparts, ".");
        ext = "." fparts[m]
    }
    ext_counts[ext]++
} END {
    for (e in ext_counts) {
        print e "|" ext_counts[e]
    }
}' "$raw_stats_stream" > "$ext_stats_tmp"

rm -f "$raw_stats_stream"

sort -u "$email_list_tmp" > "$OUT_DIR/.emails_uniq.tmp"
mv "$OUT_DIR/.emails_uniq.tmp" "$email_list_tmp"

sort -u "$date_list_tmp" > "$OUT_DIR/.dates_uniq.tmp"
mv "$OUT_DIR/.dates_uniq.tmp" "$date_list_tmp"

# Sort stats files
files_sorted="$OUT_DIR/.files_sorted.txt"
dirs_sorted="$OUT_DIR/.dirs_sorted.txt"
exts_sorted="$OUT_DIR/.exts_sorted.txt"

sort -t'|' -k2 -nr "$file_stats_tmp" > "$files_sorted" 2>/dev/null || true
sort -t'|' -k2 -nr "$dir_stats_tmp" > "$dirs_sorted" 2>/dev/null || true
sort -t'|' -k2 -nr "$ext_stats_tmp" > "$exts_sorted" 2>/dev/null || true

# Score and select representative commits (moved here before summary.md generation)
echo "Selecting representative commits..."

# Define code file extensions for scoring
code_exts='\.(js|jsx|ts|tsx|py|rs|go|java|rb|php|swift|kt|scala|cs|cpp|c|h|hpp|sh|bash|zsh)$'

# Score each commit based on:
# 1. Total lines changed (importance)
# 2. Code file ratio (prioritize code over docs)
# 3. Time period diversity (ensure coverage across date range)
commits_scored="$OUT_DIR/.commits_scored.txt"
> "$commits_scored"

# Get date range for time bucketing (git log outputs newest-first)
first_timestamp=$(tail -1 "$commits_file" | cut -d'|' -f4)  # oldest (last line)
last_timestamp=$(head -1 "$commits_file" | cut -d'|' -f4)   # newest (first line)
first_epoch="${first_timestamp:-0}"
last_epoch="${last_timestamp:-0}"
time_span=$((last_epoch - first_epoch))

# If time span is too small, treat as single period
[[ $time_span -lt 86400 ]] && time_span=86400

while IFS='|' read -r hash name email date subject || [[ -n "$hash" ]]; do
    [[ -z "$hash" ]] && continue

    # Get numstat for this commit
    if [[ ${#pathspec_args[@]} -gt 0 ]]; then
        numstat=$(git diff-tree --root --no-commit-id --numstat -r "$hash" -- "${pathspec_args[@]}" 2>/dev/null || true)
    else
        numstat=$(git diff-tree --root --no-commit-id --numstat -r "$hash" 2>/dev/null || true)
    fi

    total_lines=0
    code_lines=0
    while IFS=$'\t' read -r added deleted file; do
        [[ -z "$file" ]] && continue
        [[ "$added" == "-" ]] && continue

        total_lines=$((total_lines + added + deleted))
        if echo "$file" | grep -qE "$code_exts"; then
            code_lines=$((code_lines + added + deleted))
        fi
    done <<< "$numstat"

    # Calculate score components
    # Size score: log2 of total lines (avoid over-weighting huge commits)
    size_score=0
    if [[ $total_lines -gt 0 ]]; then
        size_score=$(awk "BEGIN {printf \"%.0f\", log($total_lines)/log(2)}")
    fi

    # Code ratio score (0-10): prefer commits with 50-100% code changes
    code_ratio_score=0
    if [[ $total_lines -gt 0 ]]; then
        code_ratio=$((code_lines * 100 / total_lines))
        if [[ $code_ratio -ge 50 ]]; then
            code_ratio_score=10
        elif [[ $code_ratio -ge 20 ]]; then
            code_ratio_score=5
        fi
    fi

    # Time diversity score (0-5): spread across early/middle/recent
    time_score=0
    if [[ $time_span -gt 0 && $first_epoch -gt 0 ]]; then
        commit_epoch="$date"
        if [[ $commit_epoch -gt 0 ]]; then
            # Normalize to 0-100 range based on position in timeline
            position=$(( (commit_epoch - first_epoch) * 100 / time_span ))
            # Give higher score to commits in first 30% or last 30% of time range
            if [[ $position -le 30 || $position -ge 70 ]]; then
                time_score=5
            else
                time_score=2
            fi
        fi
    fi

    # Final score: weighted sum
    final_score=$((size_score * 2 + code_ratio_score * 3 + time_score))

    # Output: score|hash|name|email|date|subject|total_lines|code_lines
    echo "$final_score|$hash|$name|$email|$date|$subject|$total_lines|$code_lines" >> "$commits_scored"
done < "$commits_file"

# Sort by score (descending) and select top commits
commits_selected="$OUT_DIR/.commits_selected.txt"
sort -t'|' -k1 -nr "$commits_scored" | head -n "$MAX_EXAMPLES" | cut -d'|' -f2-6 > "$commits_selected"

log_info "Selected $(wc -l < "$commits_selected" | tr -d ' ') representative commits"

# Analyze commit message patterns
log_info "Analyzing commit message patterns..."

# Count commit patterns by extracting subject field (5th pipe-delimited field)
subjects_file="$OUT_DIR/.subjects.tmp"
awk -F'|' '{print $5}' "$commits_file" > "$subjects_file"

feat_count=$(grep -cE "^(feat|feature)(\([^)]*\))?!?:" "$subjects_file" 2>/dev/null) || feat_count=0
fix_count=$(grep -cE "^fix(\([^)]*\))?!?:" "$subjects_file" 2>/dev/null) || fix_count=0
docs_count=$(grep -cE "^docs?(\([^)]*\))?!?:" "$subjects_file" 2>/dev/null) || docs_count=0
test_count=$(grep -cE "^test(\([^)]*\))?!?:" "$subjects_file" 2>/dev/null) || test_count=0
refactor_count=$(grep -cE "^refactor(\([^)]*\))?!?:" "$subjects_file" 2>/dev/null) || refactor_count=0
chore_count=$(grep -cE "^chore(\([^)]*\))?!?:" "$subjects_file" 2>/dev/null) || chore_count=0
rm -f "$subjects_file"

# JSON escape helper
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g'
}

# Generate summary.json
echo "Generating summary.json..."

{
    echo "{"
    echo "  \"repo\": \"$(json_escape "$REPO")\","
    echo "  \"author\": \"$(json_escape "$AUTHOR_DISPLAY")\","
    echo "  \"since\": \"$(json_escape "${SINCE:-(beginning)}")\","
    echo "  \"until\": \"$(json_escape "${UNTIL:-(now)}")\","
    echo "  \"total_commits\": $total_commits,"
    echo "  \"analyzed_commits\": $commit_count,"

    # Unique emails
    echo "  \"unique_emails\": ["
    first=1
    while read -r email; do
        [[ -z "$email" ]] && continue
        [[ $first -eq 0 ]] && echo ","
        echo -n "    \"$(json_escape "$email")\""
        first=0
    done < "$email_list_tmp"
    echo ""
    echo "  ],"

    # Date range
    first_date=$(sort "$date_list_tmp" | head -1)
    last_date=$(sort "$date_list_tmp" | tail -1)
    echo "  \"date_range\": {"
    echo "    \"first_commit\": \"$first_date\","
    echo "    \"last_commit\": \"$last_date\""
    echo "  },"

    # Statistics
    echo "  \"statistics\": {"
    echo "    \"total_additions\": $total_additions,"
    echo "    \"total_deletions\": $total_deletions,"
    echo "    \"total_changes\": $((total_additions + total_deletions))"
    echo "  },"

    other_count=$((commit_count - feat_count - fix_count - docs_count - test_count - refactor_count - chore_count))
    [[ $other_count -lt 0 ]] && other_count=0

    # Commit patterns
    echo "  \"commit_patterns\": {"
    echo "    \"feat\": $feat_count,"
    echo "    \"fix\": $fix_count,"
    echo "    \"docs\": $docs_count,"
    echo "    \"test\": $test_count,"
    echo "    \"refactor\": $refactor_count,"
    echo "    \"chore\": $chore_count,"
    echo "    \"other\": $other_count"
    echo "  },"

    # Top files
    echo "  \"top_files\": ["
    first=1
    while IFS='|' read -r file count adds dels; do
        [[ -z "$file" ]] && continue
        [[ $first -eq 0 ]] && echo ","
        echo -n "    {\"file\": \"$(json_escape "$file")\", \"changes\": $count, \"additions\": ${adds:-0}, \"deletions\": ${dels:-0}}"
        first=0
    done < <(head -20 "$files_sorted")
    echo ""
    echo "  ],"

    # Top directories
    echo "  \"top_directories\": ["
    first=1
    while IFS='|' read -r dir count; do
        [[ -z "$dir" ]] && continue
        [[ $first -eq 0 ]] && echo ","
        echo -n "    {\"directory\": \"$(json_escape "$dir")\", \"changes\": $count}"
        first=0
    done < <(head -10 "$dirs_sorted")
    echo ""
    echo "  ],"

    # File types
    echo "  \"file_types\": ["
    first=1
    while IFS='|' read -r ext count; do
        [[ -z "$ext" ]] && continue
        [[ $first -eq 0 ]] && echo ","
        echo -n "    {\"extension\": \"$(json_escape "$ext")\", \"count\": $count}"
        first=0
    done < "$exts_sorted"
    echo ""
    echo "  ]"
    echo "}"
} > "$OUT_DIR/summary.json"

# Generate file_stats.csv
echo "Generating file_stats.csv..."
echo "file,changes,additions,deletions" > "$OUT_DIR/file_stats.csv"
while IFS='|' read -r file count adds dels; do
    [[ -z "$file" ]] && continue
    echo "\"$file\",$count,${adds:-0},${dels:-0}"
done < "$files_sorted" >> "$OUT_DIR/file_stats.csv"

# Generate summary.md
echo "Generating summary.md..."
{
    echo "# Code Alchemist Analysis Report"
    echo ""
    echo "## Overview"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Repository | \`$REPO\` |"
    echo "| Author | $AUTHOR_DISPLAY |"
    echo "| Time Range | ${SINCE:-beginning} → ${UNTIL:-now} |"
    echo "| Total Commits | $total_commits |"
    echo "| Lines Added | +$total_additions |"
    echo "| Lines Deleted | -$total_deletions |"
    echo ""
    echo "## Commit Message Patterns"
    echo ""
    echo "| Type | Count |"
    echo "|------|-------|"
    echo "| feat | $feat_count |"
    echo "| fix | $fix_count |"
    echo "| docs | $docs_count |"
    echo "| test | $test_count |"
    echo "| refactor | $refactor_count |"
    echo "| chore | $chore_count |"
    echo "| other | $other_count |"
    echo ""
    echo "## Most Modified Files"
    echo ""
    echo "| File | Changes | +/- |"
    echo "|------|---------|-----|"
    while IFS='|' read -r file count adds dels; do
        [[ -z "$file" ]] && continue
        echo "| \`$file\` | $count | +$adds/-$dels |"
    done < <(head -15 "$files_sorted")
    echo ""
    echo "## Top Directories"
    echo ""
    echo "| Directory | Changes |"
    echo "|-----------|---------|"
    while IFS='|' read -r dir count; do
        [[ -z "$dir" ]] && continue
        echo "| \`$dir\` | $count |"
    done < <(head -10 "$dirs_sorted")
    echo ""
    echo "## File Types"
    echo ""
    echo "| Extension | Count |"
    echo "|-----------|-------|"
    while IFS='|' read -r ext count; do
        [[ -z "$ext" ]] && continue
        echo "| \`$ext\` | $count |"
    done < "$exts_sorted"
    echo ""
    echo "## Representative Commits"
    echo ""
    echo "*Selected based on code changes, file diversity, and time distribution*"
    echo ""
    samples_tmp="$OUT_DIR/.samples_md.tmp"
    head -10 "$commits_selected" > "$samples_tmp"
    while IFS='|' read -r hash name email date subject || [[ -n "$hash" ]]; do
        [[ -z "$hash" ]] && continue
        # Convert epoch to readable date
        readable_date=$(date -r "$date" "+%Y-%m-%d" 2>/dev/null || date -d "@$date" "+%Y-%m-%d" 2>/dev/null || echo "$date")
        echo "- \`${hash:0:8}\` $readable_date: $subject"
    done < "$samples_tmp"
    rm -f "$samples_tmp"
    echo ""
    echo "---"
    echo "*Generated by Code Alchemist*"
} > "$OUT_DIR/summary.md"

# Extract example commits
echo "Extracting example commits..."
samples_tmp="$OUT_DIR/.samples_json.tmp"
cp "$commits_selected" "$samples_tmp"
{
    echo "["
    first=1
    while IFS='|' read -r hash name email date subject || [[ -n "$hash" ]]; do
        [[ -z "$hash" ]] && continue

        diff_file="$OUT_DIR/examples/${hash:0:8}.diff"
        # Save both stat and patch, applying pathspec if present
        if [[ ${#pathspec_args[@]} -gt 0 ]]; then
            git show --stat --patch --format=fuller "$hash" -- "${pathspec_args[@]}" 2>/dev/null > "$diff_file" || true
        else
            git show --stat --patch --format=fuller "$hash" 2>/dev/null > "$diff_file" || true
        fi

        [[ $first -eq 0 ]] && echo ","
        echo -n "  {"
        echo -n "\"hash\": \"${hash:0:8}\", "
        echo -n "\"author\": \"$(json_escape "$name")\", "
        echo -n "\"email\": \"$(json_escape "$email")\", "
        echo -n "\"date\": \"$date\", "
        echo -n "\"subject\": \"$(json_escape "$subject")\""
        echo -n "}"
        first=0
    done < "$samples_tmp"
    echo ""
    echo "]"
} > "$OUT_DIR/example_commits.json"
rm -f "$samples_tmp"

# Generate live_files.txt with code file prioritization
echo "Generating live_files.txt..."

# Define code file extensions (prioritized for style analysis)
code_extensions='\.(js|jsx|ts|tsx|py|rs|go|java|rb|php|swift|kt|scala|cs|cpp|c|h|hpp|sh|bash|zsh)$'

# Define doc/config file basename patterns (match filename only, not full path)
doc_basenames='^(README|LICENSE|CHANGELOG|CONTRIBUTING|AUTHORS|NOTICE|\.env|\.gitignore|\.gitattributes|\.dockerignore|Makefile|CMakeLists\.txt|Dockerfile)$'

# Define doc/config file extensions
doc_extensions='\.(md|txt|yaml|yml|json|toml|ini|cfg|conf)$'

# Define config file basename patterns (package.json, etc.)
config_basenames='^(package\.json|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.toml|Cargo\.lock|go\.mod|go\.sum|setup\.py|pyproject\.toml|requirements\.txt|Gemfile|Gemfile\.lock|composer\.json|composer\.lock|pom\.xml|build\.gradle|gradlew|gradlew\.bat|mvnw|mvnw\.cmd|tsconfig\.json|jsconfig\.json|eslint.*|prettier.*|babel.*|webpack.*|vite.*|rollup.*|turbo\.json|next\.config.*|vercel\.json|netlify\.toml|docker-compose.*|Dockerfile.*)$'

code_files_tmp="$OUT_DIR/.code_files.tmp"
doc_files_tmp="$OUT_DIR/.doc_files.tmp"
>"$code_files_tmp"
>"$doc_files_tmp"

is_doc_file() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Check if basename matches doc patterns
    if echo "$basename" | grep -qE "$doc_basenames"; then
        return 0
    fi

    # Check if basename matches config patterns
    if echo "$basename" | grep -qE "$config_basenames"; then
        return 0
    fi

    # Check if file has doc extension
    if echo "$basename" | grep -qE "$doc_extensions"; then
        return 0
    fi

    return 1
}

while IFS='|' read -r file count adds dels; do
    [[ -z "$file" ]] && continue
    if git cat-file -e "HEAD:$file" 2>/dev/null; then
        # Check if it's a code file by extension
        if echo "$file" | grep -qE "$code_extensions"; then
            echo "$file" >> "$code_files_tmp"
        elif is_doc_file "$file"; then
            # It's a doc/config file
            echo "$file" >> "$doc_files_tmp"
        else
            # Unknown type - treat as code for safety
            echo "$file" >> "$code_files_tmp"
        fi
    fi
done < "$files_sorted"

# Combine: code files first, then doc files
cat "$code_files_tmp" "$doc_files_tmp" > "$OUT_DIR/live_files.txt"

code_count=$(wc -l < "$code_files_tmp" | tr -d ' ')
doc_count=$(wc -l < "$doc_files_tmp" | tr -d ' ')
log_info "Found $code_count code files, $doc_count doc/config files"

rm -f "$code_files_tmp" "$doc_files_tmp"

# Cleanup temp files
rm -f "$commits_file" "$files_sorted" "$dirs_sorted" "$exts_sorted"
rm -f "$commits_scored" "$commits_selected"
rm -f "$file_stats_tmp" "$email_list_tmp" "$date_list_tmp" "$dir_stats_tmp" "$ext_stats_tmp"
rm -f "$OUT_DIR/"*.new 2>/dev/null || true

log_info "Analysis complete!"
log_info "Output files:"
echo "  - $OUT_DIR/summary.json"
echo "  - $OUT_DIR/summary.md"
echo "  - $OUT_DIR/file_stats.csv"
echo "  - $OUT_DIR/example_commits.json"
echo "  - $OUT_DIR/examples/*.diff"
echo "  - $OUT_DIR/live_files.txt"
