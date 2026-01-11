# Part 10：Verify Gate（Fast/Full・必須カテゴリ・Verifyレポート・機械判定の裁定）

## 0. このPartの位置づけ
- 目的：SSOT（docs/）が壊れていないことを確認するための検証手順と証跡保存ルールを定める
- 依存：Part00（SSOT原則）、Part02（用語）、glossary/、decisions/ADR-0003
- 影響：evidence/verify_reports/、checks/、Release判定

## 1. 目的（Purpose）
SSOT（docs/）の品質を保証するため、以下を実現する：
1. **再現可能な検証手順**（Fast Verify / Full Verify）
2. **機械判定可能なルール**（PASS/FAIL/WARN）
3. **証跡の追跡可能性**（Evidence保存・保持ポリシー）

## 2. 適用範囲（Scope / Out of Scope）
### Scope
- docs/ 内の整合性検証（リンク切れ / 用語揺れ / Part間矛盾 / 未決事項）
- 検証結果の証跡保存（evidence/verify_reports/）
- 証跡の保持ポリシー（ADR-0003：recent-3セット）

### Out of Scope
- コード実装の品質検証（別途CI/CDで実施）
- パフォーマンステスト
- セキュリティ監査（別途Part適用）

## 3. 前提（Assumptions）
- Git管理されたリポジトリである
- checks/ 配下にスクリプトまたは手動手順が存在する
- 検証実行者はGitへの書き込み権限を持つ

## 4. 用語（Glossary参照：Part02）
- **Fast Verify**：最低限の品質ゲート（4項目、数分で完了）
- **Full Verify**：網羅的検証（Fast Verify + 追加項目）
- **Verify Report**：検証実行の証跡（1セット = 4ファイル）
- **recent-3セット**：直近3回分のタイムスタンプ単位の証跡を保持するポリシー

## 5. ルール（MUST / MUST NOT / SHOULD）
### 5.1 検証実行（MUST）
1. **docs/ を変更した場合は必ず Fast Verify を実行する**
2. **Fast Verify が PASS しない限り、変更をコミットしてはならない（MUST NOT）**
3. **Full Verify は Release 前に必ず実行する（MUST）**

### 5.2 Verify Report 命名規約（MUST）
- ファイル名：`YYYYMMDD_HHMMSS_<check_name>.md`
- **1セット = 4ファイル**（同一タイムスタンプ）：
  1. `YYYYMMDD_HHMMSS_link_check.md`
  2. `YYYYMMDD_HHMMSS_glossary_check.md`
  3. `YYYYMMDD_HHMMSS_part_consistency.md`
  4. `YYYYMMDD_HHMMSS_pending_items.md`

### 5.3 証跡保存（MUST）
- Verify Report は `evidence/verify_reports/` に保存する
- 保持ポリシー：**直近3セット**（タイムスタンプ単位）を残す（ADR-0003）
- 古いセットは `checks/prune_verify_reports.sh` で削除する

### 5.4 判定ルール（MUST）
- **PASS**：全項目が正常
- **FAIL**：1つでも致命的エラーがある（修正必須）
- **WARN**：推奨事項違反（修正推奨、リリースブロックしない）

## 6. 手順（実行可能な粒度、番号付き）
### 6.1 Fast Verify 実行手順
1. カレントディレクトリをリポジトリルートに移動
2. 以下4項目を実行（手動またはスクリプト）：
   - **link_check**：docs/ 内の相対パス・外部URLリンク切れ確認
   - **glossary_check**：docs/ と glossary/ の用語不一致確認
   - **part_consistency**：Part間の矛盾（上位規約違反）確認
   - **pending_items**：未決事項の残存確認
3. 各項目の結果を `evidence/verify_reports/YYYYMMDD_HHMMSS_<check_name>.md` に保存
4. 全項目 PASS の場合のみ、次ステップ（コミット）へ進む

### 6.2 証跡整理手順
1. `checks/prune_verify_reports.sh --dry-run` で削除対象を確認
2. 確認後、`checks/prune_verify_reports.sh` を実行（確認プロンプト表示）
3. 古いセットが `git rm -f` で削除される

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
- **FAIL時**：エラー内容を修正し、再度 Fast Verify 実行
- **スクリプトエラー時**：手動で検証を実施し、結果をレポートに記録
- **証跡削除誤操作時**：`git reflog` から復旧（一時的に可能）

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
| 項目 | 判定条件 | PASS条件 | FAIL条件 |
|------|----------|----------|----------|
| link_check | docs/ 内のリンク有効性 | すべて到達可能 | 1つでもリンク切れ |
| glossary_check | 用語の一致 | すべて一致 | 不一致が1つでも存在 |
| part_consistency | Part間の矛盾 | 矛盾なし | 上位規約違反が存在 |
| pending_items | 未決事項の残存 | なし（または明示的に許可） | 未解決の未決事項が存在 |

## 9. 監査観点（Evidenceに残すもの・参照パス）
- **Verify Report**：`evidence/verify_reports/YYYYMMDD_HHMMSS_*.md`（4点1セット）
- **保持ポリシー**：`decisions/0003-evidence-retention-policy.md`
- **検証手順**：`checks/README.md`

## 10. チェックリスト
- [ ] Fast Verify 4項目すべて実行済み
- [ ] Verify Report 4ファイルが evidence/verify_reports/ に保存済み
- [ ] すべて PASS 判定を得た
- [ ] 古い証跡を prune_verify_reports.sh で整理済み（必要に応じて）

## 11. 未決事項（推測禁止）
- タイムスタンプのタイムゾーン統一（UTC or JST）を明示する（glossary/ に追加予定）
- Full Verify の追加項目を定義する（将来）

## 12. 参照（パス）
- `decisions/0003-evidence-retention-policy.md`（保持ポリシー）
- `evidence/verify_reports/README.md`（証跡保存場所）
- `checks/README.md`（検証手順）
- `checks/prune_verify_reports.sh`（証跡整理スクリプト）
