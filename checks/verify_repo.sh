#!/bin/bash
#
# SSOT検証スクリプト（Fast/Full Verify）
#
# 使用法:
#   bash checks/verify_repo.sh [fast|full]
#

set -euo pipefail

MODE="${1:-fast}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$REPO_ROOT/evidence/verify_reports"
REPORT_FILE="$REPORT_DIR/verify_${TIMESTAMP}_${MODE}.log"

# 証跡ディレクトリ作成
mkdir -p "$REPORT_DIR"

# ログ関数
log() {
    local level="${2:-INFO}"
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $1"
    echo "$message" | tee -a "$REPORT_FILE"
}

test_result() {
    local test_name="$1"
    local passed="$2"
    local details="${3:-}"

    if [ "$passed" = "true" ]; then
        log "✓ PASS: $test_name" "PASS"
        [ -n "$details" ] && log "  → $details" "INFO"
        return 0
    else
        log "✗ FAIL: $test_name" "FAIL"
        [ -n "$details" ] && log "  → $details" "ERROR"
        return 1
    fi
}

# ヘッダー
log "========================================" "INFO"
log "SSOT Verify - Mode: $MODE" "INFO"
log "Repo: $REPO_ROOT" "INFO"
log "========================================" "INFO"

PASS_COUNT=0
TOTAL_TESTS=0

# ========================================
# Fast Verify（基本チェック）
# ========================================

log "" "INFO"
log "[Fast Verify] 開始" "INFO"

# 1. 必須フォルダ存在確認
log "" "INFO"
log "--- 1. 必須フォルダ確認 ---" "INFO"
for dir in docs decisions sources glossary checks evidence; do
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ -d "$REPO_ROOT/$dir" ]; then
        test_result "必須フォルダ: $dir/" "true" && PASS_COUNT=$((PASS_COUNT + 1))
    else
        test_result "必須フォルダ: $dir/" "false" || true
    fi
done

# 2. 必須ファイル存在確認
log "" "INFO"
log "--- 2. 必須ファイル確認 ---" "INFO"
REQUIRED_FILES=(
    "docs/00_INDEX.md"
    "docs/Part00.md"
    "docs/Part02.md"
    "docs/FACTS_LEDGER.md"
    "decisions/ADR_TEMPLATE.md"
    "glossary/GLOSSARY.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ -f "$REPO_ROOT/$file" ]; then
        test_result "必須ファイル: $file" "true" && PASS_COUNT=$((PASS_COUNT + 1))
    else
        test_result "必須ファイル: $file" "false" || true
    fi
done

# 3. ADRファイル確認
log "" "INFO"
log "--- 3. ADRファイル確認 ---" "INFO"
ADR_COUNT=$(find "$REPO_ROOT/decisions" -name '[0-9][0-9][0-9][0-9]-*.md' -type f 2>/dev/null | wc -l)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if [ "$ADR_COUNT" -ge 1 ]; then
    test_result "ADRファイル存在" "true" "検出: ${ADR_COUNT}件" && PASS_COUNT=$((PASS_COUNT + 1))
else
    test_result "ADRファイル存在" "false" "検出: ${ADR_COUNT}件" || true
fi

# 4. Partファイル確認（Part00〜Part20）
log "" "INFO"
log "--- 4. Partファイル確認 ---" "INFO"
MISSING_PARTS=""
for i in $(seq -w 0 20); do
    if [ ! -f "$REPO_ROOT/docs/Part${i}.md" ]; then
        MISSING_PARTS="${MISSING_PARTS} Part${i}.md"
    fi
done

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if [ -z "$MISSING_PARTS" ]; then
    test_result "全Partファイル存在（Part00〜Part20）" "true" "全21ファイル確認" && PASS_COUNT=$((PASS_COUNT + 1))
else
    test_result "全Partファイル存在（Part00〜Part20）" "false" "欠落:$MISSING_PARTS" || true
fi

# 5. .gitignore 確認
log "" "INFO"
log "--- 5. .gitignore 確認 ---" "INFO"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if [ -f "$REPO_ROOT/.gitignore" ]; then
    if grep -q '\.rag/' "$REPO_ROOT/.gitignore"; then
        test_result ".gitignore に .rag/ エントリ存在" "true" && PASS_COUNT=$((PASS_COUNT + 1))
    else
        test_result ".gitignore に .rag/ エントリ存在" "false" || true
    fi
else
    test_result ".gitignore ファイル存在" "false" || true
fi

# ========================================
# Full Verify（詳細チェック）
# ========================================

if [ "$MODE" = "full" ] || [ "$MODE" = "Full" ]; then
    log "" "INFO"
    log "" "INFO"
    log "[Full Verify] 開始" "INFO"

    # 6. Part02 リンク切れチェック（簡易）
    log "" "INFO"
    log "--- 6. Part02 内部参照チェック ---" "INFO"
    if [ -f "$REPO_ROOT/docs/Part02.md" ]; then
        BROKEN_LINKS=""

        # ADR参照チェック
        for adr_ref in $(grep -o 'decisions/[0-9][0-9][0-9][0-9]-[^)]*\.md' "$REPO_ROOT/docs/Part02.md" 2>/dev/null || true); do
            if [ ! -f "$REPO_ROOT/$adr_ref" ]; then
                BROKEN_LINKS="${BROKEN_LINKS} $adr_ref"
            fi
        done

        # glossary参照チェック
        if grep -q 'glossary/GLOSSARY\.md' "$REPO_ROOT/docs/Part02.md"; then
            if [ ! -f "$REPO_ROOT/glossary/GLOSSARY.md" ]; then
                BROKEN_LINKS="${BROKEN_LINKS} glossary/GLOSSARY.md"
            fi
        fi

        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if [ -z "$BROKEN_LINKS" ]; then
            test_result "Part02 リンク切れなし" "true" "OK" && PASS_COUNT=$((PASS_COUNT + 1))
        else
            test_result "Part02 リンク切れなし" "false" "切れたリンク:$BROKEN_LINKS" || true
        fi
    fi

    # 7. sources/ 保護確認
    log "" "INFO"
    log "--- 7. sources/ 保護状態確認 ---" "INFO"
    SOURCES_COUNT=$(find "$REPO_ROOT/sources" -type f 2>/dev/null | wc -l)
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$SOURCES_COUNT" -gt 0 ]; then
        test_result "sources/ にファイル存在" "true" "ファイル数: $SOURCES_COUNT" && PASS_COUNT=$((PASS_COUNT + 1))
    else
        test_result "sources/ にファイル存在" "false" "ファイル数: $SOURCES_COUNT" || true
    fi
fi

# ========================================
# 結果サマリー
# ========================================

log "" "INFO"
log "========================================" "INFO"
log "検証完了" "INFO"
log "モード: $MODE" "INFO"
log "合格: $PASS_COUNT / $TOTAL_TESTS" "INFO"
SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASS_COUNT / $TOTAL_TESTS) * 100}")
log "成功率: ${SUCCESS_RATE}%" "INFO"

if [ "$PASS_COUNT" -eq "$TOTAL_TESTS" ]; then
    log "結果: PASS ✓" "PASS"
    log "証跡: $REPORT_FILE" "INFO"
    log "========================================" "INFO"
    exit 0
else
    log "結果: FAIL ✗" "FAIL"
    log "証跡: $REPORT_FILE" "INFO"
    log "========================================" "INFO"
    exit 1
fi
