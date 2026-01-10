# CHANGELOG

All notable changes to VCG/VIBE 2026 設計書SSOT will be documented in this file.

The format is based on Part14 (変更管理) R-1403 specification.

## 2026-01-10

### Added
- **[Part03]** AI Pack（Core4/Antigravity/MCP）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: 0dd189d
- **[Part14]** 変更管理（PATCHSET/RFC/ADR・例外ルート・互換/移行・凍結解除ルール）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: ac73628
- **[Part11]** Repair（VRループ）運用（失敗分類・収束戦略・ループ制限）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (pending)
- **[CHANGELOG]** CHANGELOGファイルを作成（Part14 R-1403に準拠）
  - 担当: Claude Code
  - Commit: ac73628

### Fixed
- **[Part03]** L146の禁止コマンド例をバッククオートで囲み、Verify除外対象に修正
  - 担当: Claude Code
  - Commit: ac73628
- **[Part10]** Verify Gate の V-0901 でバッククオート内の禁止コマンドを除外
  - 担当: Claude Code
  - Commit: b375057
- **[FACTS_LEDGER]** L542の禁止コマンドをバッククオートで囲み、Verify除外対象に修正
  - 担当: Claude Code
  - Commit: 3900371

## 2026-01-09

### Added
- **[Part00]** SSOT憲法（真実順序・ADR→docs workflow）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (initial)
- **[Part01]** プロジェクトゴール・DoD・失敗定義を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (initial)
- **[Part02]** 用語管理（GLOSSARY統一）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (initial)
- **[Part04]** ワーク管理（TICKET・VIBEKANBAN・WIP制限）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (initial)
- **[Part09]** Permission Tier（ReadOnly/PatchOnly/ExecLimited/HumanGate）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (initial)
- **[Part10]** Verify Gate（Fast/Full・VRループ）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: (initial)
- **[FACTS_LEDGER]** F-0001〜F-0062（確定事実）、U-0001〜U-0010（未決事項）を追加
  - 担当: Claude Code
  - Commit: (initial)
- **[glossary/GLOSSARY]** 18用語を追加（SSOT/Verify/Evidence/VIBEKANBAN等）
  - 担当: Claude Code
  - Commit: (initial)
- **[checks/verify_repo.sh]** V-0001〜V-0004（リンク整合性・Part存在・禁止コマンド・sources整合性）を追加
  - 担当: Claude Code
  - Commit: (initial)
- **[checks/verify_repo.ps1]** Windows版検証スクリプトを追加
  - 担当: Claude Code
  - Commit: 3900371
- **[ADR-0001]** SSOT運用ガバナンス（変更手順・根拠・検証の統治）を追加
  - 担当: Claude Code
  - 状態: 承認
  - Commit: (initial)
