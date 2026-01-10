# Part 03：AI Pack（Core4/Antigravity/MCP・役割固定・コンテキスト共有）

## 0. このPartの位置づけ
- **目的**: 複数AIの役割を固定し、コンテキスト共有と並列実行を安全に実現する。
- **依存**: [Part00](Part00.md)（SSOT憲法）、[Part09](Part09.md)（Permission Tier）
- **影響**: 全Part（AIによる作業実行）

---

## 1. 目的（Purpose）

本 Part03 は **AI Pack（Core4 + Antigravity + MCP）** を通じて、以下を保証する：

1. **Core4（AI役割固定）**: 4つの課金AIを役割で固定し、責任範囲を明確化
2. **Antigravity（IDEハブ）**: エージェントの指揮所として、作業の迷いをゼロにする
3. **MCP（コンテキスト共有）**: 複数AIで同じコンテキストを共有し、コピペ地獄を終わらせる
4. **安全装置**: 軽量・安価なモデルを"本流の真実"にしない（Verify/Evidenceで固定）

**根拠**: [FACTS_LEDGER F-0008](FACTS_LEDGER.md)（Core4）、[F-0009](FACTS_LEDGER.md)（Antigravity）、[F-0011](FACTS_LEDGER.md)（MCP）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- Core4（ChatGPT, Claude Code, Gemini, Z.ai）の役割定義
- Antigravity（Google Antigravity）の運用設計
- MCP（Model Context Protocol）の導入方針
- AIの並列実行・コンテキスト共有

### Out of Scope（適用外）
- 個別AIのプロンプト設計（別途定義）
- 課金・コスト管理（プロジェクト外）
- 非課金AI（Claude 3.5 Haiku等）の利用（Core4以外）

---

## 3. 前提（Assumptions）

1. **Core4は役割固定**である（司令塔/実装/調査/補助の4役）。
2. **軽量・安価なモデルを"本流の真実"にしない**（必ずVerify/Evidenceで固定）。
3. **Antigravity は指揮所**であり、「コードを書く場所」ではない。
4. **MCP は読取から開始**し、書込は Permission Tier に従う。
5. **コンテキスト共有は Evidence に記録**される。

**根拠**: [FACTS_LEDGER F-0008](FACTS_LEDGER.md)、[Part09 R-0901](Part09.md)（Permission Tier）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Core4**: [glossary/GLOSSARY.md#Core4](../glossary/GLOSSARY.md)（4つの課金AI）
- **Antigravity**: Google Antigravity（IDEハブ）
- **MCP**: [glossary/GLOSSARY.md#MCP](../glossary/GLOSSARY.md)（Model Context Protocol）
- **Agent Pack**: AIエージェントのセット
- **Permission Tier**: [glossary/GLOSSARY.md#Permission-Tier](../glossary/GLOSSARY.md)（AI権限階層）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-0301: Core4の役割固定【MUST】
4つの課金AIは以下の **役割で固定** する：

#### 1. ChatGPT（司令塔/編集長）
- **役割**: SSOT維持、設計・統合判断、レビュー設計、品質ゲート設計
- **Permission**: ReadOnly（読取専用）
- **用途**:
  - SSOT（docs/）の整合性確認
  - ADR の作成・レビュー
  - Verify の設計
  - タスク分割・優先順位付け
- **禁止**: 実装・コード生成（Claude Code の役割）

#### 2. Claude Code（実装エンジン）
- **役割**: 実装・修正・テスト駆動の反復（CLI/デスクトップ）
- **Permission**: ExecLimited（許可コマンドのみ実行）
- **用途**:
  - コード実装・修正
  - テスト実行・lint実行
  - Verify の実行
  - VRループ（Verify-Repair Loop）
- **禁止**: 設計判断（ChatGPT の役割）

#### 3. Gemini / Google One Pro（調査・統合ハブ）
- **役割**: 外部情報、長文理解、Google連携、Antigravity連動
- **Permission**: ReadOnly（読取専用）
- **用途**:
  - 外部資料の調査
  - 長文ドキュメントの理解
  - Google Workspace 連携
  - Antigravity との連携
- **禁止**: 実装・コード生成（Claude Code の役割）

#### 4. Z.ai Lite（補助LLM/API/MCP）
- **役割**: 軽量タスク、補助分析、並列ワーク（データ分類で制限）
- **Permission**: PatchOnly（差分作成のみ）
- **用途**:
  - ログ要約
  - データ分類・整理
  - 補助的なタスク
  - 並列ワーク（軽量）
- **禁止**: "本流の真実"を生成（必ずVerify/Evidenceで固定）

**根拠**: [FACTS_LEDGER F-0008](FACTS_LEDGER.md)
**注意**: 軽量・安価なモデルを"本流の真実"にしない。必ずVerify/Evidenceで固定する。

---

### R-0302: Antigravity の運用型【MUST】
Antigravity（Google Antigravity）は **エージェントの指揮所** として運用する：

#### 運用型
1. **Editor**: 人間が読む/編集する
2. **Mission Control**: エージェントが計画→実行→検証する
3. **ブラウザ・ターミナル・エディタの同期**を前提に、作業の迷いをゼロにする

#### 禁止
- Antigravity で「コードを書く」単独作業（エージェント連携を前提とする）
- Antigravity を「単なるエディタ」として使う（指揮所として使う）

**根拠**: [FACTS_LEDGER F-0009](FACTS_LEDGER.md)

---

### R-0303: MCP導入方針【MUST】
MCP（Model Context Protocol）は以下の方針で導入する：

#### Phase 1: 読取系MCPから開始
- **対象**: ファイル読取・検索・解析
- **Permission**: ReadOnly
- **例**: filesystem, sqlite, github

#### Phase 2: 書込系は「Patch-only」「許可制」
- **対象**: ファイル書込・コマンド実行
- **Permission**: PatchOnly or ExecLimited
- **例**: git, docker（読取のみ）

#### Phase 3: 破壊系は HumanGate
- **対象**: 削除・強制操作
- **Permission**: HumanGate（人間承認必須）
- **例**: rm, git push --force

#### 監査ログ必須
- **MCP実行時は Evidence に記録**（ツール名・入力・出力・実行日時）
- **保存先**: `evidence/mcp_logs/YYYYMMDD_HHMMSS_mcp_<tool>.md`

**根拠**: [FACTS_LEDGER F-0011](FACTS_LEDGER.md)、[Part09 R-0907](Part09.md)（MCP権限管理）

---

### R-0304: コンテキスト共有の原則【SHOULD】
複数AIで同じコンテキストを共有する際の原則：

1. **SSOT（docs/）を共有の基点**とする
2. **MCP で外部データを共有**（コピペ禁止）
3. **Evidence に共有履歴を記録**（誰が何を共有したか）
4. **コンテキスト共有は読取から開始**（書込は慎重に）

**理由**: "コピペ地獄"を終わらせ、同じコンテキストを複数AIで共有する。

---

### R-0305: 軽量モデルの制限【MUST NOT】
軽量・安価なモデル（Z.ai Lite等）は **"本流の真実"を生成しない**：

**禁止**:
- SSOT（docs/）の直接編集
- ADR の作成
- 設計判断

**許可**:
- ログ要約
- データ分類
- 補助タスク（Verify/Evidenceで固定する前提）

**根拠**: [FACTS_LEDGER F-0008](FACTS_LEDGER.md)（注意事項）

---

### R-0306: AI間の責任分界【MUST】
AI間の責任範囲を明確化し、越権を禁止する：

| AI | 設計 | 実装 | 調査 | 補助 |
|----|------|------|------|------|
| ChatGPT | ✅ | ❌ | ❌ | ❌ |
| Claude Code | ❌ | ✅ | ❌ | ❌ |
| Gemini | ❌ | ❌ | ✅ | ❌ |
| Z.ai Lite | ❌ | ❌ | ❌ | ✅ |

**違反例**:
- Claude Code が設計判断をする → ChatGPT へエスカレーション
- Z.ai Lite が SSOT を直接編集 → 禁止

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: Core4の役割分担
1. タスク（TICKET）を作成（ChatGPT が担当）
2. TICKET の実装を Claude Code に依頼
3. 外部資料の調査が必要な場合、Gemini に依頼
4. ログ要約が必要な場合、Z.ai Lite に依頼
5. 各AIの成果物を Evidence に保存
6. ChatGPT が統合判断（merge/revert）

### 手順B: Antigravity での作業
1. Antigravity の Editor でドキュメントを開く
2. Mission Control でエージェントを起動
3. エージェントが計画→実行→検証
4. 人間が diff をレビュー
5. 承認後に merge

### 手順C: MCP の導入
1. Phase 1: 読取系MCPをインストール（例: filesystem）
2. MCP の設定ファイルを作成（`.mcp/config.json`）
3. MCP を Permission Tier に従って設定（ReadOnly）
4. MCP 実行時は Evidence に記録
5. Phase 2: 書込系MCP を慎重に追加（ADR 必須）

### 手順D: コンテキスト共有
1. SSOT（docs/）を共有の基点とする
2. MCP で外部データを取得（例: github MCP で issue を取得）
3. 取得したデータを Evidence に保存
4. 複数AIで同じ Evidence を参照
5. Evidence に「誰が何を共有したか」を記録

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: AIが役割を越権
**対処**:
1. 即座に作業を停止
2. Evidence に「越権の内容」を記録
3. 正しいAIへエスカレーション
4. 越権したAIの成果物は削除（または HumanGate で確認）

**エスカレーション**: 頻発する場合、Part03 の見直し。

---

### 例外2: 軽量モデルが"本流の真実"を生成
**対処**:
1. 生成された内容を削除
2. Evidence に「軽量モデルの誤用」を記録
3. 正しいAI（ChatGPT or Claude Code）で再生成
4. Verify/Evidenceで固定

**エスカレーション**: R-0305 の徹底。

---

### 例外3: Antigravity が使えない環境
**対処**:
1. Claude Code（CLI/デスクトップ）で代替
2. エージェント連携は手動で実施
3. Mission Control 相当の機能は VIBEKANBAN で代替

**エスカレーション**: Antigravity の環境整備を検討。

---

### 例外4: MCP が Permission Tier を違反
**対処**:
1. MCP の設定を修正（ReadOnly に戻す）
2. Evidence に「MCP違反」を記録
3. MCP の再設定（ADR 必須）

**エスカレーション**: Part09 例外4 を参照。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-0301: Core4の役割遵守確認
**判定条件**: Evidence に各AIの作業記録があり、役割を遵守しているか
**合否**: 越権があれば Fail
**実行方法**: `evidence/` の作業ログをスキャン
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_core4_check.md`

---

### V-0302: 軽量モデルの SSOT 編集検出
**判定条件**: docs/ の変更履歴で、Z.ai Lite による直接編集がないか
**合否**: 検出されたら Fail
**実行方法**: `git log -- docs/` で author を確認
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_lightweight_check.md`

---

### V-0303: MCP 監査ログの存在確認
**判定条件**: MCP 実行時の Evidence が存在するか
**合否**: 記録なしなら警告（Fail ではない）
**実行方法**: `evidence/mcp_logs/` の存在確認
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_mcp_audit.md`

---

### V-0304: Antigravity 作業の diff 保存確認
**判定条件**: Antigravity での作業に対応する diff が Evidence に存在するか
**合否**: 記録なしなら Fail
**実行方法**: `evidence/antigravity/` の存在確認
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_antigravity_check.md`

---

### V-0305: コンテキスト共有の記録確認
**判定条件**: 複数AIでコンテキストを共有した記録が Evidence に存在するか
**合否**: 記録なしなら警告（Fail ではない）
**実行方法**: `evidence/context_sharing/` の存在確認
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_context_check.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-0301: Core4 作業記録
**保存内容**:
- AI名（ChatGPT/Claude Code/Gemini/Z.ai Lite）
- 作業内容
- 作業時刻
- 成果物（ファイルパス）

**参照パス**: `evidence/core4/YYYYMMDD_HHMMSS_<AI>_<task>.md`
**保存場所**: `evidence/core4/`

---

### E-0302: Antigravity 作業記録
**保存内容**:
- 作業内容
- diff（変更前後）
- エージェント実行ログ
- 承認者・承認日時

**参照パス**: `evidence/antigravity/YYYYMMDD_HHMMSS_<task>.md`
**保存場所**: `evidence/antigravity/`

---

### E-0303: MCP 実行ログ
**保存内容**:
- MCP 名・ツール名
- 入力パラメータ
- 出力結果
- 実行日時

**参照パス**: `evidence/mcp_logs/YYYYMMDD_HHMMSS_mcp_<tool>.md`
**保存場所**: `evidence/mcp_logs/`

---

### E-0304: コンテキスト共有記録
**保存内容**:
- 共有元AI・共有先AI
- 共有データ（パス or 内容）
- 共有日時

**参照パス**: `evidence/context_sharing/YYYYMMDD_HHMMSS_context.md`
**保存場所**: `evidence/context_sharing/`

---

### E-0305: 越権記録
**保存内容**:
- 越権したAI
- 越権内容
- 対処内容
- 正しいAIへのエスカレーション

**参照パス**: `evidence/violations/YYYYMMDD_HHMMSS_violation_<AI>.md`
**保存場所**: `evidence/violations/`

---

## 10. チェックリスト

- [x] 本Part03 が全12セクション（0〜12）を満たしているか
- [x] Core4の役割固定（R-0301）が明記されているか
- [x] Antigravity の運用型（R-0302）が明記されているか
- [x] MCP導入方針（R-0303）が明記されているか
- [x] コンテキスト共有の原則（R-0304）が明記されているか
- [x] 軽量モデルの制限（R-0305）が明記されているか
- [x] AI間の責任分界（R-0306）が明記されているか
- [x] 各ルールに FACTS_LEDGER への参照が付いているか
- [x] Verify観点（V-0301〜V-0305）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-0301〜E-0305）が参照パス付きで記述されているか
- [ ] Core4の運用が実際に回っているか（運用開始後に確認）
- [ ] 本Part03 を読んだ人が「AIの使い分け」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-0301: Antigravity の具体的な使い方
**問題**: Antigravity の Mission Control の具体的な操作手順が不明。
**影響Part**: Part03（本Part）
**暫定対応**: Antigravity のドキュメントを参照。実際に使ってみて手順を確立。

---

### U-0302: MCP の設定ファイル形式
**問題**: `.mcp/config.json` の具体的なフォーマットが不明。
**影響Part**: Part03（本Part）
**暫定対応**: MCP の公式ドキュメントを参照。

---

### U-0303: Core4以外のAIの扱い
**問題**: Core4以外のAI（例: Claude 3.5 Haiku）を使う場合のルールが不明。
**影響Part**: Part03（本Part）
**暫定対応**: Core4以外は使わない。必要な場合はADRで決定。

---

### U-0304: コンテキスト共有の上限
**問題**: 複数AIで共有するコンテキストのサイズ上限が不明。
**影響Part**: Part03（本Part）
**暫定対応**: 各AIのコンテキスト上限（例: 200K tokens）を超えないよう注意。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part01.md](Part01.md) : 目標・DoD
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-0008, F-0009, F-0011）
- [docs/Part02.md](Part02.md) : 用語運用ルール
- [docs/Part04.md](Part04.md) : 作業管理（VIBEKANBAN）
- [docs/Part09.md](Part09.md) : Permission Tier

### sources/
- [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md) : 原文（L129-159）

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_core4.sh` : Core4役割遵守確認（未作成）

### evidence/
- `evidence/core4/` : Core4 作業記録
- `evidence/antigravity/` : Antigravity 作業記録
- `evidence/mcp_logs/` : MCP 実行ログ
- `evidence/context_sharing/` : コンテキスト共有記録
- `evidence/violations/` : 越権記録

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
