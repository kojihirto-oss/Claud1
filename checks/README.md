# checks/（検証手順・品質ゲート）

## 目的
SSOT（docs/）が壊れていないことを確認するための **再現可能な検証手順** を置く。

## ルール（SHOULD）
- 手順は「誰がやっても同じ結果」になるように書く
- 初期は手動でOK、安定したらスクリプト化/CI化（推奨）

## Fast Verify（最低限のゲート）
1) **link_check**：docs/ 内リンク切れ（相対パス／外部URL）
2) **glossary_check**：用語揺れ（glossary と docs の不一致）
3) **part_consistency**：Part間整合（上位規約 Part00 と衝突していないか）
4) **pending_items**：未決事項の残存一覧（TODO/未決の集計）

## 出力（MUST）
- **命名規約**：`evidence/verify_reports/YYYYMMDD_HHMMSS_<check_name>.md`
- **1セット = 4ファイル**（同一タイムスタンプで上記4項目を出力）
- **保持ポリシー**：直近3セット（ADR-0003）
  - 整理スクリプト：`checks/prune_verify_reports.sh`

## スクリプト
- `prune_verify_reports.sh`：古い証跡を削除（--dry-run 対応）

## 参照
- `decisions/0003-evidence-retention-policy.md`（保持ポリシー）
- `docs/Part10.md`（Verify Gate詳細）
- `evidence/verify_reports/README.md`（証跡保存場所）
