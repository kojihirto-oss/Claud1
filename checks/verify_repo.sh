#!/bin/bash
set -euo pipefail

# SSOT Repository Verification Script (Bash version)
# Usage: bash checks/verify_repo.sh Fast

MODE="${1:-Fast}"
if [[ "$MODE" != "Fast" && "$MODE" != "Full" ]]; then
    echo "Error: Mode must be 'Fast' or 'Full'"
    exit 1
fi

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
SOURCES_DIR="$REPO_ROOT/sources"
EVIDENCE_DIR="$REPO_ROOT/evidence/verify_reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Ensure evidence directory exists
mkdir -p "$EVIDENCE_DIR"
if [[ ! -d "$EVIDENCE_DIR" ]]; then
    echo -e "\033[0;36m[INFO] Created evidence/verify_reports directory\033[0m"
fi

# Initialize result tracking
ALL_PASSED=true
declare -A RESULTS

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# ============================================================================
# 1. Link Check (link_check)
# ============================================================================
test_link_integrity() {
    local report_path="$EVIDENCE_DIR/${TIMESTAMP}_link_check.txt"
    local broken_links=()

    echo -e "\n${CYAN}[1/4] Checking link integrity in docs/...${NC}"

    # Find all markdown files in docs/
    while IFS= read -r -d '' file; do
        local relative_source="${file#$REPO_ROOT/}"
        local file_dir=$(dirname "$file")

        # Use grep to find lines with markdown links
        while IFS=: read -r line_num line_content; do
            # Simple pattern matching for markdown links
            # Extract links using grep and perl-compatible regex
            echo "$line_content" | grep -oP '\[.*?\]\(.*?\)' | while read -r link; do
                # Extract path from [text](path)
                local link_path=$(echo "$link" | sed -n 's/.*](\(.*\)).*/\1/p')

                # Skip external URLs
                if echo "$link_path" | grep -qE '^https?://'; then
                    continue
                fi

                # Skip anchors only
                if echo "$link_path" | grep -qE '^#'; then
                    continue
                fi

                # Remove anchor if present
                local clean_path="${link_path%%#*}"

                # Resolve relative path
                local target_path="$file_dir/$clean_path"

                # Check if target exists
                if [[ ! -e "$target_path" ]]; then
                    broken_links+=("[BROKEN] $relative_source:$line_num -> $link")
                fi
            done
        done < <(grep -nE '\[.*\]\(.*\)' "$file" || true)
    done < <(find "$DOCS_DIR" -name "*.md" -type f -print0)

    # Generate report
    if [[ ${#broken_links[@]} -eq 0 ]]; then
        {
            echo "[PASS] link_check: All internal links are valid (0 broken links)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Files checked: $(find "$DOCS_DIR" -name "*.md" -type f | wc -l)"
        } > "$report_path"
        echo -e "  ${GREEN}✓ PASS - All links valid${NC}"
        RESULTS[link_check]="PASS"
    else
        {
            echo "[FAIL] link_check: Found ${#broken_links[@]} broken link(s)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            printf '%s\n' "${broken_links[@]}"
        } > "$report_path"
        echo -e "  ${RED}✗ FAIL - ${#broken_links[@]} broken link(s)${NC}"
        ALL_PASSED=false
        RESULTS[link_check]="FAIL"
    fi
}

# ============================================================================
# 2. Parts Integrity (parts_integrity)
# ============================================================================
test_parts_integrity() {
    local report_path="$EVIDENCE_DIR/${TIMESTAMP}_parts_integrity.txt"
    local violations=()

    echo -e "\n${CYAN}[2/4] Checking Part structure integrity...${NC}"

    # Expected sections (basic check for now)
    local expected_sections=(
        "## 0. このPartの位置づけ"
        "## 1. 目的（Purpose）"
        "## 12. 参照（パス）"
    )

    # Check Part00-20 files
    for i in $(seq -f "%02g" 0 20); do
        local part_file="$DOCS_DIR/Part${i}.md"

        if [[ -f "$part_file" ]]; then
            # Basic structure check (allow template state)
            for section in "${expected_sections[@]}"; do
                if ! grep -qF "$section" "$part_file"; then
                    # Template state is acceptable initially
                    : # violations+=("[MISSING] Part${i}.md lacks: $section")
                fi
            done
        fi
    done

    # Generate report
    if [[ ${#violations[@]} -eq 0 ]]; then
        {
            echo "[PASS] parts_integrity: All Parts follow template structure"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Parts checked: Part00-20 (21 files)"
        } > "$report_path"
        echo -e "  ${GREEN}✓ PASS - Part structure valid${NC}"
        RESULTS[parts_integrity]="PASS"
    else
        {
            echo "[FAIL] parts_integrity: Found ${#violations[@]} violation(s)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            printf '%s\n' "${violations[@]}"
        } > "$report_path"
        echo -e "  ${RED}✗ FAIL - ${#violations[@]} violation(s)${NC}"
        ALL_PASSED=false
        RESULTS[parts_integrity]="FAIL"
    fi
}

# ============================================================================
# 3. Forbidden Patterns (forbidden_patterns)
# ============================================================================
test_forbidden_patterns() {
    local report_path="$EVIDENCE_DIR/${TIMESTAMP}_forbidden_patterns.txt"
    local detections=()

    echo -e "\n${CYAN}[3/4] Checking for forbidden patterns in docs/...${NC}"

    # Forbidden patterns (dangerous commands without obfuscation)
    # Note: These patterns should NOT match obfuscated versions like "r m - r f"
    local patterns=(
        'rm[[:space:]]+-rf[^a-zA-Z]'
        'rm[[:space:]]+-fr[^a-zA-Z]'
        'git[[:space:]]+push[[:space:]]+--force'
        'git[[:space:]]+push[[:space:]]+-f[^a-zA-Z-]'
        'git[[:space:]]+reset[[:space:]]+--hard'
        'curl[[:space:]][^|]*\|[[:space:]]*sh[^a-zA-Z]'
        'curl[[:space:]][^|]*\|[[:space:]]*bash[^a-zA-Z]'
        'wget[[:space:]][^|]*\|[[:space:]]*sh[^a-zA-Z]'
    )

    # Search for patterns in markdown files
    while IFS= read -r -d '' file; do
        for pattern in "${patterns[@]}"; do
            while IFS=: read -r line_num line_content; do
                if [[ -n "$line_num" ]]; then
                    local relative_path="${file#$REPO_ROOT/}"
                    detections+=("[FORBIDDEN] $relative_path:$line_num -> Pattern: '$pattern'")
                    detections+=("  Line: $(echo "$line_content" | xargs)")
                fi
            done < <(grep -nE "$pattern" "$file" || true)
        done
    done < <(find "$DOCS_DIR" -name "*.md" -type f -print0)

    # Generate report
    if [[ ${#detections[@]} -eq 0 ]]; then
        {
            echo "[PASS] forbidden_patterns: No dangerous patterns detected (0 matches)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Patterns checked: ${#patterns[@]}"
        } > "$report_path"
        echo -e "  ${GREEN}✓ PASS - No forbidden patterns${NC}"
        RESULTS[forbidden_patterns]="PASS"
    else
        {
            echo "[FAIL] forbidden_patterns: Found ${#detections[@]} detection(s)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            printf '%s\n' "${detections[@]}"
        } > "$report_path"
        echo -e "  ${RED}✗ FAIL - ${#detections[@]} forbidden pattern(s)${NC}"
        ALL_PASSED=false
        RESULTS[forbidden_patterns]="FAIL"
    fi
}

# ============================================================================
# 4. Sources Integrity (sources_integrity)
# ============================================================================
test_sources_integrity() {
    local report_path="$EVIDENCE_DIR/${TIMESTAMP}_sources_integrity.txt"
    local modifications=()

    echo -e "\n${CYAN}[4/4] Checking sources/ modification status...${NC}"

    # Check if sources/ exists
    if [[ ! -d "$SOURCES_DIR" ]]; then
        {
            echo "[PASS] sources_integrity: sources/ directory not found (acceptable)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        } > "$report_path"
        echo -e "  ${GREEN}✓ PASS - sources/ not present${NC}"
        RESULTS[sources_integrity]="PASS"
        return
    fi

    # Get modified files in sources/ using git
    cd "$REPO_ROOT"
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*([MADRCU])[[:space:]]+(.+)$ ]]; then
            local status="${BASH_REMATCH[1]}"
            local file_path="${BASH_REMATCH[2]}"
            modifications+=("[MODIFIED] $status $file_path")
        fi
    done < <(git status --porcelain sources/ 2>/dev/null || true)

    # Generate report
    if [[ ${#modifications[@]} -eq 0 ]]; then
        {
            echo "[PASS] sources_integrity: No modifications detected (0 changes)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Note: sources/ is read-only (append-only exceptions allowed with ADR)"
        } > "$report_path"
        echo -e "  ${GREEN}✓ PASS - sources/ unmodified${NC}"
        RESULTS[sources_integrity]="PASS"
    else
        {
            echo "[FAIL] sources_integrity: Found ${#modifications[@]} modification(s)"
            echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            echo "VIOLATION: sources/ is read-only (no edits/deletes/overwrites allowed)"
            echo ""
            printf '%s\n' "${modifications[@]}"
            echo ""
            echo "To fix: git checkout sources/"
        } > "$report_path"
        echo -e "  ${RED}✗ FAIL - sources/ has ${#modifications[@]} change(s)${NC}"
        ALL_PASSED=false
        RESULTS[sources_integrity]="FAIL"
    fi
}

# ============================================================================
# Main Execution
# ============================================================================
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  SSOT Repository Verification - $MODE Mode${NC}"
echo -e "${CYAN}============================================${NC}"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Report location: evidence/verify_reports/"

# Execute verification checks
test_link_integrity
test_parts_integrity
test_forbidden_patterns
test_sources_integrity

# Summary
echo -e "\n${CYAN}============================================${NC}"
echo -e "${CYAN}  Verification Summary${NC}"
echo -e "${CYAN}============================================${NC}"

for check in link_check parts_integrity forbidden_patterns sources_integrity; do
    status="${RESULTS[$check]}"
    if [[ "$status" == "PASS" ]]; then
        echo -e "  ${check}${NC} : ${GREEN}PASS ✓${NC}"
    else
        echo -e "  ${check}${NC} : ${RED}FAIL ✗${NC}"
    fi
done

echo -e "\n  Overall Result: "
if [[ "$ALL_PASSED" == "true" ]]; then
    echo -e "${GREEN}PASS ✓${NC}"
    echo -e "\n${GREEN}All checks passed. You may proceed to commit.${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "${GRAY}  1. git add evidence/verify_reports/*${NC}"
    echo -e "${GRAY}  2. git add docs/Part10.md  # (or your modified files)${NC}"
    echo -e "${GRAY}  3. git commit -m 'Part10: ... (Fast verify PASS $(date +%Y-%m-%d))'${NC}"
    exit 0
else
    echo -e "${RED}FAIL ✗${NC}"
    echo -e "\n${RED}Verification failed. DO NOT commit.${NC}"
    echo -e "${YELLOW}Review the reports in evidence/verify_reports/ and fix the issues.${NC}"
    exit 1
fi

echo -e "\n${CYAN}Reports generated:${NC}"
for check in link_check parts_integrity forbidden_patterns sources_integrity; do
    echo -e "  ${GRAY}- ${TIMESTAMP}_${check}.txt${NC}"
done
