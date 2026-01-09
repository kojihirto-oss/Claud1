# ADR-0001: SSOT運用ガバナンス（変更手順・用語・根拠・検証）

- 日付: 2026-01-09
- 状態: 承認
- 対象: リポジトリ全体（docs/, decisions/, glossary/, sources/, checks/）
- 変更ルール: ADR → docs（必須）

## 決定（MUST）
1. SSOT本文は docs/ のみ
2. 仕様/運用の変更は必ず decisions/ にADRを追加してから docs/ を変更する（ADR→docs）
3. 用語は glossary/ に唯一定義を置き、docs/ はそれに統一する
4. 根拠は sources/ に保存し、改変・上書き・削除は禁止（追記のみ）
5. 検証手順は checks/ に置き、再現可能な形で残す
