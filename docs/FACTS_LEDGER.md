# FACTS LEDGER（事実台帳）

> sources/ から抽出した「確定情報」「要求」「制約」「決定」「未決事項」を、根拠パス付きで列挙する。
> 設計書本文を書き始める前に必ず埋める。

## 1) 確定情報（方針/ルール）
- SSOTは docs/ が正本、sources/ は材料（CLAUDE.md より）
- 変更は decisions/ に ADR を追加してから docs を変更（00_INDEX.md より）

## 2) 要求（やりたいこと）
- MCPサーバー（ZAI API）を活用してRAG作成・運用をSSOT/Verify/Evidence/Releaseに統合する

## 3) 制約（できないこと/禁止）
- docs内に危険コマンド文字列をそのまま書かない（CLAUDE.md より）
- 推測で埋めない、未決事項に落とす（CLAUDE.md より）

## 4) 使うツール/役割
- **VIBEKANBAN v0.0.148**（確認日: 2026-01-11, 出典: https://www.vibekanban.com/）
  - 役割: AI coding agentsのオーケストレーションプラットフォーム
  - 機能: Claude Code/Gemini CLI/Amp等を並列実行、git worktree分離、コードレビュー、MCP統合、GitHub PR統合
  - 特徴: ローカル実行（セキュア）、無料・オープンソース、Node.js 18+で `npx vibe-kanban` で起動
- **ZAI API**（確認日: 2026-01-11, 出典: https://docs.z.ai/guides/overview/pricing）
  - 無料枠モデル: GLM-4.6V-Flash（完全無料）、GLM-4.5-Flash（完全無料）
  - 有料モデル: GLM-4.7（$0.6/1M入力、$2.2/1M出力）、GLM-4.6V-FlashX（$0.04/1M入力、$0.4/1M出力）等
  - Web検索ツール: $0.01/use
  - コストガード必要: 無料枠外の利用には明示的な承認が必要
- **Claude Code / Gemini CLI / GPT Plus CLI**（仮定: 設計書で役割分担・切替条件を定義予定）
- **MCP (Model Context Protocol)**
  - 双方向統合: (1) コーディングエージェントにMCPサーバーを接続、(2) VIBEKANBAN自体がMCPサーバーを公開してサードパーティクライアント（Claude Desktop等）から利用可能

## 5) フォルダ構造・命名
- docs/ : 設計書SSOT（Part00〜Part20）
- sources/ : 根拠材料（改変・削除・上書き禁止）
- evidence/ : 検証証跡
- decisions/ : ADR（意思決定記録）
- glossary/ : 用語の唯一定義
- checks/ : 検証手順（Verify）

## 6) 未決事項（推測禁止）
- Claude Code / Gemini CLI / GPT Plus CLIの具体的な役割分担と切替条件
- ZAI API無料枠のレート制限（RPM/RPD）の詳細仕様
- RAGベクトルDB選定（Chroma / Qdrant / Pinecone等）
- RAG更新頻度・トリガー条件の具体仕様
