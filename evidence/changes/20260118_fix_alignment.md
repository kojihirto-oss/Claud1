# SSOT不整合修正報告 (2026-01-18)

## 概要
Runbook, CI定義, 命名規則等の不整合を修正し、実運用とのギャップを解消しました。

## 修正内容
1. **ADR命名統一**: `ADR-U0001/4` → `0008` / `0009` にリネーム（リンク一括置換）
2. **CI定義整合**: Runbook のジョブ名を `verify-gate-windows` に訂正
3. **パス整合**: `VIBEKANBAN` → `ops/vibekanban/lanes/*` に統一し、物理ディレクトリを作成
4. **運用ルール訂正**:
   - Break-glass から環境変数記述を削除（HumanGate承認運用へ）
   - `out/` をコミット除外対象として明記（.gitignore追加）

## 検証結果
- **コマンド**: `pwsh checks/verify_repo.ps1 Fast`
- **結果**: PASS (リンク切れなし)
- **ログ**: `evidence/verify_reports/20260118_110006_*.md`

## 影響範囲
Part00, Part09, Part29, Part04, Runbook, .gitignore
