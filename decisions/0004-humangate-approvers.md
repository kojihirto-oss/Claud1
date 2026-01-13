# ADR-0004: HumanGate承認者と承認SLAの定義

- 日付: 2026-01-12
- 状態: 提案
- 影響Part: Part09, Part14
- 参照: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md

## 背景
HumanGateの承認者と承認SLAが未定義だと、変更が停止し、緊急時の判断が滞留する。

## 決定
HumanGateの承認者は「主要・代理・緊急」の3系統で定義し、SLAを明確化する。

### 承認者（役割）
- **主要承認者**: Repository Owner（またはSSOT運用責任者）
- **代理承認者**: 主要承認者が不在の場合に承認できる担当
- **緊急承認者**: 緊急対応時に即時承認できる担当（任意）

### 承認者の実名/Team（運用台帳）
| 役割 | 実名 | Team | 連絡手段 | 代替 |
| --- | --- | --- | --- | --- |
| 主要承認者 | koji2 | SSOT | GitHub Review / Chat | 代理承認者 |
| 代理承認者 | TBD | SSOT | GitHub Review / Chat | 主要承認者 |
| 緊急承認者 | TBD | On-Call | Phone / Chat | 代理承認者 |

### 承認SLA
- 通常変更: 24時間以内
- 重要変更: 48時間以内
- 緊急変更: 2時間以内
- SLA超過時: 自動エスカレーション（代理→緊急の順）

### 承認チャネル
- 通常: GitHub PR Review の Approve
- 緊急: Issue/Chatでの「LGTM + 口頭/チャット確認」 + 証跡記録

### 管理方法
- 承認者の変更は ADR-0004 を更新し、evidence/humangate_approvals/ に記録
- 承認者の実名/Team は月次で棚卸し（在籍/役割/連絡手段の確認）
- TBD は運用開始前に必ず埋める（未記入のまま運用開始しない）

## 選択肢
1) **役割ベース定義（採用）**: 実名は別途運用で管理し、役割とSLAを固定
2) 実名固定: 早期は明確だが、交代時に更新漏れリスク
3) 承認なし: 運用停止や事故リスクが高いため採用しない

## 影響範囲
- **互換/移行**: 既存のHumanGate手順に承認者とSLAを追加
- **セキュリティ/権限**: 承認者の責任範囲を明確化
- **Verify/Evidence/Release**: 承認ログを evidence/humangate_approvals/ に保存

## 実行計画
- Part09 に承認者/承認チャネル/SLAを反映
- decisions/README.md の承認フロー参照を更新
- evidence/ に承認ログのテンプレを用意（必要時）

## 結果
（後日記入）
