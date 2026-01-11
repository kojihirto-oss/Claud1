#!/bin/bash
# prune_verify_reports.sh - 直近3セットを残して古い Verify レポートを削除
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
if [ "${1:-}" == "--dry-run" ]; then
  DRY_RUN=true
fi

echo "==============================================="
echo " Verify Reports Prune Tool (recent-3)"
echo "==============================================="
echo ""

# 1. verify_reports ディレクトリの存在確認
if [ ! -d "${VERIFY_REPORTS_DIR}" ]; then
  echo "? Error: ${VERIFY_REPORTS_DIR} が存在しません"
  exit 1
fi

cd "${VERIFY_REPORTS_DIR}"

# 2. 現在のレポートセット数を確認（README.md は除外）
mapfile -t report_files < <(ls -1 *.md 2>/dev/null | grep -v '^README.md$' || true)

if [ "${#report_files[@]}" -eq 0 ]; then
  echo "??  レポートが1件もありません（削除不要）"
  exit 0
fi

valid_files=()
timestamps=()
for file in "${report_files[@]}"; do
  if [[ "$file" =~ ^[0-9]{8}_[0-9]{6}_.+\.md$ ]]; then
    valid_files+=("$file")
    timestamps+=("${file:0:15}")
  fi
done

if [ "${#valid_files[@]}" -eq 0 ]; then
  echo "??  タイムスタンプ付きのレポートがありません（削除不要）"
  exit 0
fi

mapfile -t sorted_timestamps < <(printf '%s\n' "${timestamps[@]}" | sort -r | uniq)
SET_COUNT=${#sorted_timestamps[@]}
echo "?? 現在のレポートセット数: ${SET_COUNT}"

if [ "${SET_COUNT}" -le 3 ]; then
  echo "? レポートセット数が3以下のため、削除不要"
  echo ""
  echo "現在のレポート:" 
  printf '%s\n' "${valid_files[@]}" | sort -r
  exit 0
fi

# 3. 削除対象のセットを特定（最も古いものから）
DELETE_SET_COUNT=$((SET_COUNT - 3))
echo "???  削除対象セット: ${DELETE_SET_COUNT} 件"
echo ""

keep_timestamps=("${sorted_timestamps[@]:0:3}")
delete_timestamps=("${sorted_timestamps[@]:3}")

declare -A delete_map=()
for ts in "${delete_timestamps[@]}"; do
  delete_map["$ts"]=1
done

delete_files=()
keep_files=()
for file in "${valid_files[@]}"; do
  ts="${file:0:15}"
  if [ -n "${delete_map[$ts]:-}" ]; then
    delete_files+=("$file")
  else
    keep_files+=("$file")
  fi
done

# 4. 削除対象をリストアップ（確認）
echo "削除するファイル:"
printf '%s\n' "${delete_files[@]}" | sort -r
echo ""

echo "残すファイル（直近3セット）:"
printf '%s\n' "${keep_files[@]}" | sort -r
echo ""

# 5. Dry-run モードの場合はここで終了
if [ "${DRY_RUN}" = true ]; then
  echo "?? Dry-run モード: 実際には削除しません"
  exit 0
fi

# 6. 確認プロンプト（安全のため）
read -p "上記のファイルを削除してよろしいですか？ [y/N]: " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "? キャンセルしました"
  exit 0
fi

# 7. Git で削除（tracked ファイルの場合）
echo ""
echo "???  削除実行中..."
for file in "${delete_files[@]}"; do
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
echo "? 削除完了"
echo ""
echo "残りのレポート:"
mapfile -t remaining_files < <(ls -1 *.md 2>/dev/null | grep -v '^README.md$' || true)
if [ "${#remaining_files[@]}" -gt 0 ]; then
  printf '%s\n' "${remaining_files[@]}" | sort -r
fi
echo ""

remaining_timestamps=()
for file in "${remaining_files[@]}"; do
  if [[ "$file" =~ ^[0-9]{8}_[0-9]{6}_.+\.md$ ]]; then
    remaining_timestamps+=("${file:0:15}")
  fi
done

if [ "${#remaining_timestamps[@]}" -gt 0 ]; then
  mapfile -t remaining_sets < <(printf '%s\n' "${remaining_timestamps[@]}" | sort -r | uniq)
  REMAINING_SET_COUNT=${#remaining_sets[@]}
else
  REMAINING_SET_COUNT=0
fi

echo "?? 残りのレポートセット数: ${REMAINING_SET_COUNT}"

if [ "${REMAINING_SET_COUNT}" -gt 3 ]; then
  echo "??  警告: まだ ${REMAINING_SET_COUNT} セットのレポートがあります（3を超えています）"
  exit 1
fi

echo ""
echo "==============================================="
echo " 次のステップ:"
echo "   1. git status で削除が staged されているか確認"
echo "   2. git commit -m 'Prune old verify_reports (keep recent 3)'"
echo "   3. git push origin <branch-name>"
echo "==============================================="
