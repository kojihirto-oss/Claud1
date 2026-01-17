# Part 23：回帰防止設計（promptfooによる回帰検出・品質ゲート・CI統合）

## 0. このPartの位置づけ
- **目的**: LLMの品質をCIでテストし、モデル更新・プロンプト更新のたびに回帰（劣化）を検出する
- **依存**: [Part10](Part10.md)（Verify Gate）、[Part21](Part21.md)（工程別AI割当）、[Part24](Part24.md)（可観測性）
- **影響**: 全プロンプト・全エージェントの品質保証・CIパイプライン

---

## 1. 目的（Purpose）

本 Part23 は **回帰防止の自動化** を通じて、以下を保証する：

1. **回帰検出**: モデル更新・プロンプト更新時に、品質劣化を自動検出
2. **品質ゲート**: 主要プロンプト・主要エージェントの出力が基準を満たすか機械判定
3. **CI統合**: CIパイプラインに組み込み、PR/マージ前に品質チェックを実施
4. **継続改善**: 閾値を設定し、品質の上振れ・下振れを可視化

**根拠**: 最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md）「2.5 回帰防止（最高精度の核）」「4.6 promptfooで"回帰しない"を機械化」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- promptfooによるLLM回帰テスト
- 主要プロンプト・主要エージェントの品質評価
- CIパイプラインとの統合
- 閾値管理・品質ゲート

### Out of Scope（適用外）
- promptfoo以外のテストツール（他ツールを使う場合はADRで決定）
- 個別プロンプトの詳細設計（別途定義）

---

## 3. 前提（Assumptions）

1. **promptfooがインストールされている**（`npm install -g promptfoo`）
   - 公式ドキュメント: [promptfoo.dev](https://www.promptfoo.dev/docs/)
   - [promptfoo GitHub](https://github.com/promptfoo/promptfoo)
2. **主要プロンプト・主要エージェント**が特定されている
3. **期待出力・最低基準**が定義されている
4. **CIパイプライン**（GitHub Actions等）が構築されている
5. **Part10（Verify Gate）** との連携が確立されている
6. **回帰テストのベストプラクティス**が策定されている
   - [Why Regression Testing LLMs is Essential](https://adel-muursepp.medium.com/why-regression-testing-llms-is-essential-a-practical-guide-with-promptfoo-7b39b636bf91) : LLM回帰テストの重要性
   - [LLM Evaluation Testing with promptfoo](https://kpavlov.me/blog/llm-evaluation-testing-with-promptfoo-a-practical-guide/) : promptfoo実践ガイド

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **promptfoo**: [glossary/GLOSSARY.md#promptfoo](../glossary/GLOSSARY.md)（LLM回帰テストツール）
- **回帰（Regression）**: モデル更新・プロンプト更新による品質劣化
- **品質ゲート（Quality Gate）**: 品質の閾値を設定し、閾値を割ると落とす
- **期待出力（Expected Output）**: プロンプト・エージェントが期待する出力
- **最低基準（Minimum Threshold）**: 品質の最低許容値（スコア/判定）
- **評価スイート（Evaluation Suite）**: テストケースをまとめたセット

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2301: 評価スイートの作成【MUST】

主要プロンプト・主要エージェントに対し、以下の評価スイートを作成する：

#### 評価スイートの構成
- **テストケース**: 期待出力・入力・プロンプト
- **評価基準**: スコア/判定（例: 正確性>0.8, 関連性>0.7）
- **実行環境**: モデル名・プロンプトバージョン

#### 主要プロンプト（例）
- Spec生成プロンプト
- Reviewプロンプト
- 修正提案プロンプト
- 要約プロンプト

#### 主要エージェント（例）
- Specエージェント
- Buildエージェント
- Reviewエージェント
- Fixエージェント

**根拠**: rev.md「4.6 promptfooで"回帰しない"を機械化」
**違反例**: 評価スイートなしで品質ゲートを設定 → 禁止。

---

### R-2302: CI統合の強制【MUST】

promptfooはCIパイプラインに統合し、以下を実施する：

#### PR作成時
1. プロンプト・モデルの変更を検出
2. 評価スイートを実行
3. 品質ゲートで判定（閾値を割るとFAIL）
4. FAILの場合、PRをブロック

#### マージ時
1. Full評価スイートを実行
2. 品質レポートを生成
3. Part24（Langfuse）に記録

**根拠**: rev.md「2.5 回帰防止（最高精度の核）」

---

### R-2303: 閾値管理【MUST】

品質の閾値を以下のレベルで管理：

#### L1: 致命的（Critical）
- **閾値**: 0.9以上
- **対象**: 正確性、安全性
- **違反時**: 即座にブロック・HumanGateで承認のみ許可

#### L2: 重要（Important）
- **閾値**: 0.8以上
- **対象**: 関連性、完全性
- **違反時**: 警告・レビュー必須

#### L3: 通常（Normal）
- **閾値**: 0.7以上
- **対象**: 可読性、簡潔性
- **違反時**: 記録のみ

**違反例**: 閾値未設定で品質ゲート → 禁止。

---

### R-2304: 回帰検出の自動化【MUST】

promptfooは以下の回帰検出を自動実行する：

#### モデル更新時
1. 新旧モデルで同じテストケースを実行
2. スコアを比較（差分>0.1で回帰と判定）
3. 回帰検出時、即座にブロック

#### プロンプト更新時
1. 新旧プロンプトで同じテストケースを実行
2. スコアを比較（差分>0.1で回帰と判定）
3. 回帰検出時、即座にブロック

**根拠**: rev.md「4.6 promptfooで"回帰しない"を機械化」

---

### R-2305: 評価スイートの更新ルール【MUST】

評価スイートの更新は以下のルールに従う：

1. **新規プロンプト・エージェント追加時**: 必ず評価スイートを作成
2. **閾値変更時**: ADRで理由・影響範囲を明記
3. **テストケース追加時**: Part24（Langfuse）に記録
4. **評価スイート削除時**: ADRで理由を明記

---

### R-2306: 品質レポートの生成【SHOULD】

promptfooは以下の品質レポートを生成する：

1. **サマリー**: 全体スコア・回帰検出数・FAIL数
2. **詳細レポート**: テストケース別のスコア・期待出力・実際の出力
3. **傾向分析**: 前回比・品質の上振れ・下振れ
4. **改善提案**: 閾値未達のテストケースに対する改善提案

**保存先**: `evidence/promptfoo/YYYYMMDD_HHMMSS_quality_report.md`

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: promptfooの初期設定
1. promptfooをインストール: `npm install -g promptfoo`
2. 設定ファイル作成: `promptfooconfig.yaml`
3. 評価スイートのディレクトリ作成: `tests/promptfoo/`
4. テストケースの作成: `tests/promptfoo/spec_cases.yaml`

### 手順B: 評価スイートの作成
1. 主要プロンプトを特定（Spec生成・Review等）
2. テストケースを作成:
   ```yaml
   tests:
     - description: "Spec生成の正確性"
       prompt: "{{spec_prompt}}"
       expected: "PRD/Glossary/AC/Not-in-scope/失敗モードを含む"
       assertion:
         - type: icontains
           value: "PRD"
         - type: icontains
           value: "AC"
   ```
3. 閾値を設定:
   ```yaml
   thresholds:
     accuracy: 0.8
     relevance: 0.7
     safety: 0.9
   ```
4. 評価スイートを実行: `promptfoo eval -c promptfooconfig.yaml`

### 手順C: CI統合の設定
1. GitHub Actionsのワークフロー作成: `.github/workflows/promptfoo.yml`
2. PR時の自動実行を設定:
   ```yaml
   on:
     pull_request:
       paths:
         - 'prompts/**'
         - 'tests/promptfoo/**'
   jobs:
     promptfoo:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - run: npx promptfoo eval -c promptfooconfig.yaml
         - uses: actions/upload-artifact@v3
           with:
             name: promptfoo-report
             path: promptfoo-output/
   ```
3. 品質ゲートの設定: FAILの場合、PRをブロック

### 手順D: 回帰検出の実行
1. モデル更新・プロンプト更新を検出
2. 新旧の評価スイートを実行
3. スコアを比較
4. 回帰検出時、即座にブロック・HumanGateで承認

### 手順E: 品質レポートの確認
1. promptfooの出力を確認: `promptfoo-output/`
2. サマリーを確認（全体スコア・回帰検出数・FAIL数）
3. 詳細レポートを確認（テストケース別のスコア）
4. 傾向分析を確認（前回比）
5. 改善提案を確認

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: 品質ゲートでFAIL
**対処**:
1. 即座にPRをブロック
2. 原因を特定（モデル更新？プロンプト更新？テストケース不備？）
3. 修正または閾値調整（ADRで決定）
4. 再評価

**エスカレーション**: 頻発する場合、閾値・プロンプト・モデルの見直し。

---

### 例外2: 回帰検出
**対処**:
1. 即座にブロック
2. 新旧スコアの差分を分析
3. 原因を特定（モデル劣化？プロンプト不備？）
4. 修正またはロールバック
5. 再評価

**エスカレーション**: 頻発する場合、モデル選定の見直し（Part25）。

---

### 例外3: 評価スイートが不備
**対処**:
1. テストケースの不足・不備を特定
2. テストケースを追加・修正
3. Part24（Langfuse）に記録
4. 再評価

**エスカレーション**: 頻発する場合、評価スイート設計の見直し。

---

### 例外4: CI統合が失敗
**対処**:
1. CIパイプラインのエラーを特定
2. 設定ファイルを修正
3. 再実行
4. 手動実行でフォールバック

**エスカレーション**: 頻発する場合、CI設定の見直し。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2301: 評価スイートの存在確認
**判定条件**: 主要プロンプト・主要エージェントに対し評価スイートが存在するか
**合否**: 未作成があれば Fail
**実行方法**: `checks/verify_promptfoo_suite.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_promptfoo_suite.md`

---

### V-2302: 閾値設定の確認
**判定条件**: 閾値が設定されているか（L1: 0.9, L2: 0.8, L3: 0.7）
**合否**: 未設定があれば Fail
**実行方法**: `checks/verify_threshold.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_threshold.md`

---

### V-2303: CI統合の確認
**判定条件**: CIパイプラインにpromptfooが統合されているか
**合否**: 未統合なら Fail
**実行方法**: `checks/verify_ci_promptfoo.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_ci_promptfoo.md`

---

### V-2304: 品質レポートの生成確認
**判定条件**: 品質レポートが生成されているか
**合否**: 未生成なら警告（Fail ではない）
**実行方法**: `checks/verify_quality_report.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_quality_report.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2301: 評価スイート
**保存内容**:
- テストケース（期待出力・入力・プロンプト）
- 評価基準（スコア/判定）
- 実行環境（モデル名・プロンプトバージョン）

**参照パス**: `tests/promptfoo/*.yaml`
**保存場所**: `tests/promptfoo/`

---

### E-2302: 品質レポート
**保存内容**:
- サマリー（全体スコア・回帰検出数・FAIL数）
- 詳細レポート（テストケース別のスコア）
- 傾向分析（前回比）
- 改善提案

**参照パス**: `evidence/promptfoo/YYYYMMDD_HHMMSS_quality_report.md`
**保存場所**: `evidence/promptfoo/`

---

### E-2303: 回帰検出記録
**保存内容**:
- 検出日時
- 新旧スコア
- 差分
- 原因
- 対処

**参照パス**: `evidence/regression/YYYYMMDD_HHMMSS_regression.md`
**保存場所**: `evidence/regression/`

---

### E-2304: 閾値変更記録
**保存内容**:
- 変更日時
- 変更前・変更後の閾値
- 変更理由
- ADRへの参照

**参照パス**: `evidence/threshold/YYYYMMDD_HHMMSS_threshold.md`
**保存場所**: `evidence/threshold/`

---

## 10. チェックリスト

- [x] 本Part23 が全12セクション（0〜12）を満たしているか
- [x] 評価スイートの作成（R-2301）が明記されているか
- [x] CI統合の強制（R-2302）が明記されているか
- [x] 閾値管理（R-2303）が明記されているか
- [x] 回帰検出の自動化（R-2304）が明記されているか
- [x] 評価スイートの更新ルール（R-2305）が明記されているか
- [x] 品質レポートの生成（R-2306）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-2301〜V-2304）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2301〜E-2304）が参照パス付きで記述されているか
- [ ] 本Part23 を読んだ人が「回帰しないを機械化」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2301: 評価スイートのテストケース数
**問題**: 各プロンプト・エージェントに対し、何件のテストケースを作成するか不明。
**影響Part**: Part23（本Part）
**暫定対応**: 重要プロンプトは10〜50件、その他は5〜10件を目安。

---

### U-2302: 閾値の具体的な数値
**問題**: L1/L2/L3の閾値（0.9, 0.8, 0.7）が適切か不明。
**影響Part**: Part23（本Part）
**暫定対応**: 運用で調整し、ADRで決定。

---

### U-2303: 評価スイートの更新頻度
**問題**: テストケースをどの頻度で更新するか不明。
**影響Part**: Part23（本Part）
**暫定対応**: 四半期ごとの定期見直し＋必要に応じ随時更新。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part10.md](Part10.md) : Verify Gate
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part24.md](Part24.md) : 可観測性設計

### promptfoo公式一次情報
- [promptfoo Documentation](https://www.promptfoo.dev/docs/) : promptfoo公式ドキュメント
- [promptfoo GitHub Repository](https://github.com/promptfoo/promptfoo) : promptfoo公式リポジトリ
- [promptfoo Release Notes](https://www.promptfoo.dev/docs/releases/) : リリースノート
- [AI Regulation 2025 (promptfoo Blog)](https://www.promptfoo.dev/blog/ai-regulation-2025/) : AI規制2025（promptfoo公式ブログ）

### 回帰テスト・評価一次情報
- [Why Regression Testing LLMs is Essential](https://adel-muursepp.medium.com/why-regression-testing-llms-is-essential-a-practical-guide-with-promptfoo-7b39b636bf91) : LLM回帰テストの重要性
- [LLM Evaluation Testing with promptfoo](https://kpavlov.me/blog/llm-evaluation-testing-with-promptfoo-a-practical-guide/) : promptfoo実践ガイド
- [Ultimate Guide to LLM Prompt Testing](https://imanishtyagi.medium.com/ultimate-guide-to-llm-prompt-testing-a-hands-on-tutorial-with-promptfoo-b43ac17298a4) : LLMプロンプトテスト究極ガイド
- [Enterprise-Grade Prompt Evaluation](https://www.truefoundry.com/blog/enterprise-ready-prompt-evaluation-how-truefoundry-and-promptfoo-enable-confident-ai-at-scale) : エンタープライズ級プロンプト評価

### sources/
- _imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md : 原文（「2.5 回帰防止」「4.6 promptfooで"回帰しない"を機械化」）
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_promptfoo_suite.ps1` : 評価スイート確認（未作成）
- `checks/verify_threshold.ps1` : 閾値設定確認（未作成）
- `checks/verify_ci_promptfoo.ps1` : CI統合確認（未作成）
- `checks/verify_quality_report.ps1` : 品質レポート確認（未作成）

### evidence/
- `evidence/promptfoo/` : 品質レポート
- `evidence/regression/` : 回帰検出記録
- `evidence/threshold/` : 閾値変更記録

### tests/
- `tests/promptfoo/` : 評価スイート（テストケース）

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
- `promptfooconfig.yaml` : promptfoo設定ファイル（プロジェクトルート）
- `.github/workflows/promptfoo.yml` : CI統合ワークフロー
