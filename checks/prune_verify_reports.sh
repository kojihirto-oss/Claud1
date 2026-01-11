#!/usr/bin/env bash
# prune_verify_reports.sh
# Purpose: Keep only the most recent 3 timestamp sets in evidence/verify_reports/
# Policy: ADR-0003 (Evidence retention policy - recent-3 sets)

set -euo pipefail

EVIDENCE_DIR="evidence/verify_reports"
KEEP_COUNT=3

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 [--dry-run]

Keep only the most recent ${KEEP_COUNT} timestamp sets in ${EVIDENCE_DIR}/

Options:
  --dry-run    Show what would be deleted without actually deleting

Example:
  $0 --dry-run  # Preview deletion
  $0            # Execute deletion (with confirmation prompt)

Policy: decisions/0003-evidence-retention-policy.md
EOF
    exit 0
}

# Parse arguments
DRY_RUN=false
if [[ $# -gt 0 ]]; then
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
            usage
            ;;
    esac
fi

# Check if evidence directory exists
if [[ ! -d "$EVIDENCE_DIR" ]]; then
    echo -e "${YELLOW}Warning: Directory ${EVIDENCE_DIR}/ does not exist. Nothing to prune.${NC}"
    exit 0
fi

# Extract unique timestamps from filenames (format: YYYYMMDD_HHMMSS_*.md)
# Expected pattern: YYYYMMDD_HHMMSS_<check_name>.md
cd "$EVIDENCE_DIR" || exit 1

TIMESTAMPS=$(find . -maxdepth 1 -type f -name "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]_*.md" \
    | sed -E 's|^\./([0-9]{8}_[0-9]{6})_.*\.md$|\1|' \
    | sort -u -r)

if [[ -z "$TIMESTAMPS" ]]; then
    echo -e "${YELLOW}No verify reports found in ${EVIDENCE_DIR}/.${NC}"
    exit 0
fi

TOTAL_SETS=$(echo "$TIMESTAMPS" | wc -l)
echo -e "${GREEN}Found ${TOTAL_SETS} timestamp set(s):${NC}"
echo "$TIMESTAMPS" | nl

if [[ $TOTAL_SETS -le $KEEP_COUNT ]]; then
    echo -e "${GREEN}Total sets (${TOTAL_SETS}) <= ${KEEP_COUNT}. Nothing to prune.${NC}"
    exit 0
fi

# Identify timestamps to delete (all except the most recent KEEP_COUNT)
TIMESTAMPS_TO_DELETE=$(echo "$TIMESTAMPS" | tail -n +$((KEEP_COUNT + 1)))
DELETE_COUNT=$(echo "$TIMESTAMPS_TO_DELETE" | wc -l)

echo -e "\n${YELLOW}Will keep the most recent ${KEEP_COUNT} set(s) and delete ${DELETE_COUNT} older set(s):${NC}"
echo "$TIMESTAMPS_TO_DELETE" | nl

# Collect files to delete
FILES_TO_DELETE=()
while IFS= read -r ts; do
    # Find all files matching this timestamp
    while IFS= read -r file; do
        FILES_TO_DELETE+=("$file")
    done < <(find . -maxdepth 1 -type f -name "${ts}_*.md")
done <<< "$TIMESTAMPS_TO_DELETE"

if [[ ${#FILES_TO_DELETE[@]} -eq 0 ]]; then
    echo -e "${GREEN}No files to delete.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Files to be deleted (${#FILES_TO_DELETE[@]} total):${NC}"
printf '%s\n' "${FILES_TO_DELETE[@]}" | sed 's|^\./||'

if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n${GREEN}[DRY RUN] No files were deleted.${NC}"
    exit 0
fi

# Confirmation prompt
echo -e "\n${RED}WARNING: This will permanently delete ${#FILES_TO_DELETE[@]} file(s) using 'git rm -f'.${NC}"
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Aborted by user.${NC}"
    exit 0
fi

# Execute deletion
cd - > /dev/null  # Return to repo root
for file in "${FILES_TO_DELETE[@]}"; do
    file_path="${EVIDENCE_DIR}/${file#./}"
    if [[ -f "$file_path" ]]; then
        git rm -f "$file_path"
        echo -e "${GREEN}Deleted: ${file_path}${NC}"
    fi
done

echo -e "\n${GREEN}Successfully deleted ${#FILES_TO_DELETE[@]} file(s) from ${DELETE_COUNT} old set(s).${NC}"
echo -e "${GREEN}Kept the most recent ${KEEP_COUNT} set(s).${NC}"
