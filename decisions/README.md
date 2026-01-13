# decisions（意思決定ログ）

## 目的
このフォルダは **Architecture Decision Records (ADR)** を管理し、仕様・運用の変更が **なぜ・いつ・どのように** 決定されたかを記録する。

## 運用ルール（MUST）

### 1. 変更前に ADR を書く
docs/ の仕様を変更する場合、**必ず先に ADR を追加** してから変更を実施する。

**禁止事項**:
- ADR を書かずに docs/ を直接変更
- 変更理由を口頭・チャット・コミットメッセージだけで済ます
- 後から「なんとなく変えた」を理由に ADR を省略

### 2. ADR の状態管理
各 ADR は以下の状態を持つ：
- **提案**: 検討中（まだ実施していない）
- **承認**: 決定済み（実施してOK）
- **廃止**: 取り消し（別の ADR で上書きされた）

### 3. ADR の参照
docs/ で重要な変更を記述する際は、**必ず ADR へのリンク** を付ける：
```markdown
この仕様は [ADR-0005](../decisions/0005-xxx.md) で決定された。
```

## 命名規則

### ファイル名
```
NNNN-short-topic-name.md
```
- `NNNN`: 4桁の連番（0001, 0002, ...）
- `short-topic-name`: ケバブケース（小文字、ハイフン区切り）

**例**:
- `0001-ssot-governance.md`
- `0002-permission-tier-definition.md`
- `0003-revert-auto-merge.md`

### 内容
[ADR_TEMPLATE.md](ADR_TEMPLATE.md) に従って記述する。**必須項目**：
- 日付
- 状態（提案/承認/廃止）
- 影響Part（Part00, Part14 など）
- 参照（sources/, evidence/ へのパス）
- 背景・決定・選択肢・影響範囲・実行計画

## 承認フロー
承認者・承認SLA・承認チャネルは Part09 と ADR-0004 に従う。

暫定ルール：
- ADR を追加したら、関係者にレビュー依頼
- 異論がなければ「状態: 承認」に変更してコミット
- 異論があれば「状態: 提案」のまま議論継続

## チェックリスト（ADR 追加時）
- [ ] ファイル名が `NNNN-xxx.md` 形式
- [ ] ADR_TEMPLATE.md の全項目が埋まっている
- [ ] 影響Part が明記されている
- [ ] 参照（sources/ or evidence/）が明記されている
- [ ] 実行計画に検証手順がある
- [ ] docs/ の該当 Part に ADR へのリンクを追加

## 未決事項
- ADR の廃止手順（既存の docs/ をどう修正？）→ 初回廃止時に決定
- ADR の廃止手順（既存の docs/ をどう修正？）→ 初回廃止時に決定

## 参照
- [0001-ssot-governance.md](0001-ssot-governance.md) : 本フォルダの運用ルールを定義した ADR
- [ADR_TEMPLATE.md](ADR_TEMPLATE.md) : ADR の書き方
- [CLAUDE.md](../CLAUDE.md) : SSOT の絶対ルール
