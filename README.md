# vibe-spec-ssot（Claude Code 用 ZIP テンプレ）

このZIPは、**プロジェクトデータ（ファイル/会話ログ）を、Part00〜Part20の設計書SSOTへ変換**するための最小テンプレです。

## 使い方（最短）
1. このフォルダを任意の場所に展開（解凍）
2. `sources/` に材料を投入（**上書き禁止**）
   - 会話ログ → `sources/chatlogs/`
   - 既存資料/設計/メモ → `sources/files/`
   - Web根拠の保存 → `sources/webclips/`
3. Claude Code をこのフォルダで起動し、まず `docs/FACTS_LEDGER.md` を作成（事実台帳）
4. つづけて `docs/00_INDEX.md`（章の契約）を更新
5. 推奨順で Part を確定（Part00→01→02→…）

## Z.ai（検索/Reader/Vision）を Claude Code に繋ぐ（MCP）
- Claude Code は MCP を通じて外部ツールに接続できます。公式ドキュメント参照。 citeturn0search2turn0search5
- Z.ai は Web Search / Web Reader / Vision の MCP サーバを提供しています。 citeturn0search1turn0search6turn0search8

### 1) 環境変数を設定
`.env.example` を `.env` にコピーして、キーを設定：
- ZAI_API_KEY=...

（APIキーはリポジトリにコミットしない）

### 2) MCPを追加（例）
Z.ai Web Search（HTTPトランスポート）例： citeturn0search1turn0search2
- `claude mcp add` で追加（プロジェクト or ユーザー スコープ）

> ※ コマンド詳細はClaude CodeのMCPドキュメントに沿ってください。 citeturn0search2turn0search5

### 3) `.mcp.json` でプロジェクト共有（推奨）
`.mcp.json` にサーバ定義を置くと、同一プロジェクト内で再利用しやすいです（環境変数展開も可）。 citeturn0search2turn0search0

## 設計書（Part00-20）
`docs/PartXX_*.md` を章単位で確定していきます。各Partは「テンプレ（型）」に従って執筆してください。

- 日付: 2026-01-09
