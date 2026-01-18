# Part 30：エージェント協調モデル（Core4連携・HITL・フォールバック）

## 0. このPartの位置づけ
- **目的**: 複数AIエージェント（Core4）の連携・Human-in-the-Loop（HITL）・フォールバックの標準モデルを定義する
- **依存**: [Part03](Part03.md)（AI Pack）、[Part21](Part21.md)（工程別AI割当）、[Part22](Part22.md)（制限耐性）
- **影響**: 全AI連携・エージェント暴走防止・制限耐性

---

## 1. 目的（Purpose）

本 Part30 は **エージェント協調モデルの標準化** を通じて、以下を保証する：

1. **役割固定**: 各AI（ChatGPT/Claude/Gemini/Z.ai）の役割を明確に分離
2. **HITL制御**: 重要決定で人間による承認を必須化
3. **フォールバック**: 制限・障害時に自動迂回
4. **暴走防止**: エージェントの無限ループ・誤操作を防止

**根拠**: rev.md「3. 工程別AI割当」「5. 代用・無料CLI」「10. 付録：フォールバックの型」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- Core4エージェント間の連携
- HITL（Human-in-the-Loop）の承認フロー
- フォールバックの自動切り替え
- エージェント暴走防止策

### Out of Scope（適用外）
- 個別AIの内部実装（各AIの仕様）
- プロンプト構造（Part26で扱う）

---

## 3. 前提（Assumptions）

1. **Core4の役割固定**がされている（Part03, Part21）
2. **LiteLLM等のルーター**が構築されている（Part22）
   - 公式ドキュメント: [LiteLLM Documentation](https://docs.litellm.ai/docs/)
   - [LiteLLM Fallbacks](https://docs.litellm.ai/docs/proxy/reliability)
   - [LiteLLM Model Fallbacks Tutorial](https://docs.litellm.ai/docs/tutorials/model_fallbacks)
3. **VibeKanban**でタスク管理されている
4. **HITL（Human-in-the-Loop）フレームワーク**が構築されている
   - [Human-in-the-Loop for AI Agents: Best Practices](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo)
   - [Keeping Humans in the Loop: Building Safer AI Agents](https://bytebridge.medium.com/keeping-humans-in-the-loop-building-safer-24-7-ai-agents-44a3366f94c2)

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Core4**: ChatGPT（司令塔）・Claude Code（実装）・Gemini（調査）・Z.ai（補助）の4つ
- **HITL**: Human-in-the-Loopの略。重要決定で人間による承認を必須とする仕組み
- **フォールバック**: 主担当が制限・障害時に代替AIに自動切り替えする仕組み
- **エージェント暴走**: AIが無限ループ・誤操作をする状態
- **Cline**: HITLエージェント（承認つき自動化）の実装

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-3001: Core4の役割固定【MUST】

Core4は以下の役割を固定する：

#### ChatGPT（司令塔・レビュー）
- **役割**: 最終意思決定・差分評価・DoD判定
- **使用工程**: Spec・Hard Design・Fix（論理レビュー）
- **権限**: 全AIの承認・エスカレーション判断

#### Claude Code（実装）
- **役割**: ファイル変更・コマンド実行・テスト駆動開発
- **使用工程**: Build・Fix（実装）
- **権限**: ファイル読取・変更提案（HITLで承認後に実行）

#### Gemini（調査）
- **役割**: 探索・リンク回収・一次情報収集
- **使用工程**: Research・Spec（監査）
- **権限**: Web検索・ファイル読取

#### Z.ai（補助）
- **役割**: 整形・候補列挙・軽量タスク
- **使用工程**: 雑務・コメント・ドキュメント体裁
- **権限**: 読取・軽量な生成

---

### R-3002: HITL（Human-in-the-Loop）の必須化【MUST】

以下の操作は人間による承認を必須とする：

#### 承認必須操作
- **ファイル変更**: Git commit・ファイル削除・大規模変更
- **コマンド実行**: システムへの重大な影響を伴う操作（例: 強制削除、履歴改変を伴うプッシュ）
- **AI切り替え**: 主担当からフォールバックへの切り替え
- **リリース**: Release Gateの通過

#### 実装方法
- **Cline**: 承認待ち状態で一時停止し、人間が`Approve/Reject`を選択
- **VS Code通知**: 承認要求を通知で表示
- **ログ**: 全承認履歴をEvidenceに保存

---

### R-3003: フォールバックの型【MUST】

工程別にフォールバック順を固定する：

#### Spec/Design（長文・整合性）
1. Claude Opus（主担当）
2. Claude Sonnet
3. Gemini 3 Pro
4. （節約）Flash/GLM
5. （最終）ローカル

#### Build（差分生成・改修）
1. Codex（GPT-5.2）（主担当）
2. Claude Sonnet
3. Gemini 3 Pro
4. （節約）Flash/GLM
5. （最終）ローカル

#### 雑務（整形・命名・表）
1. Flash/GLM（主担当）
2. （必要時）Sonnet/Pro

#### 自動切り替え条件
- **レート制限**: 429エラー発生時
- **障害**: 500/503エラー発生時
- **上限到達**: 予算・トークン上限到達時

---

### R-3004: エージェント暴走防止【MUST】

以下の防止策を実装する：

#### VRループ3回制限
- **ルール**: Part11 R-1101に従い、3回でHumanGateを発動
- **実装**: Watcher Scriptでループ回数をカウント（Part29）
- **対処**: 3回失敗したら上位AI or 人間にエスカレーション

#### 危険コマンド禁止
- **ルール**: システムに重大な影響を及ぼすコマンド（強制削除、履歴改変を伴うプッシュなど）は禁止されています（Part27 Conftest）
- **実装**: checks/verify_repo.ps1 で検知
- **対処**: 検知時は即座に Fail し、手動確認を要求

#### コンテキスト上限
- **ルール**: AIへのコンテキスト量を上限の50%以内に制限（Part26）
- **実装**: Context Builderで圧縮・要約（Part28）
- **対処**: 上限超過時は警告し、コンテキストを削減

---

### R-3005: エージェント間通信【SHOULD】

エージェント間の通信は以下のプロトコルに従う：

#### 通信形式
- **タスクID**: VibeKanbanのチケットIDを共有
- **ステータス**: Spec→Research→Design→Build→Fix→Verify→Release→Operate
- **成果物**: JSON/Markdownで標準化

#### 通信例
```json
{
  "task_id": "TICKET-001",
  "from_agent": "chatgpt",
  "to_agent": "claude",
  "stage": "build",
  "context": {
    "spec_url": "docs/spec/TICKET-001.md",
    "design_url": "docs/design/TICKET-001.md",
    "acceptance": ["A-001", "A-002"]
  },
  "output_format": "code"
}
```

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: フォールバックの設定
1. LiteLLM設定ファイル作成: `litellm_config.yaml`
   ```yaml
   model_list:
     - model_name: "spec-primary"
       litellm_params:
         model: "claude-opus"
       fallbacks:
         - model_name: "spec-fallback-1"
           litellm_params:
             model: "claude-sonnet"
         - model_name: "spec-fallback-2"
           litellm_params:
             model: "gemini-3-pro"
   ```
2. LiteLLM起動: `litellm --config litellm_config.yaml`
3. 各AIツールがLiteLLM経由でAPI呼出

### 手順B: HITLの実行
1. AIが承認要求を発行（例：ファイル変更）
2. VS Code通知で承認要求が表示される
3. 人間が`Approve`または`Reject`を選択
4. 承認履歴をEvidenceに保存
5. `Approve`なら処理継続、`Reject`なら修正要求

### 手順C: エージェント間通信
1. ChatGPTがSpecを出力
2. VibeKanbanでステータスを`Spec`→`Design`に遷移
3. ClaudeがDesignを読取・実装
4. Verifyで品質チェック
5. 全工程のログをEvidenceに保存

### 手順D: 暴走時の対処
1. Watcher ScriptがVRループ3回を検知
2. HumanGateを発動（人間による確認を要求）
3. 必要に応じて上位AI（Opus）にエスカレーション
4. ADRで「暴走原因・対策」を記録
5. 再発防止策を実装

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: 全フォールバックが失敗
**対処**:
1. ローカルLLM（Ollama）に最終フォールバック
2. 人間による手動対応
3. ADRで「全フォールバック失敗・原因・対策」を記録

---

### 例外2: HITL承認が得られない
**対処**:
1. タイムアウト（15分）で自動キャンセル
2. ステータスを`Blocked`に変更
3. VibeKanbanで担当者に通知

---

### 例外3: エージェント間通信が失敗
**対処**:
1. 通信ログを確認
2. メッセージフォーマットを検証
3. 必要に応じて手動で成果物を転送

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-3001: Core4の役割固定確認
**判定条件**: Core4の役割がR-3001に従っているか
**合否**: 違反があれば Fail
**実行方法**: `checks/verify_core4_roles.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_core4_roles.md`

---

### V-3002: フォールバック設定確認
**判定条件**: フォールバックがR-3003に従って設定されているか
**合否**: 未設定があれば警告（Fail ではない）
**実行方法**: `checks/verify_fallback.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_fallback.md`

---

### V-3003: HITL履歴確認
**判定条件**: HITL承認履歴が記録されているか
**合否**: 未記録があれば警告（Fail ではない）
**実行方法**: `checks/verify_hitl.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_hitl.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-3001: HITL承認履歴
**保存内容**: タスクID・承認内容・承認者・承認日時
**参照パス**: `evidence/hitl/YYYYMMDD_hitl.md`
**保存場所**: `evidence/hitl/`

---

### E-3002: フォールバックログ
**保存内容**: 元モデル・フォールバック先・原因・日時
**参照パス**: `evidence/fallback/YYYYMMDD_fallback.md`
**保存場所**: `evidence/fallback/`

---

### E-3003: エージェント間通信ログ
**保存内容**: 送信元・送信先・メッセージ内容・日時
**参照パス**: `evidence/agent_comm/YYYYMMDD_agent_comm.md`
**保存場所**: `evidence/agent_comm/`

---

## 10. チェックリスト

- [x] 本Part30 が全12セクション（0〜12）を満たしているか
- [x] Core4の役割固定（R-3001）が明記されているか
- [x] HITLの必須化（R-3002）が明記されているか
- [x] フォールバックの型（R-3003）が明記されているか
- [x] エージェント暴走防止（R-3004）が明記されているか
- [x] エージェント間通信（R-3005）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-3001〜V-3003）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-3001〜E-3003）が参照パス付きで記述されているか
- [ ] 本Part30 を読んだ人が「エージェント協調モデル」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-3001: フォールバックのタイムアウト
**問題**: フォールバックのタイムアウト時間が未定。
**影響Part**: Part30（本Part）
**暫定対応**: 各フォールバックで30秒、最終で5分。

---

### U-3002: HITLの承認権限
**問題**: 誰がHITLを承認できるか未定。
**影響Part**: Part30（本Part）、Part09（Permission Tier）
**暫定対応**: Part09 Permission Tierに従い、Owner/Maintainerのみ承認可能。

---

### U-3003: エージェント間通信のプロトコル
**問題**: 標準プロトコル（MCP等）を使用するか未定。
**影響Part**: Part30（本Part）、Part28（MCP連携）
**暫定対応**: MCPベースのプロトコルを使用。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part09.md](Part09.md) : Permission Tier
- [docs/Part11.md](Part11.md) : VRルール
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part22.md](Part22.md) : 制限耐性設計
- [docs/Part28.md](Part28.md) : MCP連携設計

### HITL（Human-in-the-Loop）一次情報
- [Human-in-the-Loop for AI Agents: Best Practices](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo) : HITLベストプラクティス（2025年6月）
- [Keeping Humans in the Loop: Building Safer AI Agents](https://bytebridge.medium.com/keeping-humans-in-the-loop-building-safer-24-7-ai-agents-44a3366f94c2) : HITLによる24/7 AIエージェントの安全な構築
- [Human-in-the-Loop AI in 2025: Proven Design Patterns](https://blog.ideafloats.com/human-in-the-loop-ai-in-2025/) : 2025年のHITL AI設計パターン
- [Safety & Guardrails for Agentic AI Systems (2025)](https://skywork.ai/blog/agentic-ai-safety-best-practices-2025-enterprise/) : エージェンティブAIシステムの安全性とガードレール

### フォールバック（LiteLLM）一次情報
- [LiteLLM Documentation](https://docs.litellm.ai/docs/) : LiteLLM公式ドキュメント
- [LiteLLM Fallbacks - Proxy Reliability](https://docs.litellm.ai/docs/proxy/reliability) : フォールバック設定
- [LiteLLM Routing, Loadbalancing & Fallbacks](https://docs.litellm.ai/docs/routing-load-balancing) : ルーティング・ロードバランシング
- [Model Fallbacks w/ LiteLLM](https://docs.litellm.ai/docs/tutorials/model_fallbacks) : モデルフォールバックチュートリアル

### sources/
- [_imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md](../_imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md) : 原文（工程別AI割当・フォールバックの型）

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_core4_roles.ps1` : Core4役割確認（未作成）
- `checks/verify_fallback.ps1` : フォールバック設定確認（未作成）
- `checks/verify_hitl.ps1` : HITL履歴確認（未作成）

### evidence/
- `evidence/hitl/` : HITL承認履歴
- `evidence/fallback/` : フォールバックログ
- `evidence/agent_comm/` : エージェント間通信ログ

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
