# ADR-U0001: 承認フローの定義（Approval Flow Definition）

## 1. Context（背景）

これまで「誰が」「どのタイミングで」変更を承認するか不明確であり（U-0001）、以下の問題が発生していた：
- SSOT（docs/）への変更がノーチェックでマージされるリスク
- 緊急時（Break-glass）の手順が未定義で、運用が硬直しがち
- 承認の証跡（Evidence）が分散し、監査が困難

## 2. Decision（決定事項）

承認を「マージ可能条件が満たされた状態」と定義し、Git/CIで強制する。

### 2.1 承認者の役割（Roles）

| 役割 | 担当範囲 | 権限 | 備考 |
|------|---------|------|------|
| **Owner** | docs/, decisions/, 全体方針 | 全権限 | 最終責任者 |
| **Security** | Permission Tier, secrets, 依存 | セキュリティ拒否権 | Security Check必須 |
| **Release** | release/, versioning | リリース承認権 | DoD確認必須 |
| **Agent(AI)** | 実装, Verify, Evidence作成 | 提案権（PR作成） | 承認権限なし |

### 2.2 承認プロセスとSLA

1. **通常フロー（Standard Flow）**
   - **Trigger**: PR作成
   - **Verify**: CI (Fast/Full) PASS必須
   - **Review**: Owner または担当ロールの承認（LGTM）
   - **SLA**: 24時間以内（重要変更は48時間）

2. **代理承認（Delegation）**
   - **条件**: SLA超過時、または主要承認者不在時
   - **手順**: 代理承認者（事前に `decisions/0004-humangate-approvers.md` で定義）が承認
   - **記録**: `evidence/humangate_approvals/` に「代理承認」として記録

3. **緊急承認（Break-glass）**
   - **条件**: サイトダウン、セキュリティインシデント、デッドロック
   - **手順**:
     1. 緊急承認者（Emergency）が `ALLOW_BREAK_GLASS=true` で強制実行
     2. 実行後 24時間以内に **事後ADR** を作成
     3. **Full Verify** を事後実行し、整合性を確認
   - **リスク**: SSOT不整合の可能性（事後修正必須）

### 2.3 強制点（Enforcement）

- **GitHub Branch Protection**:
  - `Require pull request reviews before merging` (Min: 1)
  - `Require status checks to pass before merging` (verify-fast, verify-full)
  - `Include administrators` (Break-glass時のみ解除可)
- **CODEOWNERS**:
  - `docs/` @owner
  - `decisions/` @owner
  - `daily-ops/` @security

## 3. Evidence（証跡要件）

承認記録は `evidence/humangate_approvals/YYYYMMDD_HHMMSS_<ticket_id>_APPROVED.md` に保存する。

**必須項目**:
```markdown
- **Ticket ID**: TICKET-XXXX
- **Timestamp**: YYYY-MM-DD HH:MM:SS
- **Approver**: @user (Role: Owner)
- **Type**: Standard / Delegation / Break-glass
- **SLA Status**: Within SLA / Over SLA
- **Diff Hash**: sha256:...
- **Comment**: 承認理由
```

## 4. Consequences（影響）

- **Positive**:
  - 変更責任が明確化される
  - 緊急時の手順（Break-glass）が確立され、運用停止を防げる
  - 監査証跡が一箇所に集約される
- **Negative**:
  - 軽微な修正でもPRと承認が必要になる（Fast Verifyで緩和）

## 5. Verification（検証）

- **V-U0001**: `checks/verify_approval_log.ps1` (未実装) でEvidence形式をチェック
- **Manual**: PRマージ時にBranch Protectionが機能しているか確認
