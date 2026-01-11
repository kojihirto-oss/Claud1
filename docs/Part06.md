# Part 06：IDE/司令塔運用（ツール役割分担・切替条件・コストガード）

## 0. このPartの位置づけ
- **目的**: 複数のAIツール（Claude Code/Gemini CLI/Codex CLI/GPT Plus/MCP/Vibe Kanban）の役割分担と切替条件を明確化し、迷いゼロでツール選択できる運用ルールを確立する
- **依存**: Part02（用語集）、Part09（Permission Tier）、FACTS_LEDGER（ツール情報）
- **影響**: Part10（Version/Verify）、Part12（Evidence収集）、Part13（Changelog）、Part14（Release/Deploy）

## 1. 目的（Purpose）

複数のAIツールを適切に使い分け、タスク特性（サイズ/精度/コスト/並列性/納期）に応じた最適なツール選択を「機械判定可能」な基準で定義する。

## 2. 適用範囲（Scope / Out of Scope）

### Scope
- ツール役割分担マトリクス（得意/不得意/禁止用途）
- タスクサイズ別切替条件（S/M/L）
- コストガード（MCP Web Search等の課金操作）
- Evidence収集義務（外部情報取得時の証跡保存）

### Out of Scope
- 各ツールの内部仕様・アルゴリズム
- ツールのインストール・初期設定手順（環境構築ドキュメント参照）
- 個別ツールのバージョン管理ポリシー

## 3. 前提（Assumptions）

- 全ツールが最新安定版で動作している
- `docs/` が設計書SSOT、`sources/` は改変禁止材料である
- Permission Tier（Part09）に従い、越権操作は禁止
- 外部情報取得時は必ず `evidence/research/` に証跡を残す

## 4. 用語（Glossary参照：Part02）

- **Claude Code**: Anthropic社のコーディングAIアシスタント（高精度・設計書編集得意）
- **Gemini CLI**: Google製CLI（大量ファイル処理・並列実行得意）
- **Codex CLI**: OpenAI Codex CLI（コード生成・補完得意）
- **GPT Plus**: ChatGPT Plus（質疑応答・整理・ブレスト得意）
- **MCP (Model Context Protocol)**: Z.AI等のツール（Web Search等の外部情報取得）
- **Vibe Kanban**: AI agents orchestration platform（worktree隔離・並列タスク管理）

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 ツール選択の絶対ルール

1. **MUST**: タスク開始前に「ツール役割マトリクス」と「切替条件」を確認する
2. **MUST**: 外部情報取得（MCP Web Search等）時は `evidence/research/YYYYMMDD_<topic>.md` に証跡を保存する
3. **MUST**: 証跡には「取得日、出典URL、取得方法、引用原文、要再確認頻度」を必ず含める
4. **MUST NOT**: 価格/無料/無制限等の断言を根拠なく記載しない（未決事項に送る）
5. **MUST NOT**: `sources/` の改変・削除・上書き（全ツール共通禁止）
6. **SHOULD**: 失敗時は「失敗時切替先」に従い、同一ツールで再試行しない

### 5.2 コストガード

1. **MUST**: MCP Web Search使用前に「何を検索するか」を明記し、承認を得る（HumanGate未決→ADR化待ち）
2. **MUST**: Z.AI Web Searchは $0.01/use であることを認識し、無制限実行を避ける（根拠: `evidence/research/20260111_zai_pricing.md`）
3. **SHOULD**: 課金操作のログを `evidence/cost_logs/YYYYMMDD_<tool>.log` に記録する

### 5.3 Evidence収集義務

1. **MUST**: 外部情報を FACTS_LEDGER に反映する際は「出典URL + 確認日」が揃ったもののみ許可
2. **MUST**: 変動しうる情報（価格/機能/対応言語等）は「要再確認頻度」を明記する
3. **MUST NOT**: 推測・予測・期待で事実を補完しない（未決事項に送る）

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 タスク開始時のツール選択手順

1. タスクのサイズ（S/M/L）を判定する（後述「6.2 切替条件」参照）
2. 「ツール役割マトリクス」（後述「6.3」）から候補ツールを抽出する
3. 精度要求・コスト上限・納期を確認し、最適ツールを選択する
4. 選択理由を作業ログまたはコミットメッセージに残す

### 6.2 切替条件（タスクサイズ別）

#### S（Small）タスク
- **定義**: 単一ファイル編集、3ファイル以内の小規模修正、質疑応答
- **推奨ツール**: Claude Code（高精度）、GPT Plus（質疑応答）
- **納期**: 即座～数分
- **コスト上限**: 制限なし（通常プラン内）

#### M（Medium）タスク
- **定義**: 5～20ファイルの編集、新機能追加、リファクタリング
- **推奨ツール**: Claude Code（設計書編集）、Gemini CLI（並列処理）、Vibe Kanban（複数Agent並列）
- **納期**: 数十分～数時間
- **コスト上限**: Web Search 10回/タスクまで

#### L（Large）タスク
- **定義**: 全体リファクタ、大量ファイル処理（50+ファイル）、並列実行必須
- **推奨ツール**: Gemini CLI（大量ファイル）、Vibe Kanban（Agent並列）
- **納期**: 数時間～数日
- **コスト上限**: 要事前承認（HumanGate ADR待ち）

### 6.3 ツール役割マトリクス

| ツール | 得意 | 不得意 | 推奨用途 | 禁止用途 | 失敗時切替先 |
|--------|------|--------|----------|----------|--------------|
| **Claude Code** | 高精度編集、設計書本文、複雑ロジック | 大量ファイル並列処理、ブレスト | docs/ Part編集、重要ファイル修正 | sources/ 改変、大量自動生成 | Gemini CLI（並列）、GPT Plus（質疑） |
| **Gemini CLI** | 大量ファイル処理、並列実行、検索 | 精密な設計書編集、複雑判断 | 全ファイル検索、一括置換、並列タスク | docs/ Part本文編集、決定事項変更 | Claude Code（精度要）、Vibe Kanban（並列管理） |
| **Codex CLI** | コード生成、補完、定型処理 | 設計書執筆、複雑な文脈理解 | ボイラープレート生成、テンプレ作成 | docs/ 編集、ADR作成 | Claude Code（設計書）、Gemini CLI（大量） |
| **GPT Plus** | 質疑応答、整理、ブレスト、要約 | コード直接編集、ファイル操作 | 未決事項整理、ADR下書き、方針検討 | 本番ファイル編集、自動コミット | Claude Code（編集実行）、記録係に徹する |
| **MCP (Z.AI等)** | Web Search、外部情報取得 | ローカルファイル編集 | 価格調査、ドキュメント取得 | 無制限検索、未承認の課金操作 | 手動検索（コスト超過時） |
| **Vibe Kanban** | Agent並列管理、worktree隔離、タスク可視化 | 単一Agent高精度作業 | 複数タスク並列、ブランチ分離作業 | 単一ファイル精密編集 | Claude Code（単一精密）、手動git操作 |

**根拠**:
- Vibe Kanban機能: `evidence/research/20260111_vibekanban_docs.md`
- Z.AI Web Search価格: `evidence/research/20260111_zai_pricing.md`

### 6.4 外部情報取得時の手順（MCP等）

1. 検索目的・キーワードを明記する
2. MCP Web Searchを実行する（Z.AI: $0.01/use）
3. 取得結果を `evidence/research/YYYYMMDD_<topic>.md` に保存する
   - 取得日、出典URL、取得方法、引用原文、要再確認頻度を含む
4. FACTS_LEDGERへの反映は「出典URL + 確認日」が揃った後に行う
5. 価格/機能等の変動しうる情報は「要再確認頻度」を必ず明記する

### 6.5 失敗時のエスカレーション

1. ツールがタスクに適さないと判断した場合、「失敗時切替先」に従う
2. 切替先でも失敗した場合、HumanGateにエスカレーション（ADR化待ち）
3. 同一ツールで3回以上失敗した場合、タスク定義を見直す（Part01/Part04参照）

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 ツール選択ミス
- **検出**: タスク途中でツール不適合を検知（例：Claude Codeで大量ファイル処理→遅延）
- **復旧**: 「失敗時切替先」に従い、作業途中データを保存してツール切替
- **エスカレーション**: 切替先でも失敗→HumanGate

### 7.2 コスト超過
- **検出**: MCP Web Search 10回超過（Mタスク上限）
- **復旧**: 手動検索に切替、または承認申請
- **エスカレーション**: Lタスク相当→事前承認必須（ADR未定）

### 7.3 Evidence記録漏れ
- **検出**: 外部情報を参照したがevidence/research/に証跡なし
- **復旧**: 即座に証跡を作成し、コミットに追加
- **エスカレーション**: 記録漏れ3回→作業プロセス見直し

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 Verify項目

1. **ツール選択根拠の記録**: コミットメッセージに選択理由が記載されているか（SHOULD）
2. **Evidence存在確認**: MCP等で外部情報取得時、`evidence/research/YYYYMMDD_*.md` が存在するか（MUST）
3. **FACTS_LEDGER整合性**: FACTS_LEDGERに記載された事実に「出典URL + 確認日」があるか（MUST）
4. **sources/ 改変禁止**: `git diff sources/` で差分がないか（MUST）

### 8.2 判定基準

- **PASS**: 上記MUST項目すべて満たす
- **WARN**: SHOULD項目のみ未達
- **FAIL**: MUST項目1つでも未達

### 8.3 ログ出力

- 検証結果を `evidence/verify_reports/YYYYMMDD_HHMMSS_fast.log` に保存

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 必須証跡

1. **外部情報取得ログ**: `evidence/research/YYYYMMDD_<topic>.md`（取得日、出典URL、引用原文、要再確認頻度）
2. **コスト発生ログ**: `evidence/cost_logs/YYYYMMDD_<tool>.log`（未実装→未決事項）
3. **ツール切替履歴**: コミットメッセージまたは作業ログに記録
4. **Verify結果**: `evidence/verify_reports/` 配下（最新PASS 1セット保持）

### 9.2 参照パス

- `evidence/research/20260111_vibekanban_docs.md`（Vibe Kanban機能）
- `evidence/research/20260111_zai_pricing.md`（Z.AI価格）
- `docs/Part02.md`（用語集）
- `docs/Part09.md`（Permission Tier）
- `docs/FACTS_LEDGER.md`（確定情報台帳）

## 10. チェックリスト

- [ ] タスク開始前に「ツール役割マトリクス」を確認したか
- [ ] タスクサイズ（S/M/L）を判定し、推奨ツールを選択したか
- [ ] 外部情報取得時に `evidence/research/` に証跡を保存したか
- [ ] 証跡に「取得日、出典URL、引用原文、要再確認頻度」が含まれているか
- [ ] MCP Web Searchの課金を認識し、10回/タスク上限を守ったか
- [ ] FACTS_LEDGERへの反映時に「出典URL + 確認日」を確認したか
- [ ] `sources/` の改変・削除・上書きを行っていないか
- [ ] 失敗時に「失敗時切替先」に従ったか
- [ ] Verify（Fast）を実行し、PASSを確認したか

## 11. 未決事項（推測禁止）

- **HumanGate定義**: 最終裁定者・承認フロー・権限範囲（ADR化待ち）
- **コスト承認プロセス**: Lタスクの事前承認基準・上限額（ADR化待ち）
- **コストログ保存先**: `evidence/cost_logs/` の命名規則・保持期間（ADR化待ち）
- **Verify自動化**: CI/CD統合の優先度・実装時期（Part10依存）
- **RAGベクトルDB保存先**: `rag/` or `.rag/` および `.gitignore` 方針（ADR化待ち）
- **Evidence/verify_reports採用ルール**: 最新PASS 1セット保持 or 全履歴保持（ADR化待ち）

## 12. 参照（パス）

### docs/
- `docs/Part02.md`（用語集）
- `docs/Part09.md`（Permission Tier）
- `docs/Part10.md`（Version/Verify）
- `docs/Part12.md`（Evidence収集）
- `docs/FACTS_LEDGER.md`（確定情報台帳）

### sources/
- （該当なし：ツール選択ルールはdocs/が正本）

### evidence/
- `evidence/research/20260111_vibekanban_docs.md`（Vibe Kanban機能調査）
- `evidence/research/20260111_zai_pricing.md`（Z.AI価格調査）
- `evidence/verify_reports/`（Verify結果ログ）

### decisions/
- （ADR化待ち：HumanGate、コスト承認、RAG保存先、Verify_reports採用ルール）
