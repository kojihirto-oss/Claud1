# 変更要約 (2026-01-12)

## 変更ファイル
- docs/Part14.md（V-1410拡充、Markdown崩れ修正）
- decisions/0004-humangate-approvers.md（承認者実名/Team/管理方法）
- .github/CODEOWNERS（Code Owners追加）
- .github/workflows/verify.yml（Verify Gate CI）
- docs/Part09.md（HumanGate承認者/SLA/証跡命名）
- decisions/0004-humangate-approvers.md（承認者の役割・SLA定義）
- decisions/README.md（承認フロー参照を更新）
- docs/Part10.md（Verify証跡命名/保持、CI強制）
- docs/Part12.md（Evidence規格/保持ポリシー）
- docs/Part14.md（CI強制ルール、V/E追加、未決整理）
- docs/Part15.md（工程別Runbook追加）
- docs/Part16.md（RAG更新プロトコル追加）
- docs/FACTS_LEDGER.md（F/D/U追記）

## 主な変更
- V-1410の判定を「Required checks とPR Checks上の verify-gate-windows 確認」に変更
- HumanGate承認者の実名/Team/管理方法をADRに追記
- CODEOWNERSでSSOT関連パスの承認者を固定
- GitHub ActionsでVerify Gateを強制（PRで必須、pushはmain以外）
- verify_repo.ps1（Fast）をWindows runnerで実行、verify_reportsをartifact化
- HumanGate承認者の役割、SLA、承認チャネル、証跡保存先を定義
- Verify/Evidenceの命名規則を `.md` に統一し、直近3セット保持＋アーカイブに統一
- CIによるVerify Gate強制をルール化し、検証ログのEvidenceを追加
- RAG更新のトリガと証跡ログを明文化
- 「Deep Research→一次情報(MCP)→Facts→設計書差分→Verify→Evidence→Release」の工程別Runbookを追記
- FACTS_LEDGERに監査由来の事実・決定・未決を追記
