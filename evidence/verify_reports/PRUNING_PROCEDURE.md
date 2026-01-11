# Verify Reports Pruning Procedure（安全な削除手順）

## 目的
verify_reports の保持ポリシー（直近3件のみ）に従い、古いレポートを安全に削除する手順を定義します。

## 前提
- 保持ポリシー: 直近3件のみ（`decisions/0002-evidence-retention-policy.md`）
- 削除はコミット履歴に残す（git rm 使用）
- 自動削除は行わず、手動で実行する

## 手順（番号付き・実行可能）

### 1. 現状確認
まず、現在の verify_reports を確認します。

```bash
cd evidence/verify_reports
ls -lt verify_report_*.md
```

出力例:
```
verify_report_20260111_143022.md  ← 最新
verify_report_20260110_091503.md  ← 2番目
verify_report_20260109_165432.md  ← 3番目
verify_report_20260108_120000.md  ← 削除対象
verify_report_20260107_093000.md  ← 削除対象
```

### 2. 削除対象の特定
最新3件を除く、4件目以降をリストアップします。

```bash
# 最新3件を除外し、削除対象をリスト
ls -t verify_report_*.md | tail -n +4
```

### 3. 削除前の確認（MUST）
削除対象ファイルの内容を念のため確認します。

```bash
# 削除対象ファイルを1つずつ確認
for file in $(ls -t verify_report_*.md | tail -n +4); do
  echo "=== $file ==="
  head -n 10 "$file"
  echo ""
done
```

**確認ポイント**:
- [ ] 削除対象が本当に古いレポートか
- [ ] 重要な情報が含まれていないか（含まれていても git history から復元可能）
- [ ] ファイル名が命名規則に従っているか

### 4. Git ステータス確認
作業前に git の状態を確認します。

```bash
git status
```

**確認ポイント**:
- [ ] 未コミットの変更がないか（ある場合は先にコミット）
- [ ] 正しいブランチにいるか

### 5. 削除実行（git rm）
削除対象を `git rm` で削除します。

```bash
# 削除対象を git rm
ls -t evidence/verify_reports/verify_report_*.md | tail -n +4 | xargs -r git rm
```

**MUST**: 通常の `rm` ではなく `git rm` を使用すること（履歴に残すため）

### 6. コミット
削除をコミットします。コミットメッセージには以下を含めます：
- 何を削除したか
- なぜ削除したか（保持ポリシー）
- 参照ADR

```bash
git commit -m "$(cat <<'EOF'
chore: Prune old verify_reports (retain latest 3)

Removed verify_reports older than the latest 3 according to
retention policy (decisions/0002-evidence-retention-policy.md).

Deleted reports:
- verify_report_20260108_120000.md
- verify_report_20260107_093000.md

Reports can be restored from git history if needed.
EOF
)"
```

### 7. 検証
削除後の状態を確認します。

```bash
# 残っているレポート数を確認（3件以下であるべき）
ls -lt evidence/verify_reports/verify_report_*.md | wc -l

# どのレポートが残っているか確認
ls -lt evidence/verify_reports/verify_report_*.md
```

**期待値**: 3件以下のレポートが日付順に並んでいる

### 8. プッシュ（オプション）
チーム運用の場合、リモートにプッシュします。

```bash
git push origin <branch-name>
```

## 復旧手順（誤削除時）

万が一、誤って削除した場合の復旧方法：

```bash
# 削除前のコミットを確認
git log --oneline -- evidence/verify_reports/

# 特定のファイルを復元
git checkout <commit-hash> -- evidence/verify_reports/verify_report_YYYYMMDD_HHMMSS.md

# 復元をコミット
git add evidence/verify_reports/verify_report_YYYYMMDD_HHMMSS.md
git commit -m "Restore verify_report_YYYYMMDD_HHMMSS.md (reason: ...)"
```

## 自動化スクリプト（オプション）

**注意**: 自動削除は推奨しませんが、レビュー付きで実行する場合のスクリプト例：

```bash
#!/bin/bash
# prune_verify_reports.sh
# Usage: ./prune_verify_reports.sh

set -euo pipefail

REPORTS_DIR="evidence/verify_reports"
KEEP_COUNT=3

echo "=== Verify Reports Pruning ==="
echo "Policy: Keep latest $KEEP_COUNT reports"
echo ""

# 現在のレポート数
TOTAL=$(ls -t "$REPORTS_DIR"/verify_report_*.md 2>/dev/null | wc -l)
echo "Total reports: $TOTAL"

if [ "$TOTAL" -le "$KEEP_COUNT" ]; then
  echo "No pruning needed (total <= $KEEP_COUNT)"
  exit 0
fi

# 削除対象をリスト
TO_DELETE=$(ls -t "$REPORTS_DIR"/verify_report_*.md | tail -n +$(($KEEP_COUNT + 1)))
DELETE_COUNT=$(echo "$TO_DELETE" | wc -l)

echo "Reports to delete: $DELETE_COUNT"
echo "$TO_DELETE"
echo ""

# 確認プロンプト
read -p "Proceed with deletion? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

# git rm 実行
echo "$TO_DELETE" | xargs git rm

echo ""
echo "Files removed. Please review and commit:"
echo "  git status"
echo "  git commit -m 'chore: Prune old verify_reports (retain latest 3)'"
```

## チェックリスト
- [ ] 現状確認（手順1）を実施
- [ ] 削除対象を正しく特定（手順2）
- [ ] 削除前に内容確認（手順3）
- [ ] git status で状態確認（手順4）
- [ ] git rm で削除（通常の rm ではない）（手順5）
- [ ] コミットメッセージに理由・ADR参照を記載（手順6）
- [ ] 削除後の検証（3件以下か確認）（手順7）
- [ ] プッシュ（チーム運用の場合）（手順8）

## 未決事項
- 自動化スクリプトを checks/ に配置するか検討
- Pruning の実行タイミング（新規レポート追加時 vs 定期実行）の決定

## 参照
- `decisions/0002-evidence-retention-policy.md` : 保持ポリシーの根拠
- `evidence/verify_reports/README.md` : Verify Reports の概要
- `docs/Part09.md` : Permission Tier（実行権限）
