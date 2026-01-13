# Part 18：Operation Registry／司令塔UI（“押すボタン”体系・Busy/NextStep・状態遷移）

## 0. このPartの位置づけ
- 目的：Operation Registry（司令塔UI）の運用を固定し、状態遷移と次アクションを迷いなく実行できるようにする
- 依存：Part00（SSOT憲法）、Part04（作業管理）、Part06（IDE/司令塔運用）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：作業の状態遷移、次アクションの指示、監査用の記録整合

## 1. 目的（Purpose）
Operation Registry（司令塔UI）の表示と更新手順を標準化し、  
Busy/NextStep と状態遷移を運用ループに沿って固定する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- Operation Registry の更新と参照
- Busy/NextStep の記録と表示
- 状態遷移（READY/DOING/VERIFYING/REPAIRING/DONE/BLOCKED）
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- UI実装の詳細（別Part）
- 組織固有の画面デザイン方針

## 3. 前提（Assumptions）
1. 司令塔UIは作業の指示と確認の場である
2. VIBEKANBANの状態遷移は Part04 に従う
3. Permission Tierは Part09 に従う
4. Verify/Evidenceは Part00/Part10/Part12 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Operation Registry**: 司令塔UIの操作一覧・現在状態・次アクションの記録
- **Busy**: 実行中タスクの要約
- **NextStep**: 次に行うべき最短手順
- **状態遷移**: READY/DOING/VERIFYING/REPAIRING/DONE/BLOCKED の移行

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1801: 状態遷移の順守【MUST】
状態遷移は Part04 の定義に従い、飛ばしや戻しを行わない。

### R-1802: Busy/NextStepの明示【MUST】
現在の作業状況（Busy）と次アクション（NextStep）を必ず記録する。

### R-1803: 運用ループの順守【MUST】
Operation Registryの更新は「発見 → 記録 → 修正 → 検証 → 監査」で実施する。

### R-1804: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-1805: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-1806: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

### R-1816: Gemini MCP Scope【MUST】
**根拠**: [F-0072](../docs/FACTS_LEDGER.md#F-0072)
Gemini CLIのMCP設定は、個人実験用 (`user`) とプロジェクト共有用 (`project`) のスコープを明確に分離し、共有設定には機密情報を含めない。


## 6. 手順（実行可能な粒度、番号付き）
1. 発見：Operation Registryの不足・不整合・状態遷移の誤りを特定する。
2. 記録：発見内容、参照根拠、対象ファイル、保存先を記録する。
3. 修正：最小差分で更新し、Busy/NextStep を明示する。sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link/parts/forbidden/sources）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、状態遷移の整合を確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 手順2: AI/ツール割当マトリクス（工程別最適AI選択）

### R-1807: 完全版AI割当マトリクス【MUST】

以下の工程別AI割当を標準とする（根拠: [ADR-0005](../decisions/0005-vibekanban-ai-orchestration.md)）。

| 工程 | 主AI | 副AI/補完 | 入力 | 出力 | チェック | 証跡 | フォールバック | Permission Tier |
|------|------|----------|------|------|---------|------|---------------|----------------|
| **Research** | Gemini Deep Research | Z.ai (MCP経由) | SSOT/FACTS/ADR | research_inbox/ | Claude+ | evidence/research/ | 人間による文献確認 | ReadOnly |
| **Hard Design & Review** | Claude+ (Sonnet/Opus) | GPT(Projects) | Research成果/FACTS | ADR/docs/ | Gemini CLI | evidence/design/ | 人間レビュー | PatchOnly |
| **Implementation Bulk** | Gemini CLI / Codex | Claude+ | ADR/仕様 | 実装コード | Verify Gate | evidence/impl/ | Claude+で再実装 | ExecLimited |
| **Audit/整合性監査** | GPT(Projects) | Claude+ | docs/全体 | 監査レポート | 人間 | evidence/audit/ | Claude+で再監査 | ReadOnly |
| **Verify/Evidence** | Verify Gate(自動) | - | 変更差分 | PASS/FAIL | - | evidence/verify_reports/ | 手動検証 | ExecLimited |

#### MCP vs RAG の使い分け（根拠: [ADR-0007](../decisions/0007-mcp-rag-boundary.md)）

| 観点 | MCP（推奨） | RAG（推奨） |
|------|-----------|-----------|
| **データ種別** | 構造化データ（JSON/YAML/コード） | 非構造化データ（Markdown/PDF/長文） |
| **更新頻度** | 高頻度（リアルタイム） | 低頻度（日次～週次更新） |
| **参照パターン** | ピンポイント取得（特定ファイル） | あいまい検索（キーワード/意図） |
| **データ所在** | ローカルファイルシステム | インデックス化済みKB |
| **鮮度要件** | 最新必須 | 多少の遅延OK |

**判断フロー**:
1. 「特定ファイルパスがわかっている」→ **MCP Read-only**
2. 「キーワードで探したい」→ **RAG検索**
3. 「sources/を参照したい」→ **MCPでRead-only** （RAG化禁止）
4. 「docs/を検索したい」→ **RAG検索** （更新済み前提）

### 手順3: VIBEKANBAN並列運用標準（1タスク=1worktree=1Verify=1Evidence）

### R-1808: 並列運用の安全基準【MUST】

根拠: [ADR-0005](../decisions/0005-vibekanban-ai-orchestration.md) D-0005-3, [F-0070](../docs/FACTS_LEDGER.md#F-0070)

- **S タスク並列2まで**: 別worktree、証跡は独立保存
- **M タスク並列1まで**: 単独実行、worktree確保
- **L タスク並列0**: 他タスク停止、単独集中

### R-1809: 1タスク=1物理隔離の原則【MUST】

根拠: [ADR-0005](../decisions/0005-vibekanban-ai-orchestration.md) D-0005-1

- 1 TICKET = 1 worktree = 1 branch = 1 Verify = 1 Evidence Pack
- worktree命名: `worktree_TICKET-{ID}`
- branch命名: `task/TICKET-{ID}`
- 証跡保存先: `evidence/tasks/TICKET-{ID}/`

### R-1810: 失敗時フォールバック【MUST】

根拠: [ADR-0005](../decisions/0005-vibekanban-ai-orchestration.md) D-0005-4

1. **主AI失敗時**: フォールバック列のAIで再実行
2. **副AI失敗時**: 人間介入（HumanGate）
3. **Verify FAIL 3回**: 即座にHumanGate（Part09）

### 手順4: Antigravity安全柵（司令塔の権限境界）

### R-1811: Antigravityの役割限定【MUST】

根拠: [ADR-0006](../decisions/0006-antigravity-safety-rails.md) D-0006-1, [F-0073](../docs/FACTS_LEDGER.md#F-0073)

Antigravity（IDE/司令塔）は以下の役割に限定する：

1. **司令塔**: TICKET作成、AI割当指示、進捗確認
2. **レビュー**: diff確認、Evidence確認、DoD確認
3. **確認**: Verify結果、状態遷移、証跡整合性

**禁止**: 直接のファイル編集・削除・一括置換・git操作（commit/push以外）

### R-1812: 削除系操作の安全柵【MUST】

根拠: [ADR-0006](../decisions/0006-antigravity-safety-rails.md) D-0006-2

以下の削除系操作は **HumanGate必須**：

- `rm -r`, `rm (recursive+force)` （ファイル・ディレクトリ削除）
- `git clean -fdx` （未追跡ファイル削除）
- sources/ 内の任意の変更・削除
- decisions/ 内のADR削除
- evidence/ 内の証跡削除
- worktree削除（`git worktree remove`）

**例外**:
- 一時ファイル削除（`*.tmp`, `*.log`）はPatchOnly Tierで可
- 削除前にDry-run表示必須（影響範囲確認）

### R-1813: 作業ディレクトリ固定【MUST】

根拠: [ADR-0006](../decisions/0006-antigravity-safety-rails.md) D-0006-3

AIエージェント実行時は以下のディレクトリ固定を強制：

- **worktree内限定**: `worktree_TICKET-{ID}/` 配下のみ操作可
- **読み取り専用**: `docs/`, `sources/`, `decisions/`, `glossary/` （変更不可）
- **書き込み可**: `evidence/tasks/TICKET-{ID}/` （証跡保存専用）

**検証**: Fast Verifyで `sources/` 無改変確認（V-0004）

### R-1814: Permission Tier強制【MUST】

根拠: [ADR-0006](../decisions/0006-antigravity-safety-rails.md) D-0006-4

Antigravity経由のAI実行は以下のTier制限を強制：

| 操作種別 | 必要Tier | 確認方法 |
|---------|---------|---------|
| ファイル読み取り | ReadOnly | なし |
| docs/編集（最小差分） | PatchOnly | Dry-run表示 |
| Verify実行 | ExecLimited | 実行前確認 |
| 削除・sources改変・ADR追加 | HumanGate | 明示的承認 |

### R-1815: 緊急停止（Emergency Stop）【MUST】

根拠: [ADR-0006](../decisions/0006-antigravity-safety-rails.md) D-0006-5

以下の検出時は **即座に操作停止**：

- sources/ への改変検出（V-0004 FAIL）
- Permission Tier超過の実行試行
- worktree外への書き込み試行
- 禁止コマンド検出（V-0003 FAIL）

**復旧**:
1. 操作ログをevidence/emergency/に保存
2. HumanGateで原因確認
3. Rollback実行

### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 状態遷移が破綻
- 直前の変更を取り消し、状態遷移の根拠を再確認して再検証する。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1801: Operation Registry更新の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1～3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-1802: Part00 Verify要件との整合
**判定条件**:
1. V-0001～V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1801: Operation Registry記録
**内容**: Busy/NextStep、状態遷移、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-1802: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-1803: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] Busy/NextStep と状態遷移が記録されている


## 11. 未決事項（推測禁止）
- 未決事項なし（現時点）

## 12. 参照（パス）
- docs/
- sources/
- evidence/
- decisions/
### docs/
- [Part00](./Part00.md) : SSOT憲法
- [Part02](./Part02.md) : 用語・表記
- [Part04](./Part04.md) : 作業管理（状態遷移）
- [Part06](./Part06.md) : IDE/司令塔運用
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
