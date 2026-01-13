# ADR-0007: MCP-RAG Boundary（MCPとRAGの使い分け・境界・flex-routerの位置づけ）

- 日付: 2026-01-13
- 状態: 承認
- 影響Part: Part16, Part18
- 参照: docs/Part16.md（RAG運用）

## 背景

MCP（Model Context Protocol）とRAG（Retrieval-Augmented Generation）は、
いずれもAIが外部データを参照する手段だが、役割と境界が不明瞭である。

**問題**:
- MCPでローカルファイルを取得すべきか、RAG検索すべきか不明
- flex-router（複数MCP束ね）の位置づけと責任範囲が不明
- sources/ をMCPで直接読むべきか、RAG化すべきか不明
- 更新頻度・鮮度要件とMCP/RAGの選択基準が不明

境界を明確化し、「いつMCPを使い、いつRAGを使うか」を決定する必要がある。

## 決定

### D-0007-1: MCP vs RAG の使い分け原則【MUST】

| 観点 | MCP（推奨） | RAG（推奨） |
|------|-----------|-----------|
| **データ種別** | 構造化データ（JSON/YAML/コード） | 非構造化データ（Markdown/PDF/長文） |
| **更新頻度** | 高頻度（リアルタイム） | 低頻度（日次〜週次更新） |
| **参照パターン** | ピンポイント取得（特定ファイル） | あいまい検索（キーワード/意図） |
| **データ所在** | ローカルファイルシステム | インデックス化済みKB |
| **鮮度要件** | 最新必須 | 多少の遅延OK |

**判断フロー**:
1. 「特定ファイルパスがわかっている」→ **MCP Read-only**
2. 「キーワードで探したい」→ **RAG検索**
3. 「sources/を参照したい」→ **MCPでRead-only** （RAG化禁止、Part00 R-0003）
4. 「docs/を検索したい」→ **RAG検索** （更新済み前提）

### D-0007-2: sources/ の扱い【MUST】
sources/ は以下のルールで扱う：

- **MCP経由で Read-only 取得**: OK（Permission Tier: ReadOnly）
- **RAG化（埋め込み生成）**: **禁止** （sources/は原本であり、加工・インデックス化は別途ai_ready/で行う）
- **直接編集**: **禁止** （Part00 R-0003）

**理由**: sources/は証拠能力を持つ原本であり、RAG化で内容が変換・要約されると証拠性が失われる。

### D-0007-3: flex-router の位置づけ【MUST】
flex-router（vibe-flex-router MCP server）は以下の役割を担う：

1. **複数MCP束ね**: Gemini MCP, Z.ai MCP等を統合
2. **ルーティング**: `provider: auto|gemini|zai` で自動振り分け
3. **キャッシュ**: 同一クエリの重複削減（llm_cache_clear可能）
4. **ヘルスチェック**: `llm_health`でサーバ状態確認

**責任範囲**:
- MCP呼び出しの最適化（どのMCPに投げるか）
- キャッシュ管理（メモリ/プロセスライフタイム）
- **責任外**: RAG更新、sources/改変、Permission Tier管理

### D-0007-4: RAG更新トリガ【MUST】
RAGは以下のタイミングで更新する：

- **トリガ**: docs/ の更新、glossary/ の更新、decisions/ の更新
- **更新単位**: 変更ファイルのみ（全再生成はHumanGate）
- **更新元**: docs/ → ai_ready/ → RAG埋め込み
- **禁止**: sources/ → RAG直投入（D-0007-2）

**証跡**: `evidence/rag_updates/` に更新ログ保存（Part16）

### D-0007-5: MCPとRAGの併用パターン【SHOULD】
以下のパターンを推奨：

1. **Research工程**:
   - MCP: 特定ファイル取得（sources/生データ/xxx.md）
   - RAG: 関連ドキュメント検索（docs/Partxx.md）

2. **Design工程**:
   - MCP: ADR/FACTS_LEDGER 取得
   - RAG: 既存設計書検索（類似Part探索）

3. **Implementation工程**:
   - MCP: 仕様ファイル取得（docs/Partxx.md）
   - RAG: 使用例検索（過去のEvidence参照）

## 選択肢

### 案A: MCP Read-only優先、RAGは検索専用（採用）
**メリット**:
- 鮮度保証（MCPは常に最新）
- sources/の証拠性維持
- 役割分担明確

**デメリット**:
- RAG構築の手間

### 案B: 全部RAG化（不採用）
**理由**:
- sources/の証拠性喪失
- 鮮度劣化（更新タイムラグ）
- MCP不要になるが、特定ファイル取得が非効率

### 案C: 全部MCP（不採用）
**理由**:
- あいまい検索不可
- 大量ファイルの全文検索が非効率

## 影響範囲

### 互換/移行
- Part16（RAG運用）にsources/のRAG化禁止を明記
- flex-router設定（.mcp.json）にキャッシュ設定追加

### セキュリティ/権限
- MCPはReadOnly Tierで固定（sources/改変禁止）
- RAG更新はPatchOnly Tier（docs/変更時のみ）

### Verify/Evidence/Release への影響
- RAG更新時にevidence/rag_updates/へログ保存
- MCP取得時の参照パス記録

## 実行計画

### 手順
1. Part16.md に「sources/のRAG化禁止」を追記
2. Part16.md に「RAG初回作成工程」を追加
3. Part18.md に「MCP-RAG使い分けフロー」を追記
4. .mcp.json にflex-routerキャッシュ設定追加

### ロールバック
- ADR-0007 を廃止マークし、Part16/Part18 の追記箇所を削除
- RAGインデックスは保持（再構築不要）

### 検証（Verify Gate）
- Fast Verify: sources無改変（V-0004）
- RAG更新ログの存在確認

## 結果

（後日記入：MCP-RAG併用の効果、検索精度、鮮度の改善など）
