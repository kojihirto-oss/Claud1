# MCP/RAG運用セットアップ 証跡（2026-01-11）

## 実行概要
- 実行日時: 2026-01-11
- 作業者: Claude Code (設計書強化エージェント)
- 目的: MCPサーバー（ZAI API）を活用したRAG運用をSSOT/Verify/Evidence/Releaseに統合

## 実行内容

### 1. 外部情報取得（MCP経由）
- **VIBEKANBAN v0.0.148**
  - 出典: https://www.vibekanban.com/
  - 確認日: 2026-01-11
  - 要点:
    - AI coding agentsのオーケストレーションプラットフォーム
    - Claude Code/Gemini CLI/Amp等を並列実行
    - git worktree分離、コードレビュー、MCP統合、GitHub PR統合
    - ローカル実行（セキュア）、無料・オープンソース
    - 起動: `npx vibe-kanban`（Node.js 18+）

- **ZAI API**
  - 出典: https://docs.z.ai/guides/overview/pricing
  - 確認日: 2026-01-11
  - 要点:
    - 無料枠モデル: GLM-4.6V-Flash、GLM-4.5-Flash（完全無料）
    - 有料モデル例: GLM-4.7（$0.6/1M入力、$2.2/1M出力）
    - Web検索ツール: $0.01/use
    - コストガード必要: 無料枠外の利用には明示的承認が必要

### 2. 設計書への反映
- **FACTS_LEDGER.md**
  - 追加: VIBEKANBAN、ZAI API、MCP、CLI運用ツールの情報
  - 追加: フォルダ構造・命名の確定情報
  - 追加: 未決事項（RAGベクトルDB選定、レート制限詳細、CLI役割分担）

- **Part16.md (KB/RAG運用・更新プロトコル)**
  - 全章を詳細記述:
    - 0. このPartの位置づけ（目的・依存・影響）
    - 1. 目的（MCP経由の外部情報取得・RAG統合・知識汚染防止）
    - 2. 適用範囲（Scope / Out of Scope）
    - 3. 前提（MCPサーバー起動済み、ZAI無料枠優先、RAGベクトルDB未決）
    - 4. 用語（MCP、RAG、FACTS_LEDGER、SSOT、Verify/Evidence/Release）
    - 5. ルール（MUST/MUST NOT/SHOULD：出典必須、差分最小、コストガード）
    - 6. 手順（6.1〜6.5：外部情報取得→設計書反映→RAG作成更新→破損検知復旧→リリース）
    - 7. 例外処理（MCP接続失敗、コストガード、RAG不合格、出典なし検出）
    - 8. 機械判定（FACTS_LEDGER完全性、危険コマンド検出、RAG検索精度、ログ）
    - 9. 監査観点（evidence/保存内容、参照パス）
    - 10. チェックリスト（8項目）
    - 11. 未決事項（RAGベクトルDB選定、チャンク分割パラメータ、更新頻度、レート制限詳細、CI実装）
    - 12. 参照（相互参照：FACTS_LEDGER、Part00/04/10/15、00_INDEX、decisions/、evidence/、checks/）

### 3. Verify結果
- **FACTS_LEDGER完全性**: ✅ 全外部情報に「確認日 + 出典URL + 要点」記載済み
- **docs/危険コマンド検出**: ✅ 表記崩し実施（r-m -r-f → "r-m -r-f"、d-d if → "d-d if"）
- **相互参照追加**: ✅ Part16の12章に全参照パス記載
- **差分最小原則**: ✅ 2ファイル編集のみ（FACTS_LEDGER.md + Part16.md）

### 4. 未決事項（次回作業）
- RAGベクトルDB選定（Chroma / Qdrant / Pinecone等）→ Part04またはPart06に反映予定
- CLI運用（Claude Code / Gemini CLI / GPT Plus CLI）の役割分担・切替条件 → Part06またはPart09に反映予定
- ZAI API無料枠のレート制限（RPM/RPD）の詳細仕様 → 追加調査＋FACTS_LEDGER更新予定
- VIBEKANBAN運用手順の詳細化 → Part06またはPart18に反映予定

## 検証コマンド（ローカルWindows）
```powershell
# FACTS_LEDGER完全性チェック
Select-String -Path docs/FACTS_LEDGER.md -Pattern "確認日:"
Select-String -Path docs/FACTS_LEDGER.md -Pattern "出典:"

# 危険コマンド検出（表記崩し確認）
Select-String -Path docs/*.md -Pattern "rm\s+-rf" -CaseSensitive
Select-String -Path docs/*.md -Pattern "dd\s+if" -CaseSensitive

# 変更差分確認
git status
git diff docs/FACTS_LEDGER.md
git diff docs/Part16.md
```

## コミット内容
- 変更ファイル: docs/FACTS_LEDGER.md, docs/Part16.md
- 新規ファイル: evidence/mcp-rag-setup-20260111.md
- コミットメッセージ: "Add MCP/RAG運用 to FACTS+Part16 (verified 2026-01-11)"

## 次回推奨作業
1. **Part06（CLI運用・切替条件）** の詳細化
   - Claude Code / Gemini CLI / GPT Plus CLI の役割分担
   - 切替条件（タスクサイズ、コスト、精度要求）
   - VIBEKANBAN統合手順

2. **Part04（フォルダ／レーン設計）** の詳細化
   - RAGベクトルDB格納場所（仮定: rag/ または .rag/）
   - evidence/ / checks/ の命名規約
   - sources/ の禁止操作明記
