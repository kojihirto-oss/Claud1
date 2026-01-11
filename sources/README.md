# sources（根拠の保管庫）

## 目的
このフォルダは **設計書の根拠** となる原文・ログ・スクショ・会話履歴を保存し、後から「なぜこの仕様になったか」を検証可能にする。

## 運用ルール（MUST）

### 1. sources/ は材料であり本文ではない
**絶対ルール**: sources/ 内のファイルは **改変・削除・上書き禁止**。

理由：
- sources/ は「事実の記録」であり、後から手を加えると証拠能力が失われる
- docs/ が SSOT（本文）、sources/ は材料（参照のみ）

**禁止事項**:
- sources/ のファイルを編集して「読みやすく」整形
- sources/ のファイルを削除して「整理」
- sources/ のファイルを上書きして「最新版に更新」

### 2. 重要な断定には根拠を付ける
docs/ で MUST/MUST NOT を使う場合、**必ず根拠を参照** する：

```markdown
（docs/ の例）
この仕様は **MUST** である。[根拠](../sources/生データ/20260109_meeting_log.md)
```

### 3. 保存すべき根拠
以下を sources/ に保存することを推奨：
- 会議ログ・チャットログ（重要な決定が含まれるもの）
- スクリーンショット（UI仕様、エラーメッセージなど）
- 外部ドキュメント・仕様書の引用（URLだけでなく、スナップショットも）
- 実験・検証の結果（生データ、コマンド履歴）
- メール・issue・PR の重要な議論（テキスト化して保存）

### 4. sources/ からは参照のみ
docs/ を書くときは、sources/ を **引用・要約** するが、**そのままコピペしない**：
- ❌ 悪い例: sources/ の全文を docs/ に貼り付け
- ✅ 良い例: sources/ を要約し、詳細は [こちら](../sources/xxx.md) とリンク

## 命名規則

### ファイル名
```
YYYYMMDD_topic_name.md
```
- `YYYYMMDD`: 記録日（例: 20260109）
- `topic_name`: 内容を示すケバブケース（例: `meeting_log`, `ui_screenshot`）

**例**:
- `20260109_meeting_log_permission_tier.md`
- `20260105_screenshot_error_message.png`
- `20251220_external_spec_oauth2.md`

### フォルダ構造
```
sources/
├── README.md （本ファイル）
├── _MANIFEST_SOURCES.md （索引、任意）
└── 生データ/ （生ログ・スクショなど）
    ├── 20260109_meeting_log.md
    ├── 20260105_screenshot.png
    └── ...
```

**推奨**:
- 最初は `生データ/` に全て保存
- 増えたらトピック別にサブフォルダを作成（例: `sources/meetings/`, `sources/external_docs/`）

## チェックリスト（根拠追加時）
- [ ] ファイル名が `YYYYMMDD_xxx` 形式
- [ ] 内容が「事実の記録」（解釈・要約は docs/ に書く）
- [ ] docs/ から参照リンクを追加
- [ ] _MANIFEST_SOURCES.md に索引を追加（任意）

## 検証方法
checks/ に以下を追加することを推奨：
```bash
# sources/ への参照リンク切れ検出
grep -r "\.\./sources/" docs/ | while read line; do
  # リンク先のファイルが存在するか確認
done
```

## 未決事項
- sources/ の保存期限（いつまで残す？）→ Part14 で定義予定
- 機密情報の扱い（sources/ に含めてよい？）→ Part09 で定義予定
- 索引 (_MANIFEST_SOURCES.md) の自動生成 → 初回運用後に検討

## 参照
- [_MANIFEST_SOURCES.md](_MANIFEST_SOURCES.md) : 索引（任意）
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : 根拠管理のルールを定義した ADR
- [CLAUDE.md](../CLAUDE.md) : sources/ の改変・削除禁止に関する絶対ルール
