# ADR-0002: HumanGate・Permission Tier ガバナンス詳細

- 日付: 2026-01-11
- 状態: 承認
- 影響Part: Part09（Permission Tier）
- 参照: decisions/0001-ssot-governance.md, CLAUDE.md

## 背景
VCG/VIBE 2026プロジェクトでは、Claude CodeエージェントがSSOT（docs/）を自動編集・検証・リリースする。
破壊的操作・全域変更・リリース確定・例外処理などの高リスク操作には人間承認が必須。
Permission Tierと2段階承認フローを明確化し、誰が・いつ・何を・どの証跡に残すかを定める。

## 決定

### 1. Permission Tier 定義（MUST）

| Tier | 規模 | 対象操作 | 承認 | 記録 |
|------|------|----------|------|------|
| **S** (Small) | 単一ファイル・局所変更 | 誤字修正、コメント追加、局所的バグ修正 | 不要 | evidence/に実行ログ |
| **M** (Medium) | 複数ファイル・機能追加 | Part内容充実、新機能追加、複数Part横断変更 | Fast Verify PASS必須 | evidence/にVerify結果 |
| **L** (Large) | 破壊的・全域・リリース・例外 | Part番号変更、全域用語変更、リリース確定、ADR例外 | HumanGate（2段階承認） | decisions/ または evidence/ |

### 2. HumanGate 対象操作（MUST）

以下の操作は **必ず** HumanGate（人間承認）を通す：

1. **破壊的操作**
   - Part番号・ファイル名変更（参照破壊リスク）
   - sources/ の削除・上書き（証跡消失）
   - git force push, hard reset（履歴破壊）
   - リリース済みバージョンの改変

2. **全域変更**
   - glossary/ 用語の大規模変更（全Part影響）
   - フォルダ構造変更（docs/, decisions/, evidence/）
   - テンプレート・規約変更（全Part書式影響）

3. **リリース確定**
   - Part xx を「確定版」としてタグ付け
   - 外部公開・配布・APIリリース
   - バージョン番号確定（v1.0.0など）

4. **例外・ポリシー変更**
   - ADR-0001, ADR-0002 自体の変更
   - CLAUDE.md ルール変更
   - Verify条件の緩和・スキップ

### 3. 2段階承認フロー（MUST）

```
[提案] → [レビュー] → [承認] → [実行] → [記録]
```

#### 3.1 提案フェーズ
- **誰が**: Claude Code エージェント または 人間
- **何を**: decisions/ に提案ADR追加（状態: 提案）
- **証跡**: decisions/XXXX-proposal-yyyymmdd.md

#### 3.2 レビューフェーズ
- **誰が**: 人間レビュアー（開発者・PM・セキュリティ担当）
- **何を**: ADRレビュー、影響範囲確認、代替案検討
- **証跡**: ADR内にレビューコメント追記 or evidence/review-XXXX.md

#### 3.3 承認フェーズ
- **誰が**: 承認者（プロジェクトオーナー・テックリード）
- **何を**: ADRステータスを「承認」に変更、承認日時・承認者記録
- **証跡**: ADRヘッダーに「承認日時」「承認者」追記

#### 3.4 実行フェーズ
- **誰が**: Claude Code エージェント
- **何を**: 承認されたADRに従ってdocs/変更、Fast Verify実行
- **証跡**: evidence/execution-XXXX-yyyymmdd.log

#### 3.5 記録フェーズ
- **誰が**: Claude Code エージェント
- **何を**: ADRに「結果」セクション追記、Verify証跡リンク
- **証跡**: ADR最終版 + evidence/ 実行ログ

### 4. 緊急時 事後承認（SHOULD）

**緊急事態**（本番障害・セキュリティインシデント）では、事前承認なしで実行可能。
ただし **24時間以内** に事後承認記録を残す（MUST）。

#### 4.1 緊急実行
- 実行前に `evidence/emergency-YYYYMMDD-HHMM.md` 作成
- 記載内容: 発生日時、緊急理由、実行操作、影響範囲、実行者
- 実行後即座にコミット

#### 4.2 事後承認
- 24時間以内に decisions/ に事後承認ADR追加
- ステータス: 「緊急承認（事後）」
- レビュアー・承認者の追認署名を取得
- 再発防止策を「結果」セクションに記載

### 5. HumanGate 記録の置き場所（MUST）

| 記録種別 | 保管場所 | ファイル名規約 | 保持期間 |
|---------|---------|----------------|----------|
| 提案ADR | decisions/ | XXXX-proposal-description.md | 永続 |
| 承認ADR | decisions/ | XXXX-approved-description.md | 永続 |
| レビュー記録 | evidence/ | review-XXXX-YYYYMMDD.md | 永続 |
| 実行ログ | evidence/ | execution-XXXX-YYYYMMDD.log | 永続 |
| 緊急対応 | evidence/ | emergency-YYYYMMDD-HHMM.md | 永続 |
| Verify証跡 | evidence/ | verify-partXX-YYYYMMDD.log | 永続 |

## 選択肢

### 案A（採用）：3-Tier（S/M/L）+ HumanGate
- メリット: 明確な境界、Fast Verify活用、緊急対応可能
- デメリット: 初期学習コスト、ADR作成コスト

### 案B（不採用）：全操作HumanGate必須
- メリット: 最高安全性
- デメリット: 開発速度激減、Claude Code自律性喪失

### 案C（不採用）：全自動（承認なし）
- メリット: 開発速度最大
- デメリット: 破壊的変更リスク、監査不可

## 影響範囲

### 互換/移行
- 既存Part（00-20）に影響なし（新規ルール追加のみ）
- Part09にPermission Tier一覧を追記

### セキュリティ/権限
- L Tier操作は2段階承認必須（リスク低減）
- 緊急時も事後記録必須（監査可能性維持）

### Verify/Evidence/Release への影響
- M Tier以上はFast Verify PASS必須
- L TierはHumanGate + Verify証跡4点収集
- Release確定操作は必ずL Tier扱い

## 実行計画

### 手順
1. ADR-0002作成（本文書）
2. Part09にPermission Tier詳細・HumanGateルール追記
3. Fast Verify実行、PASS証跡4点収集
4. コミット（メッセージ: "Align Part09 with ADR-0002: HumanGate governance"）
5. プッシュ（branch: claude/align-part09-governance-Ig0Vr）

### ロールバック
- git revert 可能（ADR-0002削除、Part09を前版に戻す）
- 影響範囲: Part09のみ（他Partへの依存なし）

### 検証（Verify Gate）
- Fast Verify実行、以下4点を evidence/ に保存：
  1. Part09構造チェック（全セクション存在）
  2. MUST/MUST NOT/SHOULD記法チェック
  3. 参照パス有効性チェック（decisions/0002存在）
  4. 未決事項チェック（推測禁止違反なし）

## 結果
（2026-01-11実行完了）
- Fast Verify結果: **PASS (4/4)**
  - ① Part構造チェック: PASS（13セクション検出）
  - ② MUST記法チェック: PASS（25箇所検出）
  - ③ 参照パス有効性: PASS（decisions/0002存在確認）
  - ④ 未決事項チェック: PASS（推測表現なし）
- 発見事項: なし
- 改善提案:
  - checks/fast-verify.sh 自動化スクリプト作成（次回ADR候補）
  - Part02（用語集）作成後、Part09の用語定義を移動
  - Part08（Verify詳細）作成後、Fast Verify仕様を参照に変更
- 証跡:
  - evidence/verify-part09-20260111.log (Fast Verify証跡)
  - evidence/execution-0002-20260111.log (実行ログ)
- コミットハッシュ: 5968188
