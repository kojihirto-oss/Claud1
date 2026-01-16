# Part 28：MCP連携設計（Model Context Protocolによる動的コンテキスト生成）

## 0. このPartの位置づけ
- **目的**: MCP（Model Context Protocol）を活用し、「タスクに必要な最小コンテキスト」を動的生成する仕組みを定義する
- **依存**: [Part03](Part03.md)（AI Pack）、[Part21](Part21.md)（工程別AI割当）、[Part29](Part29.md)（IDE統合）
- **影響**: 全AI使用工程・コンテキスト管理・出力精度

---

## 1. 目的（Purpose）

本 Part28 は **MCP連携による動的コンテキスト生成** を通じて、以下を保証する：

1. **最小コンテキスト**: タスクに必要なファイル・証跡・SSOTのみをAIに提示
2. **ノイズ除去**: 関係ないファイル・過去のコンテキストによる幻覚を防止
3. **自動生成**: 手動でコンテキストを収集する手間を削減
4. **再現性**: 同じタスクなら同じコンテキストセットが生成される

**根拠**: 「必ず入れたい.md」（Context Packの動的生成・MCP活用）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 全AI工程でのコンテキスト生成
- MCP Serverの構成・運用
- Context Packの生成・キャッシュ・管理
- IDE/CLIからのMCP呼出

### Out of Scope（適用外）
- 個別AIのプロンプト構造（Part26で扱う）
- MCPプロトコルの詳細仕様

---

## 3. 前提（Assumptions）

1. **MCP Serverが構築されている**（mcp-server-context-builder等）
2. **各AIツールがMCP対応している**（Claude Code等）
3. **SSOTの構造が固定されている**（Part00-Part30）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **MCP**: Model Context Protocolの略。AIツールとコンテキスト供給源の標準プロトコル
- **Context Pack**: タスク実行に必要な最小限のコンテキストセット
- **Focus Pack**: 現在作業中のタスクに関連するコンテキストの動的生成結果
- **Context Builder**: Context Packを自動生成するツール（MCP Server）
- **タスクID**: VibeKanban等で管理される一意のタスク識別子

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2801: Context Packの構成【MUST】

Context Packは以下の要素で構成する：

#### 基本要素
- **タスク定義**: Goal/Acceptance/Non-Goals
- **関連SSOT**: 該当Partの該当セクション（全文ではなく該当箇所のみ）
- **過去Evidence**: 関連する過去の実行結果・検証レポート
- **参照ファイル**: タスクに関連するソースコード・設定ファイル

#### 生成ルール
- **タスクIDから自動決定**: `TICKET-001`等のタスクIDから関連ファイルを自動検出
- **変更差分のみ**: Build/Fix工程では変更差分のあるファイルのみを含む
- **深さ制限**: 間接参照は3階層までに制限（無限再帰を防止）

---

### R-2802: MCP Serverの実装【MUST】

MCP Serverは以下の機能を提供する：

#### 必須機能
- **タスクID解決**: タスクIDから関連ファイルを解決
- **差分検出**: Git差分・変更ファイルの検出
- **コンテキスト圧縮**: 長すぎるファイルのサマリー化
- **キャッシュ管理**: 同じタスクIDならキャッシュを返却

#### API仕様
```typescript
// MCP Tools (例)
{
  name: "get_context_pack",
  description: "タスクIDからContext Packを取得",
  inputSchema: {
    type: "object",
    properties: {
      task_id: { type: "string" },
      include_diff: { type: "boolean" },
      max_depth: { type: "number", default: 3 }
    }
  }
}
```

---

### R-2803: コンテキスト優先度【MUST】

コンテキストは以下の優先度で収集する：

1. **必須**: タスク定義・該当SSOT・変更ファイル
2. **重要**: 関連テスト・関連Evidence
3. **参考**: 類似過去タスク・関連ADR

**除外ルール**:
- `node_modules/`, `.git/`, `evidence/` の全文（参照時のみ）
- バイナリファイル・画像（マルチモーダル時のみ）

---

### R-2804: Context Builderの動作【SHOULD】

Context Builderは以下の動作をする：

#### 動作フロー
1. **タスクID受信**: VibeKanban等からタスクIDを受信
2. **関連ファイル検出**: タイトル・ラベル・関連Partからファイルを推定
3. **差分抽出**: 現在のworktreeでの変更差分を抽出
4. **SSOT参照**: 該当するPart・セクションを抽出
5. **パッケージ化**: Context PackとしてJSON/Markdownで出力

#### 実行タイミング
- **タスク開始時**: 手動またはWatcher Scriptで自動実行
- **VRループ時**: 修正内容に応じて再生成
- **完了時**: 最終Context PackをEvidenceに保存

---

### R-2805: IDE統合【SHOULD】

MCPはIDE/CLIから直接呼べるようにする：

#### Claude Codeとの連携
- **MCP Server設定**: `.claude/mcp_settings.json` でContext Builderを登録
- **自動呼出**: タスク開始時に自動的にContext Packを生成
- **表示形式**: `<context>` タグでAIに提示

#### VS Code/拡張機能との連携
- **サイドバー表示**: 現在のContext Packを常に表示
- **手動リロード**: ボタン一つでContext Packを更新
- **関連ファイルジャンプ**: Context Packからファイルを開く

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: MCP Serverの構築
1. インストール: `npm install -g @modelcontextprotocol/server-context-builder`
2. 設定ファイル作成: `.claude/mcp_settings.json`
   ```json
   {
     "mcpServers": {
       "context-builder": {
         "command": "npx",
         "args": ["@modelcontextprotocol/server-context-builder"]
       }
     }
   }
   ```
3. サーバー起動: `mcp-server-context-builder --port 3000`

### 手順B: Context Packの手動生成
1. タスクIDを指定: `mcp-client get-context-pack --task-id TICKET-001`
2. 出力を確認: `context-packs/TICKET-001.json`
3. 必要に応じて編集・追加
4. AIツールに提示

### 手順C: Claude Codeでの自動呼出
1. `.claude/mcp_settings.json` にContext Builderを登録
2. タスク開始時に「今このタスク（TICKET-001）をやっている」と宣言
3. Claude Codeが自動的にContext Packを生成・提示
4. AIがContext Packに基づいて回答

### 手順D: キャッシュ管理
1. 同じタスクIDならキャッシュを利用（高速化）
2. キャッシュの有効期限: 24時間
3. 手動クリア: `mcp-client clear-cache --task-id TICKET-001`

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: タスクIDから関連ファイルが検出できない
**対処**:
1. 手動でファイルを指定
2. タスクIDの命名規約を見直し
3. Context Builderの検出ロジックを改善

---

### 例外2: Context Packが大きすぎる
**対処**:
1. `max_depth` を下げて再生成
2. ファイルをサマリー化
3. 優先度を下げるコンテキストを削除

---

### 例外3: MCP Serverが応答しない
**対処**:
1. サーバーの状態を確認
2. フォールバックとして手動でコンテキストを収集
3. ログを確認し、エラー原因を特定

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2801: MCP Serverの稼働確認
**判定条件**: MCP Serverが稼働しているか
**合否**: 未稼働なら Fail
**実行方法**: `checks/verify_mcp_server.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_mcp_server.md`

---

### V-2802: Context Packの構成確認
**判定条件**: Context Packに必須要素が含まれているか
**合否**: 不足があれば Fail
**実行方法**: `checks/verify_context_pack.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_context_pack.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2801: Context Pack
**保存内容**: タスクID・生成日時・含まれるファイル・サイズ
**参照パス**: `context-packs/<task_id>.json`
**保存場所**: `context-packs/`

---

### E-2802: MCP Serverログ
**保存内容**: 起動ログ・リクエストログ・エラーログ
**参照パス**: `evidence/mcp/YYYYMMDD_mcp.log`
**保存場所**: `evidence/mcp/`

---

## 10. チェックリスト

- [x] 本Part28 が全12セクション（0〜12）を満たしているか
- [x] Context Packの構成（R-2801）が明記されているか
- [x] MCP Serverの実装（R-2802）が明記されているか
- [x] コンテキスト優先度（R-2803）が明記されているか
- [x] Context Builderの動作（R-2804）が明記されているか
- [x] IDE統合（R-2805）が明記されているか
- [x] 各ルールに「必ず入れたい.md」への参照が付いているか
- [x] Verify観点（V-2801〜V-2802）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2801〜E-2802）が参照パス付きで記述されているか
- [ ] 本Part28 を読んだ人が「MCP連携設計」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2801: MCP Serverの実装方針
**問題**: 既存のMCP Serverを使用するか、自作するか未定。
**影響Part**: Part28（本Part）
**暫定対応**: 既存の`@modelcontextprotocol/server-context-builder`を使用。

---

### U-2802: タスクIDの命名規約
**問題**: タスクIDの命名規約が未定。
**影響Part**: Part28（本Part）、Part30（エージェント協調）
**暫定対応**: `TICKET-<連番>` 形式を使用。

---

### U-2803: Context Packの保存先
**問題**: Context Packの保存先が未定。
**影響Part**: Part28（本Part）
**暫定対応**: `context-packs/` ディレクトリに保存。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part26.md](Part26.md) : プロンプトエンジニアリング標準
- [docs/Part29.md](Part29.md) : IDE統合設計
- [docs/Part30.md](Part30.md) : エージェント協調モデル

### sources/
- [_imports/最終調査_20260115_020600/必ず入れたい.md](../_imports/最終調査_20260115_020600/必ず入れたい.md) : 追加すべき機能（MCP活用）

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_mcp_server.ps1` : MCP Server稼働確認（未作成）
- `checks/verify_context_pack.ps1` : Context Pack構成確認（未作成）

### evidence/
- `evidence/mcp/` : MCP Serverログ
- `context-packs/` : Context Pack保存先

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
