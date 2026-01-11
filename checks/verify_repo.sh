#!/usr/bin/env bash
# verify_repo.sh - Repository Verification Script
# Purpose: Verify SSOT integrity, link validity, and forbidden commands
# Required: bash 4+

set -e

# Parse arguments
MODE="${1:-Fast}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_PATH="${REPO_ROOT}/docs"
SOURCES_PATH="${REPO_ROOT}/sources"
EVIDENCE_PATH="${REPO_ROOT}/evidence/verify_reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ALL_PASSED=true

# Ensure evidence directory exists
mkdir -p "${EVIDENCE_PATH}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log_info() {
    echo -e "[INFO] $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ALL_PASSED=false
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# V-0001: Link integrity check
test_links() {
    log_info "Running V-0001: Link integrity check"

    local report_path="${EVIDENCE_PATH}/${TIMESTAMP}_link_check.md"
    local broken_count=0
    local broken_links=""

    # Find all markdown files in docs/
    while IFS= read -r -d '' file; do
        # Extract markdown links: [text](path)
        while IFS= read -r line; do
            # Match [text](path) pattern
            echo "$line" | grep -oP '\[([^\]]+)\]\(([^\)]+)\)' | while read -r match; do
                link_path=$(echo "$match" | sed -E 's/.*\(([^\)]+)\).*/\1/')

                # Skip external links and anchors
                if [[ "$link_path" =~ ^https?:// ]] || [[ "$link_path" =~ ^# ]]; then
                    continue
                fi

                # Remove anchor from path
                clean_path="${link_path%%#*}"

                # Resolve relative path
                base_path=$(dirname "$file")
                target_path="${base_path}/${clean_path}"

                if [[ ! -e "$target_path" ]]; then
                    broken_count=$((broken_count + 1))
                    rel_file="${file#$REPO_ROOT/}"
                    broken_links="${broken_links}### ${rel_file}\n- Link path: \`${link_path}\`\n- Resolved: \`${target_path#$REPO_ROOT/}\`\n\n"
                fi
            done
        done < "$file"
    done < <(find "${DOCS_PATH}" -name '*.md' -print0)

    # Generate report
    local status="PASS"
    if [[ $broken_count -gt 0 ]]; then
        status="FAIL"
    fi

    cat > "$report_path" <<EOF
# V-0001: Link Integrity Check Report

**Timestamp**: ${TIMESTAMP}
**Mode**: ${MODE}
**Status**: ${status}

## Summary
- Total broken links: ${broken_count}

## Broken Links
$(if [[ $broken_count -eq 0 ]]; then
    echo "No broken links found."
else
    echo -e "$broken_links"
fi)

## Execution
- Command: \`bash checks/verify_repo.sh ${MODE}\`
- Date: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    if [[ $broken_count -gt 0 ]]; then
        log_fail "Found ${broken_count} broken links"
        return 1
    else
        log_pass "No broken links found"
        return 0
    fi
}

# V-0002: Part existence check
test_parts_exist() {
    log_info "Running V-0002: Part existence check"

    local report_path="${EVIDENCE_PATH}/${TIMESTAMP}_parts_check.md"
    local missing_count=0
    local missing_parts=""

    for i in $(seq -f "%02g" 0 20); do
        part_file="${DOCS_PATH}/Part${i}.md"
        if [[ ! -f "$part_file" ]]; then
            missing_count=$((missing_count + 1))
            missing_parts="${missing_parts}- Part${i}.md\n"
        fi
    done

    # Generate report
    local status="PASS"
    if [[ $missing_count -gt 0 ]]; then
        status="FAIL"
    fi

    cat > "$report_path" <<EOF
# V-0002: Part Existence Check Report

**Timestamp**: ${TIMESTAMP}
**Mode**: ${MODE}
**Status**: ${status}

## Summary
- Expected parts: 21 (Part00 - Part20)
- Missing parts: ${missing_count}

## Missing Parts
$(if [[ $missing_count -eq 0 ]]; then
    echo "All parts exist."
else
    echo -e "$missing_parts"
fi)

## Execution
- Command: \`bash checks/verify_repo.sh ${MODE}\`
- Date: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    if [[ $missing_count -gt 0 ]]; then
        log_fail "Missing ${missing_count} parts"
        return 1
    else
        log_pass "All parts exist"
        return 0
    fi
}

# V-0003 & V-0901: Forbidden commands check
test_forbidden_commands() {
    log_info "Running V-0003/V-0901: Forbidden commands check"

    local report_path="${EVIDENCE_PATH}/${TIMESTAMP}_forbidden_check.md"
    local detection_count=0
    local detections=""

    # Define forbidden patterns
    local patterns=(
        "rm\s+-rf"
        "rmdir\s+/s\s+/q"
        "del\s+/s\s+/q"
        "git\s+push\s+--force"
        "git\s+push\s+-f\b"
        "git\s+reset\s+--hard"
        "git\s+clean\s+-fdx"
        "curl.*\|\s*sh"
        "wget.*\|\s*sh"
        "eval\s*\$\("
        "bash\s*<\("
        "chmod\s+777"
        "sudo\s+"
        "pip\s+install\s+-g"
        "npm\s+install\s+-g"
        "apt\s+install"
    )

    # Check docs/ and checks/ using grep for performance
    # Note: Exclude content within backticks (code examples) as these are documentation
    local combined_pattern=$(IFS='|'; echo "${patterns[*]}")

    for dir in "${DOCS_PATH}" "${REPO_ROOT}/checks"; do
        if [[ -d "$dir" ]]; then
            # Use grep -r for better performance, exclude large files
            while IFS=: read -r file line_num content; do
                # Skip if forbidden command is within backticks (documentation examples)
                if echo "$content" | grep -qE '`[^`]*('$combined_pattern')[^`]*`'; then
                    continue
                fi

                detection_count=$((detection_count + 1))
                rel_file="${file#$REPO_ROOT/}"
                # Escape backticks in content
                safe_content=$(echo "$content" | sed 's/`/\\`/g')
                detections="${detections}### ${rel_file}:${line_num}\n- Content: \`${safe_content}\`\n\n"
            done < <(grep -nrE "$combined_pattern" "$dir" --include='*.md' --include='*.sh' 2>/dev/null | head -100 || true)
        fi
    done

    # Generate report
    local status="PASS"
    if [[ $detection_count -gt 0 ]]; then
        status="FAIL"
    fi

    cat > "$report_path" <<EOF
# V-0003/V-0901: Forbidden Commands Check Report

**Timestamp**: ${TIMESTAMP}
**Mode**: ${MODE}
**Status**: ${status}

## Summary
- Forbidden commands detected: ${detection_count}

## Detections
$(if [[ $detection_count -eq 0 ]]; then
    echo "No forbidden commands found."
else
    echo -e "$detections"
fi)

## Forbidden Patterns Checked
$(for pattern in "${patterns[@]}"; do
    echo "- \`${pattern}\`"
done)

## Execution
- Command: \`bash checks/verify_repo.sh ${MODE}\`
- Date: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    if [[ $detection_count -gt 0 ]]; then
        log_fail "Found ${detection_count} forbidden commands"
        return 1
    else
        log_pass "No forbidden commands found"
        return 0
    fi
}

# V-0004 & V-0902: Sources integrity check
test_sources_integrity() {
    log_info "Running V-0004/V-0902: Sources integrity check"

    local report_path="${EVIDENCE_PATH}/${TIMESTAMP}_sources_integrity.md"
    local modification_count=0
    local modifications=""

    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_warn "Git not available, skipping sources integrity check"
        return 0
    fi

    # Check for modifications in sources/
    if git rev-parse HEAD~1 &> /dev/null; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^M[[:space:]]+sources/ ]]; then
                modification_count=$((modification_count + 1))
                modified_file=$(echo "$line" | awk '{print $2}')
                modifications="${modifications}- ${modified_file}\n"
            fi
        done < <(git diff --name-status HEAD~1 HEAD -- sources/ 2>/dev/null || true)
    fi

    # Generate report
    local status="PASS"
    if [[ $modification_count -gt 0 ]]; then
        status="FAIL"
    fi

    cat > "$report_path" <<EOF
# V-0004/V-0902: Sources Integrity Check Report

**Timestamp**: ${TIMESTAMP}
**Mode**: ${MODE}
**Status**: ${status}

## Summary
- Modified files in sources/: ${modification_count}

## Modified Files
$(if [[ $modification_count -eq 0 ]]; then
    echo "No modifications in sources/ (additions are OK)."
else
    echo -e "$modifications"
fi)

## Rule
- sources/ files must not be modified (append-only)
- See: Part00 R-0003, Part09 R-0903

## Execution
- Command: \`bash checks/verify_repo.sh ${MODE}\`
- Date: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    if [[ $modification_count -gt 0 ]]; then
        log_fail "Found ${modification_count} modified files in sources/"
        return 1
    else
        log_pass "No modifications in sources/"
        return 0
    fi
}

# Main execution
log_info "=== Repository Verification Started ==="
log_info "Mode: ${MODE}"
log_info "Repository: ${REPO_ROOT}"
echo ""

# Run checks
test_links || true
echo ""

test_parts_exist || true
echo ""

test_forbidden_commands || true
echo ""

test_sources_integrity || true
echo ""

# Summary
log_info "=== Verification Complete ==="
log_info "Evidence saved to: ${EVIDENCE_PATH}"

if [[ "$ALL_PASSED" == "true" ]]; then
    log_pass "Overall Status: PASS"
    exit 0
else
    log_fail "Overall Status: FAIL"
    log_fail "Please fix the issues above and re-run verification"
    exit 1
fi
