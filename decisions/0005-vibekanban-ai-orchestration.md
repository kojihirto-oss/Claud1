# ADR-0005: VIBEKANBAN AI Orchestration（AI運用標準とタスク単位の固定）

- 日付: 2026-01-13
- 状態: 承認
- 影響Part: Part04, Part09, Part15, Part18
- 参照: docs/Part04.md（VIBEKANBAN状態遷移）, docs/Part09.md（Permission Tier）

## 背景

AI運用において「1タスク=1worktree=1ブランチ=1PR相当=1Verify=1Evidence」の原則を明文化し、
複数AIエージェントが並列実行する際の衝突・矛盾・証跡散逸を防ぐ必要がある。

現状、VIBEKANBAN（Part04）では状態遷移とWIP制限が定義されているが、
AI運用における具体的な割当（どの工程にどのAIを使うか）と、
並列実行時の安全柵（証跡の紐付け、失敗時のフォールバック）が未定義である。

## 決定

### D-0005-1: 1タスク=1物理隔離【MUST】
- 1 TICKET = 1 worktree = 1 branch = 1 Verify = 1 Evidence Pack
- worktree命名: `worktree_TICKET-{ID}`
- branch命名: `task/TICKET-{ID}`
- 証跡保存先: `evidence/tasks/TICKET-{ID}/`

### D-0005-2: AI割当の標準（工程別）【MUST】
以下の工程別AI割当を標準とする：

| 工程 | 主AI | 副AI/補完 | 入力 | 出力 | チェック | 証跡 | フォールバック |
|------|------|----------|------|------|---------|------|---------------|
| Research | Gemini Deep Research | Z.ai(MCP経由) | SSOT/FACTS/ADR | research_inbox/ | Claude+ | evidence/research/ | 人間による文献確認 |
| Hard Design & Review | Claude+ (Sonnet/Opus) | GPT(Projects) | Research成果/FACTS | ADR/docs/ | Gemini CLI | evidence/design/ | 人間レビュー |
| Implementation Bulk | Gemini CLI / Codex | Claude+ | ADR/仕様 | 実装コード | Verify Gate | evidence/impl/ | Claude+で再実装 |
| Audit/整合性監査 | GPT(Projects) | Claude+ | docs/全体 | 監査レポート | 人間 | evidence/audit/ | Claude+で再監査 |
| Verify/Evidence | Verify Gate(自動) | - | 変更差分 | PASS/FAIL | - | evidence/verify_reports/ | 手動検証 |

### D-0005-3: 並列運用の安全基準【MUST】
- **S タスク並列2まで**: 別worktree、証跡は独立保存
- **M タスク並列1まで**: 単独実行、worktree確保
- **L タスク並列0**: 他タスク停止、単独集中
- worktree未確保での実行は禁止（衝突防止）

### D-0005-4: 失敗時フォールバック【MUST】
- Verify FAIL 3回: HumanGate（Part09）
- AI割当失敗: フォールバック列のAIで再実行
- 証跡欠落: 再実行不可、人間介入

## 選択肢

### 案A: 工程別AI固定割当（採用）
**メリット**:
- 迷いゼロ、再現性高い
- 証跡とAI選択が紐付く
- 失敗時のフォールバック明確

**デメリット**:
- AI性能差で最適解がずれる可能性

### 案B: AI自由選択（不採用）
**理由**:
- 証跡にAI選択理由が残らない
- 再現性が低い
- フォールバックが不明瞭

### 案C: 全工程Claude+のみ（不採用）
**理由**:
- ResearchはGemini Deep Researchが強い
- 実装バルクはGemini CLI/Codexが高速
- コスト過大

## 影響範囲

### 互換/移行
- 既存のVIBEKANBAN運用（Part04）と整合
- worktree命名規則の統一（U-0402解消）

### セキュリティ/権限
- AIごとにPermission Tier準拠（Part09）
- 削除系・権限境界操作はHumanGate必須

### Verify/Evidence/Release への影響
- 証跡が1タスク=1ディレクトリで整理される
- Evidence PackにAI選択履歴を含める

## 実行計画

### 手順
1. Part15.md に工程別AI割当表を追記
2. Part18.md にAI/ツール割当マトリクスを追記
3. 証跡ディレクトリ構造を `evidence/tasks/TICKET-{ID}/` に統一
4. Fast Verifyで証跡整合性を確認

### ロールバック
- ADR-0005 を廃止マークし、Part15/Part18 の追記箇所を削除
- 証跡ディレクトリは保持（監査用）

### 検証（Verify Gate）
- Fast Verify: リンク切れ、用語揺れ、Part間整合
- 証跡4点: link/parts/forbidden/sources

## 結果

（後日記入：実際にAI運用で回した結果、改善点など）
