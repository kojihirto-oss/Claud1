# Part 10：Verify Gate（Fast/Full・必須カテゴリ・Verifyレポート・機械判定の裁定）

## 0. このPartの位置づけ
- 目的：Verify Gate（Fast/Full）の詳細仕様と Verify レポート保持ポリシーを定義する
- 依存：Part02（用語）、Part09（Permission Tier、DoD、Fast Verify 手順）
- 影響：全Part（Verify 実行の基準）、checks/（検証スクリプト）、evidence/verify_reports/（レポート保存）

## 1. 目的（Purpose）

Verify Gate（Fast Verify / Full Verify）の詳細仕様を定義し、品質ゲートとして機能させる。
- Fast Verify（4点チェック）の実行基準と判定方法
- Full Verify（詳細検証）の実装（今後定義）
- Verify レポートの保持ポリシー（直近3方式）
- 機械判定の裁定基準

## 2. 適用範囲（Scope / Out of Scope）

### Scope
- Fast Verify の実行基準と判定方法（Part09 で定義済み、本Partで詳細化）
- Full Verify の実装仕様（今後定義）
- Verify レポートの保持ポリシー（直近3方式）
- Verify レポートのフォーマットと必須項目
- 古いレポートの prune 手順

### Out of Scope
- Evidence Pack の保持ポリシー（Part09 section 9 で定義済み：削除禁止）
- CI/CD との連携（Part14 で定義予定）

## 3. 前提（Assumptions）

1. Fast Verify は DoD-2 の必須要件（Part09 section 5.2）
2. Verify レポートは品質トレンドの追跡に使用される
3. Evidence Pack（削除禁止）と Verify レポート（ローテーション）は区別される
4. Verify レポートのサイズは小さい（数KB〜数十KB）

## 4. 用語（Glossary参照：Part02）

- **Verify Gate**: 品質ゲート。Fast Verify と Full Verify の総称。
- **Fast Verify**: 必須4点チェック（リンク切れ/用語揺れ/Part間整合/未決事項）。
- **Full Verify**: 詳細検証（Fast Verify + 追加項目、今後定義）。
- **Verify レポート**: Fast/Full Verify の実行結果を記録したファイル。
- **recent-3**: 直近3回分を保持し、古いものを削除するローテーション方式。

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 Fast Verify の実行基準（Part09 より）

詳細は Part09 section 6.2 を参照。本Partでは保持ポリシーに焦点を当てる。

### 5.2 Verify レポート保持ポリシー（recent-3 方式）

#### 保持方針
- **MUST**: evidence/verify_reports/ に直近3回分のレポートを保持する
- **MUST**: 4回目以降の古いレポートは削除（prune）する
- **MUST**: レポートのファイル名は `YYYYMMDD_HHMM_verify.txt` 形式とする
- **MUST**: レポートには実行日時、チェック項目、判定結果を含める

#### 採用理由（直近3を選択）
1. **品質トレンド分析**: 3回分の履歴で改善/悪化を検出可能
2. **監査可能性**: Part09 section 9（監査観点）の要件に適合
3. **ディスク効率**: レポートは小サイズのため3倍でも許容範囲
4. **運用安全性**: 誤操作時のバックアップとして機能
5. **Evidence Pack との区別**: 重要な証跡（evidence/ 直下）は削除禁止、verify_reports は一時レポート

#### 最新1を不採用とした理由
- 過去との比較ができず、品質トレンドが不明
- 監査時に変化の履歴を示せない
- Part09 の監査要件を満たしにくい

### 5.3 Evidence Pack との区別

| 種類 | 保存場所 | 保持方針 | 用途 |
|------|----------|----------|------|
| **Evidence Pack** | evidence/ 直下 | 削除禁止（追記のみ） | 永続的な監査証跡 |
| **Verify レポート** | evidence/verify_reports/ | 直近3でローテーション | 品質トレンド追跡 |

**Evidence Pack の内容（削除禁止）：**
- 変更差分（*_diff.txt）
- 実行ログ（*_log.txt）
- HumanGate 承認記録（*_approval.txt）

**Verify レポートの内容（直近3）：**
- Fast/Full Verify の実行結果
- チェック項目ごとの判定（PASS/FAIL/WARN）
- エラー詳細

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 Verify レポートの生成手順

1. **Fast Verify を実行**
   - Part09 section 6.2 の手順に従う
   - 4点チェックを実行（リンク切れ/用語揺れ/Part間整合/未決事項）

2. **レポートを生成**
   - ファイル名: `YYYYMMDD_HHMM_verify.txt`
   - 保存先: `evidence/verify_reports/`
   - 内容: 実行日時、チェック項目、判定結果、エラー詳細

3. **レポート数を確認**
   - `ls -1 evidence/verify_reports/*_verify.txt | wc -l` で確認
   - 3を超える場合、prune 実行（セクション 6.2 参照）

4. **Git add & commit**
   ```bash
   git add evidence/verify_reports/YYYYMMDD_HHMM_verify.txt
   git commit -m "Add verify report: YYYYMMDD_HHMM"
   ```

### 6.2 古いレポートの Prune 手順

詳細は `evidence/verify_reports/README.md` を参照。以下は要約：

1. **現在のレポート数を確認**
   ```bash
   cd evidence/verify_reports
   ls -1 *_verify.txt | wc -l
   ```

2. **3を超える場合、削除対象を特定**
   ```bash
   # 最も古いレポートをリストアップ
   ls -1t *_verify.txt | tail -n +4
   ```

3. **Git で削除**
   ```bash
   # 4番目以降（古い順）を削除
   ls -1t *_verify.txt | tail -n +4 | xargs git rm -f
   ```

4. **削除結果を確認**
   ```bash
   # 残りが3以下であることを確認
   ls -1 *_verify.txt
   ```

5. **Commit & Push**
   ```bash
   git commit -m "Prune old verify_reports (keep recent 3)"
   git push origin <branch-name>
   ```

### 6.3 重要なレポートの永久保存（例外）

特定のレポートを永久保存したい場合：

1. **レポートを evidence/ 直下にコピー**
   ```bash
   cp evidence/verify_reports/20260111_0600_verify.txt \
      evidence/20260111_0600_critical_verify.txt
   ```

2. **Git add & commit**
   ```bash
   git add evidence/20260111_0600_critical_verify.txt
   git commit -m "Archive critical verify report"
   ```

3. **verify_reports/ 内のファイルは通常通り prune される**

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 Prune の誤実行

**検出条件**：
- 直近3より多くのレポートを削除してしまった
- 重要なレポートを誤って削除した

**対処**：
1. Git history から復元
   ```bash
   git log -- evidence/verify_reports/
   git checkout <commit-hash> -- evidence/verify_reports/<filename>
   ```

2. 復元後、正しい prune を再実行

### 7.2 レポート数が0になった場合

**検出条件**：
- すべてのレポートが削除された（誤操作）

**対処**：
1. 次回の Verify 実行時に新しいレポートを生成
2. Git history から最新のレポートを復元（可能であれば）

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 Verify レポート数の判定

| 項目 | 判定条件 | PASS | WARN | FAIL |
|------|----------|------|------|------|
| レポート数 | evidence/verify_reports/ 内のレポート数 | 1〜3件 | 4件以上 | 0件 |

### 8.2 Verify レポートの必須項目チェック

各レポートに以下が含まれているか確認：

| 項目 | 必須 | 判定 |
|------|------|------|
| 実行日時 | MUST | なければ FAIL |
| 実行者（AI/人間） | MUST | なければ FAIL |
| チェック項目と判定 | MUST | なければ FAIL |
| エラー詳細（FAIL時） | SHOULD | なければ WARN |

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 Verify レポートに記録すべき内容

- 実行日時（YYYY-MM-DD HH:MM:SS 形式）
- 実行者（AI Agent / 人間の識別）
- チェック項目と判定結果（各項目ごとに PASS/FAIL/WARN）
- エラー詳細（FAIL の場合、どのファイル・行・内容が問題か）
- 実行環境（ブランチ名、commit hash）

### 9.2 監査時の確認項目

- 直近3回のレポートが存在するか
- 各レポートに必須項目が含まれているか
- FAIL があった場合、修正されているか（次のレポートで PASS になっているか）
- レポート数が3を超えていないか（prune が正しく実行されているか）

## 10. チェックリスト

Verify レポート生成・管理時：

- [ ] Verify を実行し、結果をレポートに記録した
- [ ] レポートのファイル名が `YYYYMMDD_HHMM_verify.txt` 形式である
- [ ] レポートに実行日時、実行者、チェック項目、判定結果を含めた
- [ ] レポートを evidence/verify_reports/ に保存した
- [ ] レポート数を確認し、3を超える場合は prune を実行した
- [ ] Git add & commit を完了した
- [ ] 重要なレポートは evidence/ 直下にコピーした（該当時）

## 11. 未決事項（推測禁止）

- Full Verify の詳細仕様（Fast Verify に追加する検証項目）
- Verify レポートの自動生成スクリプト（checks/ で今後実装）
- Prune の自動化（Verify 実行時に自動で prune するか、手動実行とするか）
- CI/CD との連携（Part14 で定義予定）

## 12. 参照（パス）

- docs/Part09.md section 5.2（DoD-2: Verify PASS）
- docs/Part09.md section 6.2（Fast Verify の実行手順）
- docs/Part09.md section 9（監査観点）
- docs/Part02.md（用語定義：Verify Gate、Fast Verify、Full Verify）
- evidence/verify_reports/README.md（保持ポリシー詳細）
- evidence/README.md（Evidence Pack との区別）
- checks/README.md（検証手順）
