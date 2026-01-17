# Part 26：プロンプトエンジニアリング標準（各AIのプロンプト設計ルール・ベストプラクティス）

## 0. このPartの位置づけ
- **目的**: 各AI（Claude/GPT/Gemini/Z.ai）のプロンプト設計ルールを標準化し、「誰が書いても同じ品質」を保証する
- **依存**: [Part03](Part03.md)（AI Pack）、[Part21](Part21.md)（工程別AI割当）、[Part30](Part30.md)（エージェント協調）
- **影響**: 全AI使用工程・プロンプト品質・出力精度

---

## 1. 目的（Purpose）

本 Part26 は **プロンプトエンジニアリングの標準化** を通じて、以下を保証する：

1. **同一品質**: 誰がプロンプトを書いても同じ品質の出力が得られる
2. **最適構造**: 各AIの最適なプロンプト構造（Claude: XMLタグ、GPT: JSON等）を定義
3. **コンテキスト活用**: コンテキストを最大限有効活用する順序・優先度を固定
4. **出力保証**: 出力フォーマットを指定し、後続処理の自動化を可能にする

**根拠**: 「必ず入れたい.md」（CLIラッパー実装・Context Pack動的生成・Core4のIDE統合）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- Core4（ChatGPT, Claude Code, Gemini, Z.ai）のプロンプト設計
- 各工程（Spec/Research/Design/Build/Fix/Verify/Release/Operate）のプロンプト
- プロンプトのバージョン管理
- プロンプトの品質評価

### Out of Scope（適用外）
- 個別AIのプロンプトチューニング（モデルパラメータ）
- 新しいAIモデルの評価（Part25で扱う）

---

## 3. 前提（Assumptions）

1. **Core4の役割固定**がされている（Part03, Part05）
2. **各AIに最適なプロンプト構造**が存在する
3. **プロンプトの品質が出力精度に直結**する
4. **プロンプトはバージョン管理**される

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **プロンプトエンジニアリング**: LLMへの指示を最適化する技術
- **プロンプト構造**: 各AIに最適なプロンプトフォーマット
- **コンテキスト**: LLMへの入力情報（参照ファイル・タスクID等）
- **出力フォーマット**: LLMの出力形式（JSON/Markdown/Code等）
- **プロンプトバージョン**: プロンプトのバージョン管理（v1.0, v1.1等）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2601: Claudeのプロンプト構造【MUST】

Claude（Opus/Sonnet）は以下のプロンプト構造に従う：

#### XMLタグによるセクション分割
```xml
<context>
ここにコンテキスト情報を記述
</context>

<task>
ここにタスク内容を記述
</task>

<constraints>
ここに制約条件を記述
</constraints>

<output_format>
ここに出力フォーマットを記述
</output_format>
```

**理由**: XMLタグによりプロンプトが構造化され、Claudeがセクションを正確に認識できる。

---

### R-2602: GPTのプロンプト構造【MUST】

GPT（Codex/GPT-5.2）は以下のプロンプト構造に従う：

#### JSONベースのセクション分割
```json
{
  "context": "ここにコンテキスト情報",
  "task": "ここにタスク内容",
  "constraints": "ここに制約条件",
  "output_format": "ここに出力フォーマット"
}
```

**理由**: JSON構造によりGPTが情報を正確にパースできる。

---

### R-2603: Geminiのプロンプト構造【MUST】

Gemini（3 Pro/Flash）は以下のプロンプト構造に従う：

#### Markdownベースのセクション分割
```markdown
## Context
ここにコンテキスト情報

## Task
ここにタスク内容

## Constraints
ここに制約条件

## Output Format
ここに出力フォーマット
```

**理由**: Markdown構造によりGeminiがセクションを正確に認識できる。

---

### R-2604: コンテキスト投入の順序【MUST】

コンテキストは以下の順序で投入する：

1. **タスク定義**（Goal/Acceptance/Non-Goals）
2. **参照ファイル**（SSOTの該当箇所・SPEC・Evidence）
3. **制約条件**（禁止事項・前提条件）
4. **出力フォーマット**（JSON/Markdown/Code等）

**理由**: AIがタスク→参照→制約→出力の順で理解しやすい。

---

### R-2605: 出力フォーマットの指定【MUST】

出力フォーマットは以下を指定する：

- **形式**: JSON/Markdown/Code/Plain text
- **エンコーディング**: UTF-8
- **構造**: 必須フィールド・オプションフィールド
- **例**: サンプル出力を含める

**理由**: 後続処理の自動化・パースが可能になる。

---

### R-2606: プロンプトのバージョン管理【MUST】

プロンプトは以下の形式でバージョン管理する：

- **バージョン**: v1.0, v1.1, v2.0等
- **変更履歴**: 変更内容・変更日時・変更理由
- **保存先**: `prompts/v<version>/<purpose>.md`

**理由**: プロンプトの変更履歴を追跡し、再現性を担保する。

---

### R-2607: プロンプトの品質評価【SHOULD】

プロンプトの品質を以下の指標で評価する：

1. **明確性**: タスクが明確に定義されているか
2. **完全性**: 必要な情報が漏れなく含まれているか
3. **制約**: 制約条件が明記されているか
4. **出力**: 出力フォーマットが指定されているか
5. **再現性**: 同じプロンプトで同じ品質の出力が得られるか

---

### R-2608: AI役割切り替えランチャー【SHOULD】

IDE（VS CodeやCursor）内で、「これは設計相談（ChatGPT）」「これは実装（Claude）」とワンクリックで送信先を変えるプリセットを用意する：

#### プリセット定義
- **設計モード（Spec/Design）**: ChatGPT（GPT-5.2）へ送信
- **実装モード（Build）**: Claude Code（Sonnet）へ送信
- **調査モード（Research）**: Gemini 3 Proへ送信
- **雑務モード（整形・コメント）**: Z.ai GLMへ送信

#### 実装方法
- **VS Code拡張機能**: `vibe-ai-switcher` 拡張機能をインストール
- **コマンドパレット**: `Ctrl+Shift+P` → `Vibe: Switch AI Mode` で選択
- **ショートカットキー**: `Alt+1`〜`Alt+4` で各モードに切り替え

#### プロンプト自動切り替え
- 各モードで最適なプロンプト構造（R-2601〜R-2603）を自動適用
- Claude: XMLタグ構造
- GPT: JSON構造
- Gemini: Markdown構造

**根拠**: [Part03](Part03.md)（Core4の役割固定）、[Part29](Part29.md)（IDE統合設計）、必ず入れたい.md「Core4の役割分担をIDEに統合」

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: Claudeプロンプトの作成
1. XMLタグでセクション分割
2. `<context>`にタスクに関連するコンテキストを記述
3. `<task>`にタスク内容を記述（Goal/Acceptanceを含む）
4. `<constraints>`に制約条件を記述（禁止事項・前提条件）
5. `<output_format>`に出力フォーマットを記述（例を含む）
6. プロンプトを `prompts/v1.0/claude/<task_name>.md` に保存

### 手順B: GPTプロンプトの作成
1. JSON形式でプロンプトを作成
2. `context`にタスクに関連するコンテキストを記述
3. `task`にタスク内容を記述
4. `constraints`に制約条件を記述
5. `output_format`に出力フォーマットを記述
6. プロンプトを `prompts/v1.0/gpt/<task_name>.md` に保存

### 手順C: Geminiプロンプトの作成
1. Markdown形式でプロンプトを作成
2. `## Context`にタスクに関連するコンテキストを記述
3. `## Task`にタスク内容を記述
4. `## Constraints`に制約条件を記述
5. `## Output Format`に出力フォーマットを記述
6. プロンプトを `prompts/v1.0/gemini/<task_name>.md` に保存

### 手順D: プロンプトのバージョン更新
1. プロンプトを修正
2. バージョンをインクリメント（v1.0→v1.1）
3. 変更履歴を記録
4. 旧バージョンを `prompts/archive/` に移動
5. 新バージョンを `prompts/v<version>/` に保存

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: プロンプトが意図した出力を生成しない
**対処**:
1. プロンプトの明確性を確認（タスク定義・制約条件）
2. 出力フォーマットの例を追加・詳細化
3. プロンプトを分割し、段階的に指定

**エスカレーション**: 3回以上改善しても効果なしの場合、Part23（回帰防止）で評価。

---

### 例外2: プロンプトが長すぎてエラーになる
**対処**:
1. コンテキストを優先順位で削減
2. 参照ファイルをサマリーに置き換え
3. プロンプトを複数に分割

---

### 例外3: AIがプロンプトを無視する
**対処**:
1. Permission Tierを確認（Part09）
2. プロンプトの構造を確認（R-2601〜R-2603）
3. プロンプトをより明確に記述

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2601: プロンプト構造の確認
**判定条件**: 各AIのプロンプトがR-2601〜R-2603に従っているか
**合否**: 違反があれば Fail
**実行方法**: `checks/verify_prompt_structure.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_prompt_structure.md`

---

### V-2602: 出力フォーマットの指定確認
**判定条件**: 全プロンプトに出力フォーマットが指定されているか
**合否**: 未指定があれば Fail
**実行方法**: `checks/verify_output_format.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_output_format.md`

---

### V-2603: プロンプトのバージョン管理確認
**判定条件**: プロンプトがバージョン管理されているか
**合否**: 未管理があれば警告（Fail ではない）
**実行方法**: `checks/verify_prompt_version.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_prompt_version.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2601: プロンプトファイル
**保存内容**: プロンプト全文・バージョン・変更履歴
**参照パス**: `prompts/v<version>/<ai>/<task_name>.md`
**保存場所**: `prompts/`

---

### E-2602: プロンプト変更履歴
**保存内容**: バージョン・変更内容・変更日時・変更理由
**参照パス**: `prompts/CHANGELOG.md`
**保存場所**: `prompts/`

---

### E-2603: プロンプト品質評価記録
**保存内容**: 明確性・完全性・制約・出力・再現性のスコア
**参照パス**: `evidence/prompt_evaluation/YYYYMMDD_evaluation.md`
**保存場所**: `evidence/prompt_evaluation/`

---

## 10. チェックリスト

- [x] 本Part26 が全12セクション（0〜12）を満たしているか
- [x] Claudeのプロンプト構造（R-2601）が明記されているか
- [x] GPTのプロンプト構造（R-2602）が明記されているか
- [x] Geminiのプロンプト構造（R-2603）が明記されているか
- [x] コンテキスト投入の順序（R-2604）が明記されているか
- [x] 出力フォーマットの指定（R-2605）が明記されているか
- [x] プロンプトのバージョン管理（R-2606）が明記されているか
- [x] 各ルールに「必ず入れたい.md」への参照が付いているか
- [x] Verify観点（V-2601〜V-2603）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2601〜E-2603）が参照パス付きで記述されているか
- [ ] 本Part26 を読んだ人が「プロンプトエンジニアリング標準」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2601: プロンプトの最適長
**問題**: 各AIのプロンプト最適長（トークン数）が不明。
**影響Part**: Part26（本Part）
**暫定対応**: 各AIのコンテキスト上限の50%以内を目安。

---

### U-2602: プロンプトのテンプレート化
**問題**: よく使うプロンプトパターンをテンプレート化するか不明。
**影響Part**: Part26（本Part）
**暫定対応**: `prompts/templates/` にテンプレートを保存。

---

### U-2603: プロンプトのA/Bテスト
**問題**: プロンプトのA/Bテストを実施するか不明。
**影響Part**: Part26（本Part）、Part23（回帰防止）
**暫定対応**: Part23で評価・改善。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part30.md](Part30.md) : エージェント協調

### プロンプトエンジニアリング一次情報
- [OpenAI: Best practices for prompt engineering](https://help.openai.com/en/articles/6654000-best-practices-for-prompt-engineering-with-the-openai-api) : OpenAI公式プロンプトエンジニアリングガイド
- [Prompt Engineering Guide](https://www.promptingguide.ai/) : プロンプトエンジニアリング総合ガイド
- [Prompt Engineering Best Practices 2025](https://codesignal.com/blog/prompt-engineering-best-practices-2025/) : 2025年版プロンプトエンジニアリングベストプラクティス
- [The Ultimate Guide to Prompt Engineering in 2025](https://www.lakera.ai/blog/prompt-engineering-guide) : 2025年版プロンプトエンジニアリング究極ガイド
- [Complete Prompt Engineering Guide: 15 AI Techniques for 2025](https://www.dataunboxed.io/blog/the-complete-guide-to-prompt-engineering-15-essential-techniques-for-2025) : 15のAI技術ガイド

### sources/
- _imports/最終調査_20260115_020600/必ず入れたい.md : 追加すべき機能
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### prompts/
- `prompts/v1.0/claude/` : Claudeプロンプト
- `prompts/v1.0/gpt/` : GPTプロンプト
- `prompts/v1.0/gemini/` : Geminiプロンプト

### evidence/
- `evidence/prompt_evaluation/` : プロンプト品質評価記録

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
