# evidence/verify_reports/（検証実行の証跡）

## 目的
Verify Gate（Fast/Full）の実行結果を **再現可能・追跡可能** な形で保存する。

## 命名規約（MUST）
```
YYYYMMDD_HHMMSS_<check_name>.md
```

- **YYYYMMDD_HHMMSS**：実行日時（UTC or JST、統一すること）
- **<check_name>**：検証項目名（例：link_check, glossary_check, part_consistency, pending_items）
- **1セット = 4ファイル**：同一タイムスタンプで以下4点を出力
  1. `YYYYMMDD_HHMMSS_link_check.md`
  2. `YYYYMMDD_HHMMSS_glossary_check.md`
  3. `YYYYMMDD_HHMMSS_part_consistency.md`
  4. `YYYYMMDD_HHMMSS_pending_items.md`

## 保持ポリシー（ADR-0003）
- **直近3セット**（タイムスタンプ単位）を保持
- 古いセットは `checks/prune_verify_reports.sh` で `git rm -f` により削除
- 削除前に `--dry-run` と確認プロンプトで安全確保（MUST）

## ファイル形式
各ファイルは Markdown 形式で以下を含む（推奨）：
- 実行日時・実行者（または実行環境）
- 検証対象（Part / ファイルパス / ルール）
- 判定結果（PASS / FAIL / WARN）
- エラー詳細（FAILの場合）
- 再現手順（手動検証の場合）

## 例
```
20260111_031500_link_check.md
20260111_031500_glossary_check.md
20260111_031500_part_consistency.md
20260111_031500_pending_items.md
```

## 参照
- `decisions/0003-evidence-retention-policy.md`（保持ポリシー詳細）
- `docs/Part10.md`（Verify Gate仕様）
- `checks/prune_verify_reports.sh`（整理スクリプト）
