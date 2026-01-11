# Part 10：Verify Gate（Fast/Full・必須カテゴリ・Verifyレポート・機械判定の裁定）

## 0. このPartの位置づけ
- 目的：Verify Gate の運用ルール・レポート生成・Evidence保持ポリシーを定義
- 依存：Part09（Permission Tier）, Part02（用語定義）
- 影響：Evidence（証跡管理）, Release判定

## 1. 目的（Purpose）

Verify Gate を通じて、コード・ドキュメント・設定の品質を検証し、
リリース可否判定のための Evidence（検証レポート）を生成・保持する。

## 2. 適用範囲（Scope / Out of Scope）

**Scope（対象）**:
- Fast Verify / Full Verify の実行基準
- Verify レポートの生成・保存
- 必須検証カテゴリの定義
- 機械判定の裁定ルール
- Evidence（verify_reports）の保持ポリシー

**Out of Scope（対象外）**:
- 個別の検証スクリプト詳細（checks/ に配置）
- CI/CD パイプライン設定（別 Part で定義）

## 3. 前提（Assumptions）

- Verify Gate は手動または半自動で実行される
- 検証結果は markdown 形式で出力される
- Evidence は Git リポジトリで管理される
- 削除された Evidence は Git history から復元可能

## 4. 用語（Glossary参照：Part02）

- **Verify Gate**: コード・ドキュメントの品質検証ゲート
- **Fast Verify**: 軽量・高速な検証（commit 前など）
- **Full Verify**: 完全な検証（release 前など）
- **verify_report**: 検証結果レポート（Evidence）
- **Pruning**: 古い Evidence の削除（保持ポリシーに従う）

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 Evidence 保持ポリシー（MUST）

**MUST**: verify_reports は **直近3件のみ** 保持する
- 根拠: `decisions/0002-evidence-retention-policy.md`
- 理由: トレンド分析・回帰検出・監査証跡として最小限かつ十分

**MUST**: 古い verify_reports を削除する際は `git rm` を使用する
- 理由: コミット履歴に削除記録を残し、復元可能にする
- 禁止: 通常の `rm` コマンドでの削除

**MUST**: 新規 verify_report 追加時、4件以上存在する場合は pruning を実行する
- 手順: `evidence/verify_reports/PRUNING_PROCEDURE.md`

**MUST NOT**: verify_reports を自動削除しない
- 理由: 誤削除防止、手動承認プロセスの維持

### 5.2 レポート命名規則（MUST）

verify_report のファイル名は以下の形式に従う：
```
verify_report_YYYYMMDD_HHMMSS.md
```

例: `verify_report_20260111_143022.md`

### 5.3 検証実行（SHOULD）

**SHOULD**: Fast Verify は頻繁に実行する（commit 前、pull request 前など）
**SHOULD**: Full Verify は重要なタイミングで実行する（release 前、major change 前など）

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 Verify Report 生成手順
1. 検証スクリプトを実行（checks/ 配下）
2. 結果を markdown 形式で出力
3. ファイル名を命名規則に従って生成（`verify_report_YYYYMMDD_HHMMSS.md`）
4. `evidence/verify_reports/` に保存
5. Git にコミット
6. 保持ポリシー確認（4件以上なら pruning 実施）

### 6.2 Pruning 手順
1. `evidence/verify_reports/` のレポート数を確認
2. 4件以上なら `evidence/verify_reports/PRUNING_PROCEDURE.md` に従って削除
3. `git rm` で古いレポートを削除
4. コミットメッセージに削除理由・ADR参照を明記
5. プッシュ（チーム運用の場合）

詳細: `evidence/verify_reports/PRUNING_PROCEDURE.md`

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 Verify 失敗時
- 失敗レポートも Evidence として保存する（MUST）
- 失敗原因を明記する
- 修正後に再検証を実施

### 7.2 誤って Pruning した場合
- Git history から復元する
- 復元手順: `evidence/verify_reports/PRUNING_PROCEDURE.md` § 復旧手順

### 7.3 保持ポリシー変更が必要な場合
- 新しい ADR を作成する（ADR → docs の順）
- Part10 を更新する
- 既存 Evidence への影響を評価する

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 Evidence 数の検証
**条件**: `evidence/verify_reports/` に存在する `verify_report_*.md` が 3件以下
**合否**:
- PASS: 3件以下
- FAIL: 4件以上（pruning 必要）

**検証コマンド例**:
```bash
count=$(ls evidence/verify_reports/verify_report_*.md 2>/dev/null | wc -l)
if [ $count -le 3 ]; then echo "PASS"; else echo "FAIL: $count reports (should be ≤ 3)"; fi
```

### 8.2 ファイル命名規則の検証
**条件**: すべての verify_report が `verify_report_YYYYMMDD_HHMMSS.md` 形式
**合否**:
- PASS: すべてのファイルが命名規則に従う
- FAIL: 命名規則に従わないファイルが存在

**検証コマンド例**:
```bash
ls evidence/verify_reports/*.md | grep -v -E 'verify_report_[0-9]{8}_[0-9]{6}\.md|README\.md|PRUNING_PROCEDURE\.md'
# 出力なし → PASS, 出力あり → FAIL
```

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 保持する Evidence
- **verify_reports**: 直近3件（最新の検証結果・トレンド分析用）
- **削除ログ**: Git commit history（pruning 記録）

### 9.2 参照パス
- Evidence 本体: `evidence/verify_reports/`
- 保持ポリシー: `decisions/0002-evidence-retention-policy.md`
- Pruning 手順: `evidence/verify_reports/PRUNING_PROCEDURE.md`
- README: `evidence/verify_reports/README.md`

### 9.3 監査時の確認項目
- [ ] verify_reports が直近3件以内か
- [ ] 削除時に git rm を使用したか（git log で確認）
- [ ] コミットメッセージに削除理由が明記されているか
- [ ] ファイル名が命名規則に従っているか

## 10. チェックリスト
- [ ] verify_report を生成する際、ファイル名が命名規則に従っているか
- [ ] 新規レポート追加後、4件以上存在しないか確認したか
- [ ] Pruning 実施時に PRUNING_PROCEDURE.md に従ったか
- [ ] 削除時に `git rm` を使用したか（`rm` ではない）
- [ ] コミットメッセージに ADR-0002 への参照を含めたか
- [ ] Part09（Permission Tier）に従った権限で実行したか

## 11. 未決事項（推測禁止）
- Fast Verify と Full Verify の具体的な検証項目（checks/ で定義予定）
- Verify Gate の自動化レベル（手動 / 半自動 / 全自動）
- Fast Verify / Full Verify でレポートを区別するか（現在は区別なし）
- CI/CD パイプラインとの統合方法

## 12. 参照（パス）
- `decisions/0002-evidence-retention-policy.md` : Evidence 保持ポリシー（直近3件）
- `evidence/verify_reports/README.md` : Verify Reports の概要
- `evidence/verify_reports/PRUNING_PROCEDURE.md` : 安全な削除手順
- `docs/Part09.md` : Permission Tier（実行権限）
- `docs/Part02.md` : 用語定義（Glossary）
- `checks/` : 検証スクリプト（今後追加）
