# Vibe Kanban Documentation Research

**取得日**: 2026-01-11
**出典URL**: https://vibekanban.com/docs
**取得方法**: MCP Web Reader (Z.AI)

## 概要

Vibe Kanbanは、AI coding agentsのためのオーケストレーションプラットフォームです。

## 主要機能

### 1. AI Agents Orchestration
- **定義**: AI coding agentsの計画、レビュー、安全な実行を支援するプラットフォーム
- **目的**: 開発者がAIアシスタントの力を活用しながら、コードベースを完全にコントロールできる

### 2. Isolated Git Worktree
- **隔離実行**: 各タスクは独立したgit worktreeで実行される
- **安全性**: Agentsが互いに干渉したり、mainブランチに影響を与えたりすることを防止
- **並列実行**: 複数のAI agentsが独立したブランチで同時に作業可能

### 3. Multi-Agent Support
- **対応Agent**: Claude Code, OpenAI Codex, Amp, Cursor Agent CLI, Gemini等
- **ワークフロー**: Agent間の切り替えをワークフロー変更なしで実行可能

### 4. Visual Code Review
- **差分レビュー**: 行ごとの差分表示
- **コメント機能**: AIの変更に対してコメントを追加可能
- **フィードバック**: Agentへのフィードバック送信

## 引用（原文）

> "Vibe Kanban is an **orchestration platform for AI coding agents** that helps developers plan, review, and safely execute AI-assisted coding tasks. Each task runs in an isolated git worktree, giving you complete control over your codebase whilst leveraging the power of AI assistants."

> "Every task runs in an isolated git worktree. Agents can't interfere with each other or your main branch."

> "Switch between Claude Code, OpenAI Codex, Amp, Cursor Agent CLI, Gemini, and other agents without changing workflows."

## 検証可能性

- 公式ドキュメント: https://vibekanban.com/docs
- GitHub リポジトリ: https://github.com/BloopAI/vibe-kanban (検索結果より)
- 最終確認日: 2026-01-11
- **要再確認頻度**: 四半期ごと（機能追加・対応Agent変更の可能性）
