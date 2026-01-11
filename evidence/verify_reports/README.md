# evidence/verify_reports/（Verify レポート保持・ローテーション）

## 目的

Fast Verify および Full Verify の実行結果を保存し、品質トレンドの追跡と監査証跡を提供する。

## 保持ポリシー：直近3方式（recent-3）

### 方針
- **MUST**: 直近3回分の Verify レポートを保持する
- **MUST**: 4回目以降の古いレポートは自動的に削除（prune）する
- **MUST**: レポートのファイル名は `YYYYMMDD_HHMM_verify.txt` 形式とする
- **SHOULD**: レポートには実行日時、チェック項目、判定結果（PASS/FAIL/WARN）を含める

### 採用理由

**直近3を選択した根拠：**
1. **品質トレンド分析**: 3回分の履歴で改善/悪化を検出可能
2. **監査可能性**: Part09 section 9（監査観点）の要件に適合
3. **ディスク効率**: verify_reports は小サイズ（数KB〜数十KB）のため3倍でも許容範囲
4. **運用安全性**: 誤操作時のバックアップとして機能
5. **Evidence Pack との区別**: 重要な証跡（evidence/ 直下）は削除禁止、verify_reports は一時レポートとしてローテーション

**最新1を不採用とした理由：**
- 過去との比較ができず、品質トレンドが不明
- 監査時に変化の履歴を示せない
- Part09 の監査要件を満たしにくい

## ディレクトリ構造

```
evidence/
├── verify_reports/           ← このディレクトリ（Verify レポート）
│   ├── README.md             ← このファイル
│   ├── 20260111_0600_verify.txt  ← 最新
│   ├── 20260110_1800_verify.txt  ← 1つ前
│   └── 20260110_1200_verify.txt  ← 2つ前
├── YYYYMMDD_HHMM_<task-id>_diff.txt      ← Evidence Pack（削除禁止）
├── YYYYMMDD_HHMM_<task-id>_log.txt       ← Evidence Pack（削除禁止）
└── YYYYMMDD_HHMM_<task-id>_approval.txt  ← Evidence Pack（削除禁止）
```

## 運用ルール

### 1. レポート生成時
- Fast Verify または Full Verify の実行後、結果を `YYYYMMDD_HHMM_verify.txt` で保存
- レポートには以下を含める：
  - 実行日時（タイムスタンプ）
  - 実行者（AI Agent / 人間）
  - チェック項目（Fast Verify: 4項目、Full Verify: 詳細項目）
  - 判定結果（PASS / FAIL / WARN）
  - エラー詳細（FAIL の場合）

### 2. レポートのローテーション（prune）
- **タイミング**: 新しい Verify レポート生成時、または手動実行時
- **条件**: レポート数が3を超える場合
- **処理**: 最も古いレポートから順に削除（セクション「Prune手順」参照）

### 3. Evidence Pack との区別
- **verify_reports/**: 一時的な品質レポート（直近3でローテーション）
- **evidence/ 直下**: 永続的な証跡（Evidence Pack、削除禁止）
  - 変更差分（*_diff.txt）
  - 実行ログ（*_log.txt）
  - HumanGate 承認記録（*_approval.txt）

## Prune 手順（古いレポート削除）

### 手動 Prune の実行

以下のスクリプトを使用して、古い verify_reports を安全に削除する：

```bash
#!/bin/bash
# prune_verify_reports.sh - 直近3を残して古いレポートを削除

cd /path/to/repo/evidence/verify_reports

# 1. 現在のレポート数を確認
REPORT_COUNT=$(ls -1 *_verify.txt 2>/dev/null | wc -l)
echo "現在のレポート数: ${REPORT_COUNT}"

if [ "${REPORT_COUNT}" -le 3 ]; then
  echo "レポート数が3以下のため、削除不要"
  exit 0
fi

# 2. 削除対象のレポートを特定（最も古いものから）
DELETE_COUNT=$((REPORT_COUNT - 3))
echo "削除対象: ${DELETE_COUNT} 件"

# 3. 削除対象をリストアップ（確認）
echo "削除するファイル:"
ls -1t *_verify.txt | tail -n ${DELETE_COUNT}

# 4. 確認プロンプト（安全のため）
read -p "上記のファイルを削除してよろしいですか？ [y/N]: " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "キャンセルしました"
  exit 0
fi

# 5. Git で削除（tracked ファイルの場合）
ls -1t *_verify.txt | tail -n ${DELETE_COUNT} | xargs git rm -f

# 6. 削除結果の確認
echo "削除完了。残りのレポート:"
ls -1 *_verify.txt
```

### Prune 実行後の確認

```bash
# 1. 残りのレポート数を確認（3以下であること）
ls -1 evidence/verify_reports/*_verify.txt | wc -l

# 2. Git status で削除が staged されているか確認
git status

# 3. Commit
git commit -m "Prune old verify_reports (keep recent 3)"

# 4. Push
git push origin <branch-name>
```

## 自動化（将来実装）

**SHOULD**: Fast Verify/Full Verify の実行時に自動 prune を組み込む
- checks/ に prune スクリプトを配置
- Verify 実行後、レポート数が3を超える場合に自動削除
- 削除前に確認プロンプトを表示（人間判断）

## 例外処理

### 重要なレポートの永続保存

特定のレポートを永久保存したい場合（例：重大な問題を検出したレポート）：

1. レポートを evidence/ 直下にコピー（ファイル名変更）
   ```bash
   cp evidence/verify_reports/20260111_0600_verify.txt \
      evidence/20260111_0600_critical_verify.txt
   ```

2. Git add & commit
   ```bash
   git add evidence/20260111_0600_critical_verify.txt
   git commit -m "Archive critical verify report"
   ```

3. verify_reports/ 内のファイルは通常通り prune される

## 監査観点

### Verify レポートに記録すべき内容
- 実行日時（YYYY-MM-DD HH:MM:SS形式）
- 実行者（AI Agent / 人間の識別）
- チェック項目と判定結果（各項目ごとに PASS/FAIL/WARN）
- エラー詳細（FAIL の場合、どのファイル・行・内容が問題か）
- 実行環境（ブランチ名、commit hash）

### 監査時の確認項目
- 直近3回のレポートが存在するか
- 各レポートに必須項目が含まれているか
- FAIL があった場合、修正されているか（次のレポートで PASS になっているか）

## 参照

- docs/Part09.md section 5.2（DoD-2: Verify PASS）
- docs/Part09.md section 6.2（Fast Verify の実行手順）
- docs/Part09.md section 9（監査観点）
- docs/Part10.md section 5（Verify レポート保持ポリシー）
- checks/README.md（検証手順）
