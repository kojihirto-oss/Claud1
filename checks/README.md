# checks/（検証手順・品質ゲート）

## 目的
SSOT（docs/）が壊れていないことを確認するための **再現可能な検証手順** を置く。

## ルール（SHOULD）
- 手順は「誰がやっても同じ結果」になるように書く
- 初期は手動でOK、安定したらスクリプト化/CI化（推奨）

## 最低限のゲート（推奨）
1) docs 内リンク切れ（相対パス／外部URL）
2) 用語揺れ（glossary と docs の不一致）
3) Part間整合（上位規約 Part00 と衝突していないか）
4) 未決事項の残存一覧（TODO/未決の集計）

## 出力（推奨）
- checks/_reports/YYYYMMDD_HHMM/ に結果を保存（将来導入）

## 利用可能なスクリプト

### prune_verify_reports.sh

**目的**: evidence/verify_reports/ の古いレポートを削除し、直近3を保持する

**使用方法**:
```bash
# Dry-run（削除対象の確認のみ）
./checks/prune_verify_reports.sh --dry-run

# 実行（確認プロンプトあり）
./checks/prune_verify_reports.sh
```

**動作**:
1. evidence/verify_reports/ 内の *_verify.txt ファイル数を確認
2. 3以下の場合は何もしない
3. 4以上の場合、最も古いファイルから削除（直近3を残す）
4. Git で削除（git rm -f）
5. 削除後、git commit & push が必要

**詳細**: evidence/verify_reports/README.md および docs/Part10.md section 6.2 を参照
