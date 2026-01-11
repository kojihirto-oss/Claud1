#!/bin/bash
# prune_verify_reports.sh - 直近3を残して古い Verify レポートを削除
#
# Usage: ./checks/prune_verify_reports.sh [--dry-run]
#
# Options:
#   --dry-run : 削除対象をリストアップするのみで、実際には削除しない

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERIFY_REPORTS_DIR="${REPO_ROOT}/evidence/verify_reports"

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
fi

echo "==============================================="
echo " Verify Reports Prune Tool (recent-3)"
echo "==============================================="
echo ""

# 1. verify_reports ディレクトリの存在確認
if [ ! -d "${VERIFY_REPORTS_DIR}" ]; then
  echo "❌ Error: ${VERIFY_REPORTS_DIR} が存在しません"
  exit 1
fi

cd "${VERIFY_REPORTS_DIR}"

# 2. 現在のレポート数を確認
REPORT_COUNT=$(ls -1 *_verify.txt 2>/dev/null | wc -l)
echo "📊 現在のレポート数: ${REPORT_COUNT}"

if [ "${REPORT_COUNT}" -eq 0 ]; then
  echo "⚠️  レポートが1件もありません（削除不要）"
  exit 0
fi

if [ "${REPORT_COUNT}" -le 3 ]; then
  echo "✅ レポート数が3以下のため、削除不要"
  echo ""
  echo "現在のレポート:"
  ls -1t *_verify.txt
  exit 0
fi

# 3. 削除対象のレポートを特定（最も古いものから）
DELETE_COUNT=$((REPORT_COUNT - 3))
echo "🗑️  削除対象: ${DELETE_COUNT} 件"
echo ""

# 4. 削除対象をリストアップ（確認）
echo "削除するファイル:"
DELETE_FILES=$(ls -1t *_verify.txt | tail -n ${DELETE_COUNT})
echo "${DELETE_FILES}"
echo ""

echo "残すファイル（直近3）:"
KEEP_FILES=$(ls -1t *_verify.txt | head -n 3)
echo "${KEEP_FILES}"
echo ""

# 5. Dry-run モードの場合はここで終了
if [ "${DRY_RUN}" = true ]; then
  echo "🔍 Dry-run モード: 実際には削除しません"
  echo ""
  echo "実行コマンド:"
  echo "  ls -1t *_verify.txt | tail -n ${DELETE_COUNT} | xargs git rm -f"
  exit 0
fi

# 6. 確認プロンプト（安全のため）
read -p "上記のファイルを削除してよろしいですか？ [y/N]: " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "❌ キャンセルしました"
  exit 0
fi

# 7. Git で削除（tracked ファイルの場合）
echo ""
echo "🗑️  削除実行中..."
ls -1t *_verify.txt | tail -n ${DELETE_COUNT} | while read file; do
  if git ls-files --error-unmatch "${file}" > /dev/null 2>&1; then
    echo "  git rm ${file}"
    git rm -f "${file}"
  else
    echo "  rm ${file} (untracked)"
    rm -f "${file}"
  fi
done

# 8. 削除結果の確認
echo ""
echo "✅ 削除完了"
echo ""
echo "残りのレポート:"
ls -1t *_verify.txt
echo ""

REMAINING_COUNT=$(ls -1 *_verify.txt 2>/dev/null | wc -l)
echo "📊 残りのレポート数: ${REMAINING_COUNT}"

if [ "${REMAINING_COUNT}" -gt 3 ]; then
  echo "⚠️  警告: まだ ${REMAINING_COUNT} 件のレポートがあります（3を超えています）"
  exit 1
fi

echo ""
echo "==============================================="
echo " 次のステップ:"
echo "   1. git status で削除が staged されているか確認"
echo "   2. git commit -m 'Prune old verify_reports (keep recent 3)'"
echo "   3. git push origin <branch-name>"
echo "==============================================="
