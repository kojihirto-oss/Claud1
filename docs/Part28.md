# Part 28：MCP連携設計（Model Context Protocolによる動的コンテキスト生成）

## 0. このPartの位置づけ
- **目的**: MCP（Model Context Protocol）を活用し、「タスクに必要な最小コンテキスト」を動的生成する仕組みを定義する
- **依存**: [Part03](Part03.md)（AI Pack）、[Part09](Part09.md)（Permission Tier）、[Part18](Part18.md)（MCP vs RAG境界）、[Part21](Part21.md)（工程別AI割当）、[Part29](Part29.md)（IDE統合）、[Part00](Part00.md)
- **影響**: 全AI使用工程・コンテキスト管理・出力精度
- **Primary Sources**:
  - [FACTS_LEDGER](FACTS_LEDGER.md): F-0075（MCP vs RAG役割分離）、F-0011（MCP導入方針）
  - [ADR-0007](../decisions/0007-mcp-rag-boundary.md): D-0007-1〜D-0007-5（MCP vs RAG使い分け、sources/扱い、flex-router位置づけ）
- **Quick Start**: [手順セクション](#手順)を参照

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
- MCP認証・セキュリティ（OAuth 2.1ベース）
- MCP許可/禁止リスト、Permission Tierとの統合
- Context Packフォーマット、保存場所、命名規則、差分管理、Evidence化

### Out of Scope（適用外）
- 個別AIのプロンプト構造（Part26で扱う）
- MCPプロトコルの詳細実装（公式仕様書を参照）
- RAGの詳細（Part16で扱う）

---

## 3. 前提（Assumptions）

1. **MCP Serverが構築されている**（mcp-server-context-builder等）
   - 公式仕様: [Model Context Protocol Specification](https://modelcontextprotocol.io/specification/2025-03-26)
   - GitHub: [modelcontextprotocol](https://github.com/modelcontextprotocol)
2. **各AIツールがMCP対応している**（Claude Code等）
3. **SSOTの構造が固定されている**（Part00-Part30）
4. **OAuth 2.1ベースの認証が構築されている**
   - [OAuth 2.1 Authorization Framework (Draft)](https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/)
   - [RFC 8414: Authorization Server Metadata](https://www.rfc-editor.org/rfc/rfc8414.html)
   - [RFC 7591: Dynamic Client Registration](https://www.rfc-editor.org/rfc/rfc7591.html)
5. **vibe-mcp-flex-router-node が配置されている**
   - `C:\Users\koji2\Desktop\vibe-mcp-flex-router-node` に配置済み
   - MCPツール `llm_chat` / `llm_health` / `llm_cache_clear` を提供

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

### R-2800: MCP許可/禁止リスト【MUST】

**MCPで何をするか（許可リスト）**:
- **許可対象**: 読み取り系MCP（Read-only Resources）
- **許可操作**: ファイル読み取り、ディレクトリ一覧、ファイル検索
- **許可データ**:
  - `docs/`（SSOT全文）
  - `decisions/`（ADR全文）
  - `glossary/`（用語定義）
  - `evidence/`（証跡・参照のみ、編集禁止）
  - `sources/`（Read-only、RAG化禁止、ADR-0007 D-0007-2）
- **許可プロトコル**: MCP Resources（Read-only）、MCP Prompts（制限付き）

**MCPで何をしないか（禁止リスト）**:
- **禁止操作**:
  - ファイル書き込み（PatchOnly Tier以上で可能）
  - ファイル削除・移動（HumanGate必須）
  - `sources/`への書き込み（絶対禁止、Part00 R-0003）
  - `sources/`のRAG化（ADR-0007 D-0007-2）
  - 秘密情報（API Key/Token）を含む設定ファイルの読み取り
- **禁止データ**:
  - `.env`、`*.key`、`*_secrets*`、`credentials.json`（秘密情報）
  - `node_modules/`、`.git/`、`dist/`（生成物）
  - 一時ファイル（`*.tmp`、`*.log`）

**Permission Tierとの統合**（Part09準拠）:

| 操作種別 | 必要Tier | MCP許可 | 確認方法 |
|---------|---------|---------|---------|
| ファイル読み取り | ReadOnly | ✓ Read-only Resources | なし |
| docs/編集（最小差分） | PatchOnly | ✗ 書き込み禁止 | Dry-run表示 |
| MCP Prompts実行 | ExecLimited | △ 制限付き | 実行前確認 |
| 削除・sources改変 | HumanGate | ✗ 絶対禁止 | 明示的承認 |

**根拠**:
- Part09（Permission Tier）
- Part18 R-1814（MCP vs RAGの使い分け）
- ADR-0007 D-0007-2（sources/の扱い）

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

### R-2802: Context Packフォーマット【MUST】

**フォーマット仕様**:

```json
{
  "context_pack": {
    "version": "1.0",
    "task_id": "TICKET-001",
    "generated_at": "2025-01-17T12:30:00+09:00",
    "generated_by": "mcp-context-builder",
    "expires_at": "2025-01-18T12:30:00+09:00",
    "elements": {
      "task_definition": {
        "goal": "string",
        "acceptance": ["string"],
        "non_goals": ["string"]
      },
      "related_ssot": [
        {
          "part": "Part10",
          "section": "Verify Gate",
          "excerpt": "string",
          "path": "docs/Part10.md"
        }
      ],
      "past_evidence": [
        {
          "task_id": "TICKET-000",
          "result": "PASS",
          "path": "evidence/tasks/TICKET-000/"
        }
      ],
      "source_files": [
        {
          "path": "src/main.ts",
          "excerpt": "string",
          "diff": "string"
        }
      ]
    },
    "metadata": {
      "total_size_bytes": 12345,
      "file_count": 5,
      "max_depth": 3,
      "includes_diff": true
    }
  }
}
```

**保存場所と命名規則**:
- **保存場所**: `evidence/context-packs/YYYYMMDD/`
- **命名規則**: `context_pack_<task-id>_<timestamp>.json`
- **例**: `context_pack_TICKET-001_20250117_123000.json`
- **Evidence化**: タスク完了時に `evidence/tasks/TICKET-001/context_pack.json` にコピー

**差分管理**:
- **バージョン管理**: 同一タスクIDで再生成される場合、バージョン番号をインクリメント
- **バージョン形式**: `v1`, `v2`, `v3`...（ファイル名には含めず、メタデータで管理）
- **差分保存**: 前回版からの変更差分を `elements.metadata.diff_from_previous` に保存
- **保持期間**: タスク完了後のContext PackはEvidenceとして永久保存

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

### R-2803: 秘密情報の扱い【MUST NOT】

**絶対に読み取ってはならないファイル**:
- `.env`、`*.env.*`（環境変数、API Key、Token）
- `*.key`、`*.pem`、`*.cert`（秘密鍵、証明書）
- `*_secrets*`、`*_credentials*`、`*_auth*`（認証情報）
- `credentials.json`、`secrets.json`、`config.secrets.json`

**注意書き（MCP Server実装時）**:
> **警告**: MCP Serverのファイル読み取り機能は、秘密情報を含むファイルを絶対に読み取ってはならない。
> 秘密情報がAIに渡ると、以下のリスクがある：
> - AIの出力に秘密情報が含まれる（ログ、レスポンス）
> - 秘密情報が外部サービスに送信される可能性
> - 監査ログに秘密情報が記録され、長期間保存される
>
> **対策**:
> 1. ファイルパスブラックリストを実装（上記パターンに一致するファイルを拒否）
> 2. ファイル内容スキャン（`API_KEY`、`SECRET`、`TOKEN`等のキーワード検出）
> 3. 読み取り拒否時のログ（試行されたパス、理由を記録）
> 4. 定期的な監査（MCP Serverログのスキャン、漏洩チェック）

**根拠**:
- Part09（Permission Tier）
- 一般的なセキュリティベストプラクティス（Secrets Management）

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

### R-2806: vibe-mcp-flex-router-node運用【MUST】

vibe-mcp-flex-router-node は **MCPのLLMルーティング用途**に限定して運用する。

- **役割**: MCPクライアントからのLLM呼び出しを `llm_chat` / `llm_health` / `llm_cache_clear` で中継し、Gemini/Z.ai へルーティングする
- **配置**: ローカル端末（`C:\Users\koji2\Desktop\vibe-mcp-flex-router-node`）に常設し、STDIOでのみ起動する（HTTP公開しない）
- **起動**: `Start_VIBE_MCP_Inspector.cmd` または `run-inspector-safe.cmd` を推奨し、STDIO単体時は `npm run start`
- **更新**: 更新前に `git status` で作業差分を確認し、`git pull --ff-only` → `npm install` → `npm run verify:stdio` を必須
- **障害時切替**: `llm_health` が失敗した場合は、MCPクライアント側を直結設定（Gemini/Z.ai のOpenAI互換エンドポイント）へ切替し、Evidenceに記録する
- **用途限定**: `llm_chat` / `llm_health` / `llm_cache_clear` 以外の用途に拡張しない
- **STDIO専用**: MCP transport は stdio のみ（HTTPサーバーとして公開しない）
- **秘密情報保護**: `.env` の内容は表示・共有しない（鍵の有無は `llm_health` で判定）
- **ログ運用**: 監査用のログはEvidenceに保存し、APIキーは記録しない
- **フォールバック**: ルーティング失敗時は `gemini` / `zai` の順序で自動フォールバック

---

### R-2807: 外部調査→根拠→設計書反映→Verify→証跡【MUST】

外部調査から設計反映までの事故防止フローを固定する。

1. **外部調査**: 公式仕様・公式Repo・一次情報を優先して収集する
2. **根拠保存**: `evidence/research_import/` に Evidence を作成し、URL/更新日/参照日/種別/要点を記録する
3. **設計書反映**: 該当Partへ反映し、Evidenceのファイル名と結びつける
4. **Verify**: `checks/verify_repo.ps1`（Fast）で合格を確認する
5. **証跡**: Verifyレポートと変更差分を Evidence に保存し、必要に応じて `_MANIFEST_SOURCES.md` を更新する

Evidenceテンプレ（例）:
```
# <調査タイトル>

## URL
- <https://example.com>

## 更新日
- 2026-01-11（不明なら Unknown）

## 参照日
- 2026-01-17

## 種別
- Primary / Secondary

## 設計へ落とすべき要点
- 箇条書き
```

### R-2808: 一次情報優先ルール【MUST】

- **優先順位**: 公式仕様 / 公式Repo / 公式アナウンスを最優先とする
- **例外**: 一次情報が欠落・非公開・更新停止の場合は二次情報を許可する
- **ラベル付け**: 二次情報は `Secondary` と明記し、一次情報の代替理由と差分を記録する

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

### 手順E: vibe-mcp-flex-router-node 運用Runbook

#### 起動（Start）
1. 前提確認: Node.js 18+、`.env` にAPIキー設定済み（鍵の内容は表示しない）
2. 依存導入（初回のみ）: `npm install`
3. 起動方法（Inspector経由）: `Start_VIBE_MCP_Inspector.cmd` または `run-inspector-safe.cmd` または `npm run inspect`
4. 起動方法（STDIO単体）: `npm run start`
5. 注意: STDIO起動中のターミナルには入力しない（JSON-RPCが壊れるため）

#### 検証（Verify）
1. STDIO検証: `npm run verify:stdio`
2. Inspector上で `llm_health` を実行し、`keySet: true` を確認
3. `llm_chat` を短文で実行し、`provider` と `cached` の返りを確認

#### 更新（Update）
1. 変更確認: `git status` で作業差分なしを確認
2. 更新取得: `git pull --ff-only`
3. 依存更新: `npm install`
4. 再検証: `npm run verify:stdio` → `llm_health` を確認
5. 証跡: 更新日と検証結果をEvidenceに記録

#### 障害復旧（Recovery）
1. Inspector接続不可: ブラウザ再起動 → Inspector再起動 → `llm_health` 再確認
2. 返答エラー: `.env` のキー有無を確認し、`provider` を固定して切り分け
3. ネットワーク障害: 復旧後に `llm_chat` を再実行し、キャッシュ影響を確認
4. 端末フリーズ: OSのタスク管理でプロセスを停止し、再起動する

#### 障害時切替（Failover）
1. Router障害: `llm_health` がFailなら直ちにMCPクライアント側の直接接続に切替
2. 切替先: Gemini/Z.ai のOpenAI互換エンドポイントを指定して応急運用
3. 証跡: 切替理由・開始/終了時刻・影響範囲をEvidenceに記録

#### クライアント設定（Client Config）
1. `.MCP.json.example` を基に `.MCP.json` を作成する
2. `command` は `node`、`args` は `server.mjs` の**絶対パス**
3. パスはJSONの仕様に従い `\\` でエスケープする

```json
{
  "mcpServers": {
    "vibe-flex-router": {
      "type": "stdio",
      "command": "node",
      "args": [
        "C:\\Users\\koji2\\Desktop\\vibe-mcp-flex-router-node\\server.mjs"
      ],
      "env": {}
    }
  }
}
```

#### ログ/証跡（Logs & Evidence）
1. 起動ログとエラーはEvidenceに保存（標準エラーの内容のみ）
2. `llm_health` の結果をテキストで保存（APIキーは含めない）
3. `llm_chat` の検証結果を `verify_reports` に保存

#### 安全運用（Safe Ops）
1. `.env` の内容をログ・チケット・チャットに貼らない
2. `llm_health` のみで鍵の有無を確認する
3. 不要な常時起動は避け、タスク単位で起動・停止する

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

### 例外4: MCPセキュリティインシデント

KBで抽出されたMCPセキュリティに関する攻撃ベクトルと対策：

#### Confused Deputy Problem（混同された代理人問題）
**攻撃内容**:
- MCPプロキシサーバーが静的クライアントIDを第三者APIに使用する場合
- 悪意あるクライアントが同意クッキーを悪用し、ユーザーの明示的な承認なしに認証コードを取得

**対策**:
- **Per-Client Consent Storage**: クライアントごとの同意状態を分離して保存
- **Consent UI Requirements**: 明確な同意UIでリクエスト元クライアントを識別
- **Redirect URI Validation**: リダイレクトURIを厳密に検証

**根拠**: [MCP Security - Confused Deputy](https://modelcontextprotocol.io/specification/draft/basic/authorization#security-considerations)

#### Token Passthrough（トークン直接通過）アンチパターン
**問題**:
- MCPサーバーがトークンを検証せずに下流APIに通過させる
- 監査証跡の欠如、説明責任の欠如

**対策**:
- **MUST NOT accept any tokens** that were not explicitly issued for the MCP server
- **Validate token claims**: roles, privileges, audience

#### Session Hijack Prompt Injection（セッションハイジャック）
**攻撃内容**:
- 攻撃者がセッションIDを使用してMCPサーバーを呼び出す
- MCPサーバーが追加の認証をチェックしない

**対策**:
- **MUST Verify all inbound requests**
- **MUST NOT use sessions for authentication**
- **Use secure random session IDs**

#### Local MCP Server Compromise（ローカルMCPサーバー侵害）
**リスク**:
- ローカルMCPサーバーはユーザーと同じ権限で実行される
- 悪意ある「スタートアップ」コマンドが実行される可能性

**対策**:
- **Pre-Configuration Consent**: 新しいローカルMCPサーバー接続前に同意ダイアログを表示
- **Sandboxed Environment**: サンドボックス環境で最小限の権限で実行

---

### 追加のセキュリティ対策（Inspector/Proxy/Authorization）

#### Authorization Server Metadata検証【MUST】
**問題**: 不正なAuthorization Serverエンドポイントへの接続

**対策**:
1. **RFC 8414準拠**: Authorization Server MetadataをJSON形式で取得・検証
2. **必須フィールド検証**:
   - `issuer`: 発行者URLの検証
   - `authorization_endpoint`: 認証エンドポイント
   - `token_endpoint`: トークンエンドポイント
   - `jwks_uri`: 公開鍵セットURI
3. **TLS証明書検証**: すべての通信でmTLSを推奨

**実装例**:
```typescript
// Authorization Server Metadata検証
const metadata = await fetch(authServerMetadataUrl);
const json = await metadata.json();

// 必須フィールド検証
const requiredFields = ['issuer', 'authorization_endpoint', 'token_endpoint', 'jwks_uri'];
for (const field of requiredFields) {
  if (!json[field]) throw new Error(`Missing required field: ${field}`);
}
```

**根拠**:
- [RFC 8414: OAuth 2.0 Authorization Server Metadata](https://www.rfc-editor.org/rfc/rfc8414.html)

#### Dynamic Client Registrationの安全利用【SHOULD】
**問題**: 動的クライアント登録時の悪意あるクライアント登録

**対策**:
1. **RFC 7591準拠**: Dynamic Client Registrationプロトコルに従う
2. **クライアント認証**: 登録時にクライアント認証を実施
3. **redirect_uris検証**: 登録時にredirect_urisを厳密に検証
4. **grant_types制限**: 必要最小限のgrant_typesのみを許可

**実装例**:
```typescript
// Dynamic Client Registration
const registrationRequest = {
  client_name: "MCP Context Builder",
  redirect_uris: ["https://localhost:3000/callback"],
  grant_types: ["authorization_code"],
  response_types: ["code"],
  scope: "read:context-pack"
};

const response = await fetch(registrationEndpoint, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(registrationRequest)
});
```

**根拠**:
- [RFC 7591: OAuth 2.0 Dynamic Client Registration Protocol](https://www.rfc-editor.org/rfc/rfc7591.html)

#### MCP Inspectorの追加検証項目【MUST】
**追加の検証項目**:
1. **リクエストサイズ制限**: 単一リクエストのサイズ上限（例: 10MB）
2. **レスポンスサイズ制限**: 単一レスポンスのサイズ上限（例: 50MB）
3. **レート制限**: 同一クライアントからのリクエスト頻度制限（例: 100req/min）
4. **Timeout設定**: 単一リクエストのタイムアウト（例: 30秒）

**実装例**:
```typescript
// リクエスト検証ミドルウェア
function validateRequest(req) {
  // サイズ制限
  if (req.headers['content-length'] > 10 * 1024 * 1024) {
    throw new Error('Request too large');
  }

  // レート制限（Redis等で実装）
  const clientId = req.client_id;
  const requestCount = await redis.incr(`rate_limit:${clientId}`);
  if (requestCount > 100) {
    throw new Error('Rate limit exceeded');
  }

  // Timeout設定
  req.setTimeout(30000); // 30秒
}
```

#### Proxyモード時の追加対策【MUST】
**問題**: MCP Proxy経由での認証情報漏洩

**対策**:
1. **TokenMasking**: ログ出力時にトークンをマスク
2. **ヘッダー検証**: `Authorization`ヘッダーの検証
3. **Upstream TLS**: Upstreamサーバーとの通信は必ずTLS

**実装例**:
```typescript
// Token Masking
function maskToken(token) {
  if (!token) return token;
  return token.substring(0, 8) + '...' + token.substring(token.length - 8);
}

// ヘッダー検証
function validateHeaders(headers) {
  const authHeader = headers['authorization'];
  if (authHeader && !authHeader.startsWith('Bearer ')) {
    throw new Error('Invalid authorization header');
  }
}
```

---

### 例外5: vibe-mcp-flex-router-node が応答しない
**対処**:
1. `llm_health` の実行可否を確認
2. Inspector再起動後に再接続
3. 依存導入の状態を確認し、STDIO検証を再実施

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

### V-2803: vibe-mcp-flex-router-node 稼働確認
**判定条件**: `llm_health` が成功し、keySetの有無が返るか
**合否**: 応答がない場合は Fail
**実行方法**: `checks/verify_mcp_flex_router.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_mcp_flex_router.md`

---

### V-2804: STDIO検証（Router）
**判定条件**: `tools/list` が成功し、`llm_chat` が取得できるか
**合否**: 取得できない場合は Fail
**実行方法**: `npm run Verify:stdio`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_mcp_stdio.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2801: Context Pack
**保存内容**: タスクID・生成日時・含まれるファイル・サイズ
**参照パス**: `context-packs/<task_id>.json`
**保存場所**: `context-packs/`

---

### E-2802: MCP Serverログ
**保存内容**: 起動ログ・リクエストログ・エラーログ
**参照パス**: `evidence/mcp/YYYYMMDD_MCP.log`
**保存場所**: `evidence/mcp/`

---

### E-2803: MCP Flex Routerヘルス
**保存内容**: `llm_health` の結果（鍵の有無のみ）
**参照パス**: `evidence/mcp/YYYYMMDD_mcp_flex_router_health.md`
**保存場所**: `evidence/mcp/`

---

### E-2804: MCP Flex Router検証
**保存内容**: STDIO検証結果と `llm_chat` の簡易確認
**参照パス**: `evidence/verify_reports/YYYYMMDD_HHMMSS_mcp_flex_router.md`
**保存場所**: `evidence/verify_reports/`

---

### E-2805: 外部調査Evidence
**保存内容**: URL/更新日/参照日/種別（Primary or Secondary）/要点/反映先
**参照パス**: `evidence/research_import/YYYYMMDD_<topic>.md`
**保存場所**: `evidence/research_import/`

---

## 10. チェックリスト

- [x] 本Part28 が全12セクション（0〜12）を満たしているか
- [x] Context Packの構成（R-2801）が明記されているか
- [x] MCP Serverの実装（R-2802）が明記されているか
- [x] コンテキスト優先度（R-2803）が明記されているか
- [x] Context Builderの動作（R-2804）が明記されているか
- [x] IDE統合（R-2805）が明記されているか
- [x] vibe-mcp-flex-router-node運用Runbookが記載されているか
- [x] 各ルールに「必ず入れたい.md」への参照が付いているか
- [x] Verify観点（V-2801〜V-2804）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2801〜E-2804）が参照パス付きで記述されているか
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

### MCP公式一次情報
- [Model Context Protocol Official Site](https://modelcontextprotocol.io/) : MCP公式サイト（2025）
- [MCP GitHub Repository](https://github.com/modelcontextprotocol/modelcontextprotocol) : MCP公式GitHub（仕様書・スキーマ）
- [MCP Specification 2025-11-25](https://modelcontextprotocol.io/specification/2025-11-25/) : 2025年11月仕様（async Tasks、改善されたOAuth）
- [MCP Authorization (OAuth 2.1)](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) : MCP認証仕様（OAuth 2.1ベース）
- [MCP Development Roadmap](https://modelcontextprotocol.io/development/roadmap) : MCP開発ロードマップ
- [Anthropic MCP Announcement](https://www.anthropic.com/news/model-context-protocol) : AnthropicによるMCP発表

### OAuth 2.1関連一次情報（2025年最新）
- [OAuth 2.1 Authorization Framework (IETF Draft)](https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/) : OAuth 2.1公式ドラフト
- [OAuth 2.1 Draft -13 (Latest, 2025-05-28)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-13) : 最新ドラフト文書
- [OAuth.net Specifications (Updated 2025-10-20)](https://oauth.net/specs/) : OAuth仕様ハブ
- [GitHub: oauth-wg/oauth-v2-1](https://github.com/oauth-wg/oauth-v2-1) : IETF OAUTH Working Groupリポジトリ

### 解説・分析記事（2025年）
- [WorkOS: MCP 2025-11-25 Spec Update](https://workos.com/blog/mcp-2025-11-25-spec-update) : 2025年11月MCP仕様更新の解説
- [Auth0: MCP Spec Updates (June 2025)](https://auth0.com/blog/mcp-specs-update-all-about-auth/) : 2025年6月MCP認証仕様更新の解説
- [Kane.mx: MCP Authorization OAuth RFC Deep Dive](https://kane.mx/posts/2025/mcp-authorization-oauth-rfc-deep-dive/) : MCP認証とOAuth RFCの詳細分析
- [WorkOS: OAuth 2.1 What's New](https://workos.com/blog/oauth-2-1-whats-new) : OAuth 2.1の新機能解説
- [Thoughtworks: MCP Impact 2025](https://www.thoughtworks.com/en-cn/insights/blog/generative-ai/model-context-protocol-mcp-impact-2025) : MCPの2025年への影響分析

### RFC一次情報
- [RFC 8414: OAuth 2.0 Authorization Server Metadata](https://www.rfc-editor.org/rfc/rfc8414.html) : 認証サーバーメタデータ仕様
- [RFC 7591: OAuth 2.0 Dynamic Client Registration Protocol](https://www.rfc-editor.org/rfc/rfc7591.html) : 動的クライアント登録プロトコル
- [RFC 9470: OAuth 2.0 Step Up Authentication Challenge](https://www.rfc-editor.org/rfc/rfc9470.html) : ステップアップ認証チャレンジ
- [RFC 8707: OAuth 2.0 Resource Indicators (RFC 8707)](https://www.rfc-editor.org/rfc/rfc8707.html) : リソースインジケータ（MCPで採用）

### sources/
- [_imports/最終調査_20260115_020600/必ず入れたい.md](../_imports/最終調査_20260115_020600/必ず入れたい.md) : 追加すべき機能（MCP活用）

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_mcp_server.ps1` : MCP Server稼働確認（未作成）
- `checks/verify_context_pack.ps1` : Context Pack構成確認（未作成）
- `checks/verify_mcp_flex_router.ps1` : MCP Flex Router稼働確認（未作成）

### evidence/
- `evidence/mcp/` : MCP Serverログ
- `context-packs/` : Context Pack保存先

### external/
- `C:\Users\koji2\Desktop\vibe-mcp-flex-router-node\README.md` : 運用手順の一次情報
- `C:\Users\koji2\Desktop\vibe-mcp-flex-router-node\server.mjs` : ツール定義（llm_chat/llm_health）
- `C:\Users\koji2\Desktop\vibe-mcp-flex-router-node\.MCP.json.example` : クライアント設定例

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
