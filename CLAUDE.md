# VCG/VIBE 2026 設計書SSOT（唯一の正）— Claude Code 常設ルール

## 目的
このリポジトリは「プロジェクトデータ（ファイル/会話ログ）→ 設計書（Part00-20）」へ変換し、
Verify→Evidence→Release を壊さず回すための **設計書SSOT** です。

## 破壊防止（絶対ルール）
- **docs/** が正本。**sources/** は材料であり本文ではない（改変・削除・上書き禁止）。
- 重要な断定（MUST/MUST NOT/SHOULD）は **根拠**（sources/ or evidence/ or decisions/）への参照パスを必ず付ける。
- 不明点は推測で埋めない。必ず「未決事項」に落とす。
- Part番号（00〜20）とファイル名は変更禁止（参照が破壊される）。
- 方針変更・例外許可・互換破壊は **decisions/** に ADR を追加してから本文へ反映する。
- 実行・権限に関わる手順は Part09（Permission Tier）に従う（越権禁止）。

## 出力規約（全Part共通）
- ルールは **MUST / MUST NOT / SHOULD** で記述。
- 手順は番号付きで、**人間がそのまま実行できる粒度**にする。
- 章末に必ず以下を置く：
  - チェックリスト
  - 未決事項
  - 参照（docs/sources/evidence/decisions のパス）

## 執筆順（矛盾を防ぐ推奨）
Part00 → Part01 → Part02 → Part04 → Part09 → Part10 → Part12 → Part13 → Part14 → Part11 → その他
