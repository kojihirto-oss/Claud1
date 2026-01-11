# FACTS LEDGER（事実台帳）

> sources/ から抽出した「確定情報」「要求」「制約」「決定」「未決事項」を、根拠パス付きで列挙する。
> 設計書本文を書き始める前に必ず埋める。

## 1) 確定情報（方針/ルール）
- （例）SSOTは docs/ が正本 … 根拠: sources/...

## 2) 要求（やりたいこと）
- …

## 3) 制約（できないこと/禁止）
- …

## 4) 使うツール/役割

### Vibe Kanban
- **ID**: FACT-TOOL-001
- **定義**: AI coding agentsのオーケストレーションプラットフォーム
- **主要機能**:
  - Isolated git worktree実行（各タスクが独立したworktreeで動作）
  - Multi-agent support（Claude Code, OpenAI Codex, Amp, Cursor Agent CLI, Gemini等）
  - Visual code review（行ごとの差分表示、コメント、フィードバック）
  - 並列タスク管理（複数Agentが独立ブランチで同時作業）
- **出典**: https://vibekanban.com/docs
- **確認日**: 2026-01-11
- **根拠パス**: `evidence/research/20260111_vibekanban_docs.md`
- **要再確認**: 四半期ごと（機能追加・対応Agent変更の可能性）

### Z.AI MCP (Model Context Protocol)
- **ID**: FACT-TOOL-002
- **Built-in Tools価格**:
  - Web Search: **$0.01 / use** (USD)
- **通貨**: USD
- **課金単位**: 1回の使用ごと
- **出典**: https://docs.z.ai/guides/overview/pricing
- **確認日**: 2026-01-11
- **根拠パス**: `evidence/research/20260111_zai_pricing.md`
- **要再確認**: 月次（価格変動リスクあり）
- **注意**: 価格は予告なく変更される可能性。本番環境での大量利用前に最新価格を必ず確認すること

## 5) フォルダ構造・命名
- …

## 6) 未決事項（推測禁止）
- …
