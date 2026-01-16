# Part 25：統合ツール構成（VibeKanban/Continue/ローカル逃げ道・モデル選定・コスト最適化）

## 0. このPartの位置づけ
- **目的**: "滑らかに回す"補助ツール群を統合し、誰がやっても同じ品質で再現可能にする
- **依存**: [Part03](Part03.md)（AI Pack）、[Part04](Part04.md)（作業管理）、[Part21](Part21.md)（工程別AI割当）、[Part22](Part22.md)（制限耐性）、[Part23](Part23.md)（回帰防止）、[Part24](Part24.md)（可観測性）
- **影響**: 全ツール選定・統合I/F・ローカル逃げ道・モデル評価・コスト最適化

---

## 1. 目的（Purpose）

本 Part25 は **統合ツール構成** を通じて、以下を保証する：

1. **同一流儀**: IDE（Antigravity/VS Code）/CLI（Aider/Codex/Gemini/Z.ai）/CI（promptfoo/各種scan）で同じ流儀
2. **止まらない**: ローカルLLM（Ollama/LM Studio）・無料CLI（aichat/llm）・低コスト/無料枠のルーティングにより、制限で止まらない
3. **モデル選定**: 外部ランキング→自分の回帰（promptfoo）で"本当に強い"割当を固める
4. **コスト最適**: 経済モードを工程に組み込み、精度を落とさず制限も超えにくくする

**根拠**: 最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md）「4. "滑らかに回す"補助ツール群（VibeKanban中心の統合）」「5. 代用・無料CLI（制限時の"逃げ道）」「6. "モデル選定"を最も精度高くやる手順」「7. コスト最適化」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- VibeKanbanによるオーケストレーション
- Continueによる統一I/F
- ローカル逃げ道（Ollama/LM Studio/aichat/llm）
- モデル選定の手順
- コスト最適化の戦略

### Out of Scope（適用外）
- 個別ツールの詳細な使用方法（各ツールのドキュメントを参照）
- 新しいツールの評価（プロセスは本Partで定義）

---

## 3. 前提（Assumptions）

1. **Core4が役割固定**されている（Part03, Part05）
2. **VibeKanbanが司令塔**として稼働している（Part04）
3. **Part21-24** の設定が完了している
4. **ローカルLLM・無料CLI**がインストールされている（環境依存）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **VibeKanban**: [glossary/GLOSSARY.md#VIBEKANBAN](../glossary/GLOSSARY.md)（並列エージェント実行の安全装置・司令塔）
- **Continue**: [glossary/GLOSSARY.md#Continue](../glossary/GLOSSARY.md)（統一I/Fツール）
- **ローカルLLM**: Ollama/LM Studio等のローカル実行環境
- **無料CLI**: aichat/llm等の無料〜低コストCLIツール
- **モデル選定**: 外部ランキング→自分の回帰でモデルを選定するプロセス
- **コスト最適**: 経済モードの工程組み込み

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2501: VibeKanbanで固定すべきもの【MUST】

VibeKanbanは以下を固定する：

#### レーン（例）
- Spec → Research → Design → Build → Fix → Verify → Release → Operate

#### WIP制限
- Spec/Designは"未確定を積まない"
- Buildは"並列しすぎて衝突しない"

#### DoD（完了条件）を各レーンに固定
- Spec: PRD/Glossary/AC/Not-in-scope/失敗モードが機械判定可能
- Build: 実装コード/テストコード/diff/manifestが揃っている
- Verify: テスト結果/カバレッジ/回帰レポートがGreen

#### 証跡リンク（どのタスクの成果か）を必ず紐付け
- Evidenceへの参照
- タスクID（TICKET-XXX）

**根拠**: rev.md「4.1 VibeKanban（司令塔）で固定すべきもの」
**違反例**: DoD未設定でレーン運用 → 禁止。

---

### R-2502: 1タスク=1隔離の強制【MUST】

1 TICKET = 1 worktree = 1 branch = 1 Verify = 1 Evidence Pack

これで並列作業しても衝突しにくい（大規模の必須条件）。

**根拠**: rev.md「4.2 1タスク=1隔離（大規模で破綻しない基本形）」

---

### R-2503: Continueで"同一流儀"化【MUST】

以下で同一のルール/文体/出力規約に寄せる：

#### IDE（Antigravity/VS Code）
#### CLI（Aider/Codex/Gemini/Z.ai）
#### CI（promptfoo/各種scan）

**誰がやっても同じ品質**＝再現性。

**根拠**: rev.md「4.3 Continueで"同一流儀"化」

---

### R-2504: ローカルLLMは"最強"ではなく"止まらない"【MUST NOT】

ローカルは「最高精度」ではなく、**"止まらない"** と **"機密を外に出さない"** が価値。

制限時・深夜・ネット不調・閉域案件で効く。

**根拠**: rev.md「5.2 ローカル実行（完全オフライン逃げ道）」

---

### R-2505: 無料CLIの"逃げ道"としての位置づけ【MUST】

以下を入れておくと、プロバイダ変更・OpenRouter/Groq/ローカルへ逃がすのが"ワンコマンド"になる：

#### aichat: 多プロバイダ対応、REPL、RAG/ツール/エージェント機能も持てる
#### llm（simonw/llm）: CLI＋Pythonライブラリで拡張しやすい

**根拠**: rev.md「5.1 無料〜低コストで強い"汎用LLM CLI"」

---

### R-2506: モデル選定の手順【MUST】

以下の手順でモデルを選定する：

1. **外部ランキングで候補プールを作る**
   - Artificial Analysis / LLM Stats / LM Arena / Scale系 / HF Open LLM Leaderboard

2. **あなたの代表タスクを"評価セット"にする**
   - 実際のRepo・実際のバグ・実際の設計書・実際の変更

3. **promptfooで回帰試験**
   - 重要タスクは数十〜数百ケースで固定
   - スコア/判定をゲート化

4. **勝ったモデルを工程に割当**
   - Spec/Design
   - Build
   - Review
   - 雑務

**根拠**: rev.md「6. "モデル選定"を最も精度高くやる手順（リーダーボード＋自分の回帰）」

---

### R-2507: コスト最適化の戦略【SHOULD】

以下のコスト最適化を実施する：

- **高精度を使う工程を固定**: Spec / Hard Design / Review（論理）
- **軽量に落としてよい工程を固定**: 整形、候補列挙、コメント、ドキュメント体裁
- **大規模実装は"火力枠（Aider/Codex）に集中"**: 中途半端に分散するとコストも手戻りも増える

**根拠**: rev.md「7. コスト最適化」

---

### R-2508: IDE統合ツール（Watcher/Context Builder/Status Bar）【SHOULD】

「必ず入れたい.md」に基づき、以下のIDE統合ツールを実装する：

#### Watcher Script
- **機能**: ファイル保存時に `Verify` を自動実行するスクリプト
- **実行内容**:
  - Fast Verifyの自動実行
  - VRループ回数のカウント
  - Status Barへの結果表示
- **実装方法**: PowerShell 7.0+、またはNode.js

#### Context Builder
- **機能**: 作業中のタスクに合わせて `Focus Pack` を自動生成するプロンプトツール
- **入力**: タスクID（TICKET-XXX）
- **出力**: 関連するSSOT、Evidence、参照ファイルのセット
- **連携**: MCP Server経由で自動生成（Part28）

#### Status Bar
- **機能**: 「現在のモード（設計or実装）」と「VRループ残機」を表示するIDE拡張
- **表示項目**:
  - 現在のモード: 設計/実装/調査/雑務
  - VRループ残機: 「あと1回でHumanGate」
  - Context Pack状態: 生成済み/未生成/要更新
- **色分け**:
  - 緑: 問題なし（VRループ0〜1回）
  - 黄: 注意（VRループ2回）
  - 赤: 危険（VRループ3回＝HumanGate）

**根拠**: 必ず入れたい.md「Watcher Script」「Context Builder」「Status Bar」、[Part29](Part29.md)（IDE統合設計）

---

LiteLLM側で、工程タグ別budget・モデル別budget・フォールバック順を設定して「迷いを消す」ことで、結果的に精度が上がります（再現性＝精度）。

**根拠**: rev.md「7. コスト最適化（精度を落とさず、制限も超えにくくする）」

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: VibeKanbanのセットアップ
1. VibeKanbanのフォルダ構造を作成:
   ```
   VIBEKANBAN/
   ├── 000_INBOX/
   ├── 100_SPEC/
   ├── 200_BUILD/
   ├── 300_VERIFY/
   ├── 400_REPAIR/
   └── 900_RELEASE/
   ```
2. レーンを定義（Spec → Research → Design → Build → Fix → Verify → Release → Operate）
3. WIP制限を設定（Spec/Design: WIP=2, Build: WIP=1）
4. DoDを各レーンに設定
5. 証跡リンクの設定（Evidenceへの参照パス）

### 手順B: 1タスク=1隔離の実行
1. タスク（TICKET）を作成
2. worktreeを作成: `git worktree add ../worktree_<TICKET-ID> <branch>`
3. worktreeで作業を実行
4. Verifyを実行
5. Evidenceを保存
6. merge to main
7. worktreeを削除: `git worktree remove ../worktree_<TICKET-ID>`

### 手順C: Continueによる統一I/F化
1. Continueをインストール
2. 共通ルールを設定:
   - プロンプト規約
   - 作業手順
   - コンテキスト投入
   - ログ出力
3. IDE（VS Code）にContinue拡張をインストール
4. CLI（Aider/Codex/Gemini/Z.ai）にContinueを統合
5. CI（promptfoo/各種scan）にContinueを統合

### 手順D: ローカルLLMのセットアップ
1. Ollamaをインストール:
   - 公式サイトからダウンロード: https://ollama.com
   - または: `curl -fsSL https://ollama.com/install.sh -o install.sh && bash install.sh`
2. モデルをpull: `ollama pull llama3`
3. 実行確認: `ollama run llama3`
4. aichat/llmからOllamaを使用するよう設定

### 手順E: 無料CLIのセットアップ
1. aichatをインストール: `cargo install aichat`
2. llmをインストール: `pip install llm`
3. 各プロバイダのAPIキーを設定
4. 実行確認: `aichat "Hello, world!"`, `llm "Hello, world!"`

### 手順F: モデル選定の実行
1. 外部ランキングで候補プールを作成:
   - Artificial Analysis (https://artificialanalysis.ai)
   - LLM Stats (https://llm-stats.com)
   - LM Arena (https://lmarena.ai)
   - HF Open LLM Leaderboard (https://huggingface.co/spaces/lmsys/chatbot-arena-leaderboard)
2. 代表タスクを評価セットにする
3. promptfooで回帰試験を実行
4. スコア/判定をゲート化
5. 勝ったモデルを工程に割当

### 手順G: コスト最適化の実施
1. 高精度を使う工程を固定（Spec / Hard Design / Review）
2. 軽量に落としてよい工程を固定（整形、候補列挙、コメント、ドキュメント体裁）
3. 大規模実装を火力枠（Aider/Codex）に集中
4. LiteLLMで工程タグ別budget・モデル別budget・フォールバック順を設定

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: VibeKanbanが使えない環境
**対処**:
1. フォルダベースで代替（`VIBEKANBAN/` フォルダ構造）
2. 手動でWIP制限を管理
3. 環境改善を検討

**エスカレーション**: 並列実行が必須の場合、環境移行を検討。

---

### 例外2: worktreeが使えない環境
**対処**:
1. 並列禁止（WIP=1固定）
2. 順次実行（1タスクずつ完了させる）
3. 環境改善を検討

**エスカレーション**: 並列実行が必須の場合、環境移行を検討。

---

### 例外3: ローカルLLMが動かない
**対処**:
1. ハードウェア要件を確認（GPUメモリ等）
2. 軽量モデルに切り替え（llama3 → phi3）
3. aichat/llmを代替として使用

**エスカレーション**: ローカルLLMが必須の場合、環境改善を検討。

---

### 例外4: モデル選定で候補が見つからない
**対処**:
1. 外部ランキングの範囲を拡大
2. 評価セットを拡充
3. 一時的に既存モデルで継続（ADRで決定）

**エスカレーション**: 長期解決しない場合、要件の見直し。

---

### 例外5: コストオーバーが頻発
**対処**:
1. LiteLLMで予算設定を見直し
2. 高精度を使う工程を再検討
3. ローカルLLM・無料CLIへの移行を検討

**エスカレーション**: Part22（制限耐性）の見直し。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2501: VibeKanban設定の確認
**判定条件**: レーン・WIP制限・DoD・証跡リンクが設定されているか
**合否**: 未設定があれば Fail
**実行方法**: `checks/verify_vibekanban.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_vibekanban.md`

---

### V-2502: Continue統合の確認
**判定条件**: IDE/CLI/CIでContinueが統合されているか
**合否**: 未統合なら警告（Fail ではない）
**実行方法**: `checks/verify_continue.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_continue.md`

---

### V-2503: ローカルLLMの確認
**判定条件**: Ollama/LM Studioがインストールされているか
**合否**: 未インストールなら警告（Fail ではない）
**実行方法**: `checks/verify_local_llm.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_local_llm.md`

---

### V-2504: 無料CLIの確認
**判定条件**: aichat/llmがインストールされているか
**合否**: 未インストールなら警告（Fail ではない）
**実行方法**: `checks/verify_free_cli.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_free_cli.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2501: VibeKanban設定
**保存内容**: レーン定義・WIP制限・DoD・証跡リンク
**参照パス**: `VIBEKANBAN/README.md`
**保存場所**: `VIBEKANBAN/`

---

### E-2502: Continue設定
**保存内容**: 共通ルール・プロンプト規約・作業手順・コンテキスト投入・ログ出力
**参照パス**: `continue/config.yaml`
**保存場所**: `continue/`

---

### E-2503: ローカルLLM設定
**保存内容**: Ollama/LM Studioの設定・モデル名・ポート番号
**参照パス**: `local_llm/README.md`
**保存場所**: `local_llm/`

---

### E-2504: 無料CLI設定
**保存内容**: aichat/llmの設定・APIキー（環境変数）
**参照パス**: `free_cli/README.md`
**保存場所**: `free_cli/`

---

### E-2505: モデル選定記録
**保存内容**: 候補プール・評価セット・promptfoo結果・工程割当
**参照パス**: `evidence/model_selection/YYYYMMDD_model_selection.md`
**保存場所**: `evidence/model_selection/`

---

## 10. チェックリスト

- [x] 本Part25 が全12セクション（0〜12）を満たしているか
- [x] VibeKanbanで固定すべきもの（R-2501）が明記されているか
- [x] 1タスク=1隔離の強制（R-2502）が明記されているか
- [x] Continueで"同一流儀"化（R-2503）が明記されているか
- [x] ローカルLLMは"最強"ではなく"止まらない"（R-2504）が明記されているか
- [x] 無料CLIの"逃げ道"（R-2505）が明記されているか
- [x] モデル選定の手順（R-2506）が明記されているか
- [x] コスト最適化の戦略（R-2507）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-2501〜V-2504）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2501〜E-2505）が参照パス付きで記述されているか
- [ ] 本Part25 を読んだ人が「統合ツール構成」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2501: VibeKanbanの具体的なツール
**問題**: VibeKanbanを「フォルダ」「Git Issue」「外部ツール（Trello等）」のどれで実装するか未定。
**影響Part**: Part25（本Part）
**暫定対応**: フォルダベース（`VIBEKANBAN/`）で開始。運用が安定したら外部ツールへ移行を検討。

---

### U-2502: Continueの具体的な設定ファイル形式
**問題**: Continueのconfig.yamlの具体的なフォーマットが不明。
**影響Part**: Part25（本Part）
**暫定対応**: Continueの公式ドキュメントを参照。

---

### U-2503: ローカルLLMの具体的なモデル選定
**問題**: どのモデルを使うか不明（llama3/phi3/mistral等）。
**影響Part**: Part25（本Part）
**暫定対応**: 環境依存としてADRで決定。

---

### U-2504: 無料CLIの優先順位
**問題**: aichatとllmのどちらを優先するか不明。
**影響Part**: Part25（本Part）
**暫定対応**: 両方インストール・状況に応じて使い分け。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part04.md](Part04.md) : 作業管理（VIBEKANBAN）
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part22.md](Part22.md) : 制限耐性設計
- [docs/Part23.md](Part23.md) : 回帰防止設計
- [docs/Part24.md](Part24.md) : 可観測性設計

### sources/
- _imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md : 原文（「4. "滑らかに回す"補助ツール群」「5. 代用・無料CLI」「6. "モデル選定"を最も精度高くやる手順」「7. コスト最適化」）
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_vibekanban.ps1` : VibeKanban設定確認（未作成）
- `checks/verify_continue.ps1` : Continue統合確認（未作成）
- `checks/verify_local_llm.ps1` : ローカルLLM確認（未作成）
- `checks/verify_free_cli.ps1` : 無料CLI確認（未作成）

### evidence/
- `evidence/model_selection/` : モデル選定記録

### ツール公式サイト
- VibeKanban: https://github.com/example/vibe-kanban（環境依存）
- Continue: https://github.com/example/continue（環境依存）
- Ollama: https://ollama.com
- LM Studio: https://lmstudio.ai
- aichat: https://github.com/sigoden/aichat
- llm: https://github.com/simonw/llm

### 外部ランキング（モデル選定用）
- Artificial Analysis: https://artificialanalysis.ai
- LLM Stats: https://llm-stats.com
- LM Arena: https://lmarena.ai
- HF Open LLM Leaderboard: https://huggingface.co/spaces/lmsys/chatbot-arena-leaderboard

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
