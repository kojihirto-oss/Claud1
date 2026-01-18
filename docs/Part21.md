# Part 21：工程別AI割当設計（Spec/Research/Design/Build/Fix/Verify/Release/Operate）

## 0. このPartの位置づけ
- **目的**: 各工程（Spec/Research/Design/Build/Fix/Verify/Release/Operate）でのAI割当を固定し、迷いを排除する
- **依存**: [Part03](Part03.md)（Core4）、[Part05](Part05.md)（Core4運用）、[Part09](Part09.md)（Permission Tier）
- **影響**: 全作業工程のAI選択・フォールバック順・成果物フォーマット

---

## 1. 目的（Purpose）

本 Part21 は **工程別AI割当の標準化** を通じて、以下を保証する：

1. **迷いゼロ**: 各工程で「どのAIを使うか」が一意に決まる
2. **精度保証**: 高精度が必要な工程は高精度モデル、軽量で良い工程は軽量モデルを固定
3. **制限耐性**: メインモデルが使えない場合のフォールバック順を明確化
4. **成果物固定**: 各工程で期待される成果物フォーマットを統一

**根拠**: 最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md）「3. 工程別AI割当（最高精度×制限耐性の"固定編成"）」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 全7工程（Spec/Research/Design/Build/Fix/Verify/Release/Operate）のAI割当
- 主担当/副担当/軽量/フォールバックの役割定義
- 各工程の成果物フォーマット

### Out of Scope（適用外）
- 個別AIのプロンプト設計（別途定義）
- 新しいAIモデルの評価・選定（Part25で扱う）

---

## 3. 前提（Assumptions）

1. **Core4は役割固定**である（Part03, Part05）
2. **高精度モデルは「Spec/Design/Review」**に使う
3. **実装は「火力枠（Aider/Codex）」に集中**させる
4. **フォールバックは固定順**である（詰み回避）
5. **成果物は機械判定可能**である

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Core4**: [glossary/GLOSSARY.md#Core4](../glossary/GLOSSARY.md)（4つの課金AI）
- **主担当（高精度）**: その工程で最も使うAI（Claude Opus, Gemini 3 Pro等）
- **副担当（クロスチェック）**: 主担当の結果を検証するAI
- **軽量（節約）**: コストを抑えるためのAI（Gemini Flash, GLM等）
- **フォールバック**: メインモデルが使えない場合の代替AI
- **工程**: Spec/Research/Design/Build/Fix/Verify/Release/Operate

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2101: 工程別AI割当の固定【MUST】

各工程は以下のAI割当に従う：

#### A) Spec（要件/仕様固め）
- **主担当（高精度）**: Claude（Opus優先）
- **副担当（監査/抜け漏れ）**: Gemini 3 Pro
- **軽量（節約・整形）**: Gemini Flash / Z.ai GLM
- **フォールバック（制限時）**: ローカル（Ollama/LM Studio）＋軽量LLM
- **成果物（固定フォーマット）**: PRD / Glossary / AC（受入基準）/ Not-in-scope / 失敗モード

#### B) Research（調査/比較/一次情報回収）
- **主担当（探索・リンク回収）**: Gemini 3 Pro（必要ならDeep Research系）
- **副担当（構造化・矛盾検出）**: Claude（Sonnet優先）
- **軽量（候補列挙）**: Z.ai GLM / Gemini Flash
- **フォールバック**: OpenRouter経由の低コスト/無料枠モデル、またはローカル
- **成果物**: 調査レポート / 選定候補リスト / 比較表 / 参照リンク

#### C) Hard Design（アーキ/境界/例外/非機能）
- **主担当（設計骨格）**: Claude（Opus→Sonnet）
- **副担当（実装可能性・疑似コード）**: Codex（GPT-5.2）
- **軽量（チェックリスト化）**: Gemini Flash / GLM
- **フォールバック**: Gemini 3 Pro（長文設計が詰まった時の代替）
- **成果物**: ADR / API契約 / 状態遷移 / 失敗モード一覧 / テスト計画 / DoD

#### D) Build（実装）
用途で分ける：

**D-1: 大規模改造（火力枠）**
- **主担当**: Aider（CLI）＋ Codex
- **副担当（別解・バグ潰し）**: Claude Sonnet
- **軽量（小修正）**: Gemini Flash / GLM

**D-2: IDE自動化（反復作業/周辺作業の自動化）**
- **主担当**: VS Code + Cline（HITLエージェント）
- **機能**: 「ファイル変更とコマンド実行を"承認つき"で自動化」する前線
- **用途**:
  - 反復作業の自動化（リファクタリング、一括変更）
  - 周辺作業の自動化（テスト生成、ドキュメント更新）
  - 承認フロー（人間が `Approve/Reject` を選択）
- **副担当**: Codex / Claude
- **設定方法**:
  1. VS Code拡張機能 `Cline` をインストール
  2. APIキー設定（Anthropic API for Claude）
  3. プロンプト規約・作業手順を統一（Part26 Part25 Continue参照）

**D-3: "統一の運転方法"**
- **Continue**で、共通ルール（プロンプト規約/作業手順/コンテキスト投入/ログ）を統一

- **成果物**: 実装コード / テストコード / diff / manifest

#### E) Fix（レビュー/修正/セキュリティ）
- **主担当（論理レビュー）**: Claude Sonnet
- **副担当（実装観点レビュー）**: Codex
- **自動検知（必須級）**: Gitleaks / Trivy / Lint / Typecheck / Unit tests
- **成果物**: レビューレポート / 修正パッチ / Verifyレポート

#### F) Verify（回帰/品質ゲート）
- **主役はモデルではなく"テスト"**
- **promptfoo**をCIに入れ、主要プロンプト/主要エージェントの出力が基準を満たすか、リグレッション（劣化）が起きていないかを機械で保証
- **成果物**: テスト結果 / カバレッジ / 回帰レポート

#### G) Release / Operate（運用・改善）
- **Langfuse**: トレース/評価/失敗分析/改善ループ
- **LiteLLM**: 予算・制限耐性・ルーティング
- **成果物**: リリースノート / SBOM / 運用ダッシュボード / メトリクス

**根拠**: rev.md「3. 工程別AI割当」
**違反例**: 軽量モデルでSpecを書く → 精度不足のため、禁止。

---

### R-2102: フォールバックの型（固定テンプレ）【MUST】

工程別に「詰み回避」順を固定する：

#### Spec/Design（長文・整合性）
Claude Opus → Claude Sonnet → Gemini 3 Pro →（節約）Flash/GLM →（最終）ローカル

#### Build（差分生成・改修）
Codex（GPT-5.2）→ Claude Sonnet → Gemini 3 Pro →（節約）Flash/GLM →（最終）ローカル

#### 雑務（整形・命名・表）
Flash/GLM →（必要時）Sonnet/Pro

**根拠**: rev.md「10. 付録：フォールバックの"型"（固定テンプレ）」

---

### R-2103: 成果物フォーマットの固定【MUST】

各工程の成果物は以下のフォーマットに従う：

#### Spec成果物
```markdown
## PRD（Product Requirements Document）
### 目的
### 非機能要件
### 用語（Glossary参照）
### 受入基準（AC）
### Not-in-scope
### 失敗モード
```

#### Research成果物
```markdown
## 調査レポート
### 調査目的
### 候補リスト
### 比較表
### 推奨順位
### 参照リンク
```

#### Design成果物
```markdown
## ADR（Architecture Decision Record）
### 背景
### 決定内容
### 選択肢（案A/案B/案C）
### 採用理由
### 影響範囲
### DoD
```

**根拠**: rev.md「3. 工程別AI割当」成果物セクション

---

### R-2104: 高精度を使う工程の固定【MUST】

- **高精度を使う工程**: Spec / Hard Design / Review（論理）
- **軽量に落としてよい工程**: 整形、候補列挙、コメント、ドキュメント体裁
- **大規模実装は"火力枠（Aider/Codex）に集中"**: 中途半端に分散するとコストも手戻りも増える

**根拠**: rev.md「7. コスト最適化（精度を落とさず、制限も超えにくくする）」

---

### R-2105: 工程間の引き継ぎ【MUST】

各工程の完了時、以下を引き継ぐ：

1. **成果物**（前工程のフォーマットに従う）
2. **Evidence**（Verify/Evidenceへの参照）
3. **未決事項**（あれば次工程で解決）
4. **DoDチェック**（完了条件を確認）

**違反例**: Spec未完了でBuild開始 → Part01 R-0104違反。

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: Spec工程の実行
1. **主担当（Claude Opus）**でPRDを作成
2. **副担当（Gemini 3 Pro）**で監査・抜け漏れチェック
3. **軽量（Flash/GLM）**で整形・フォーマット調整
4. **DoDチェック**: 受入基準が機械判定可能か確認
5. **Evidence保存**: Spec成果物を `VIBEKANBAN/100_SPEC/` に保存
6. **Verify実行**: Part10のVerify Gateで整合性確認

### 手順B: Research工程の実行
1. **主担当（Gemini 3 Pro）**で探索・リンク回収
2. **副担当（Claude Sonnet）**で構造化・矛盾検出
3. **軽量（GLM/Flash）**で候補列挙
4. **比較表作成**: 候補を評価・順位付け
5. **推奨決定**: 選定結果をADRとして保存
6. **Evidence保存**: Research成果物を `sources/research_inbox/` に保存

### 手順C: Build工程の実行
1. **大規模改造**: Aider（CLI）＋ Codexで実装
2. **IDE自動化**: VS Code + Clineで承認つき自動化
3. **Verify実行**: テスト・lint・型チェック
4. **Review**: Claude Sonnetで論理レビュー、Codexで実装レビュー
5. **VRループ**: 失敗なら修正→再検証
6. **Evidence保存**: diff・manifest・sha256を保存

### 手順D: Fix工程の実行
1. **自動検知**: Gitleaks / Trivy / Lint / Typecheck / Unit tests
2. **論理レビュー**: Claude Sonnet
3. **実装レビュー**: Codex
4. **修正**: 最小差分で修正
5. **再検証**: VerifyでGreenを確認
6. **Evidence保存**: 修正パッチ・Verifyレポートを保存

### 手順E: フォールバックの実行
1. メインモデルがレート制限・障害・上限到達で使えない場合
2. **フォールバック順**（R-2102）に従って代替AIに切り替え
3. **Evidenceに「フォールバック実施」を記録**
4. 元のモデルが復帰したら、元に戻す

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: メインモデルが全く使えない
**対処**:
1. フォールバック順に従って代替AIに切り替え
2. ローカルLLM（Ollama/LM Studio）が最後の砦
3. Evidenceに「フォールバック実施・理由・期間」を記録

**エスカレーション**: 長期フォールバックが予想される場合、ADRで暫定運用を決定。

---

### 例外2: 工程間の成果物が不整合
**対処**:
1. 前工程の成果物を確認
2. 不整合箇所を特定
3. 前工程へ戻り、修正
4. 再度引き継ぎ

**エスカレーション**: 不整合が頻発する場合、成果物フォーマット（R-2103）の見直し。

---

### 例外3: 高精度モデルが予算オーバー
**対処**:
1. LiteLLM（Part22）で自動フォールバック
2. 緊急の場合、手動で軽量モデルに切り替え
3. Evidenceに「予算オーバー・切り替え理由」を記録

**エスカレーション**: 予算オーバーが常態化する場合、Part22で予算設定の見直し。

---

### 例外4: 成果物フォーマットが遵守されていない
**対処**:
1. フォーマット違反箇所を特定
2. 正しいフォーマットに修正
3. Verifyでフォーマットチェックを実施
4. Evidenceに「フォーマット修正」を記録

**エスカレーション**: 違反が頻発する場合、R-2103の見直し。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2101: 工程別AI割当の遵守確認
**判定条件**: Evidenceに各工程のAI割当が記録され、R-2101に従っているか
**合否**: 違反があれば Fail
**実行方法**: `evidence/` の作業ログをスキャン
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_ai_assignment.md`

---

### V-2102: 成果物フォーマットの確認
**判定条件**: 各工程の成果物がR-2103のフォーマットに従っているか
**合否**: フォーマット違反があれば Fail
**実行方法**: `checks/verify_artifact_format.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_artifact_format.md`

---

### V-2103: フォールバック記録の確認
**判定条件**: フォールバック実施時にEvidenceに記録があるか
**合否**: 記録なしなら警告（Fail ではない）
**実行方法**: `evidence/` のフォールバック記録を確認
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_fallback_check.md`

---

### V-2104: 工程間引き継ぎの確認
**判定条件**: 工程間で成果物・Evidence・未決事項・DoDが引き継がれているか
**合否**: 引き継ぎ漏れがあれば Fail
**実行方法**: `evidence/` の引き継ぎ記録を確認
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_handover_check.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2101: 各工程のAI割当記録
**保存内容**:
- 工程名
- 主担当/副担当/軽量/フォールバックのAI
- 使用理由
- 成果物パス

**参照パス**: `evidence/ai_assignment/YYYYMMDD_HHMMSS_<process>.md`
**保存場所**: `evidence/ai_assignment/`

---

### E-2102: 成果物
**保存内容**:
- Spec: PRD / Glossary / AC / Not-in-scope / 失敗モード
- Research: 調査レポート / 選定候補リスト / 比較表 / 参照リンク
- Design: ADR / API契約 / 状態遷移 / 失敗モード一覧 / テスト計画 / DoD
- Build: 実装コード / テストコード / diff / manifest
- Fix: レビューレポート / 修正パッチ / Verifyレポート
- Verify: テスト結果 / カバレッジ / 回帰レポート
- Release/Operate: リリースノート / SBOM / 運用ダッシュボード / メトリクス

**参照パス**: `VIBEKANBAN/` 各レーン / `evidence/artifacts/`
**保存場所**: `VIBEKANBAN/`, `evidence/artifacts/`

---

### E-2103: フォールバック記録
**保存内容**:
- フォールバック実施日時
- 元のAI・代替AI
- フォールバック理由（レート制限/障害/予算オーバー）
- 期間

**参照パス**: `evidence/fallback/YYYYMMDD_HHMMSS_fallback.md`
**保存場所**: `evidence/fallback/`

---

### E-2104: 工程間引き継ぎ記録
**保存内容**:
- 前工程・次工程
- 引き継ぎ成果物
- 未決事項
- DoDチェック結果

**参照パス**: `evidence/handover/YYYYMMDD_HHMMSS_handover_<from>_<to>.md`
**保存場所**: `evidence/handover/`

---

## 10. チェックリスト

- [x] 本Part21 が全12セクション（0〜12）を満たしているか
- [x] 工程別AI割当（R-2101）が明記されているか
- [x] フォールバックの型（R-2102）が明記されているか
- [x] 成果物フォーマット（R-2103）が明記されているか
- [x] 高精度を使う工程の固定（R-2104）が明記されているか
- [x] 工程間の引き継ぎ（R-2105）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-2101〜V-2104）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2101〜E-2104）が参照パス付きで記述されているか
- [ ] 本Part21 を読んだ人が「どの工程でどのAIを使うか」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2101: 新しいAIモデルの追加手順
**問題**: GPT-6や新しいモデルが登場した場合、どのように工程割当に追加するか不明。
**影響Part**: Part21（本Part）、Part25（統合ツール構成）
**暫定対応**: Part25で評価→ADRで決定→Part21を更新。

---

### U-2102: ローカルLLMの具体的なモデル選定
**問題**: フォールバック先のローカルLLM（Ollama/LM Studio）でどのモデルを使うか不明。
**影響Part**: Part21（本Part）、Part25（統合ツール構成）
**暫定対応**: 環境依存としてPart25で明記。

---

### U-2103: 工程の追加・分割の基準
**問題**: 新しい工程（例：Security Review）を追加する場合の基準が不明。
**影響Part**: Part21（本Part）
**暫定対応**: ADRで決定→Part21を更新。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part01.md](Part01.md) : 目標・DoD
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part05.md](Part05.md) : Core4運用
- [docs/Part09.md](Part09.md) : Permission Tier
- [docs/Part10.md](Part10.md) : Verify Gate
- [docs/Part22.md](Part22.md) : 制限耐性設計
- [docs/Part23.md](Part23.md) : 回帰防止設計
- [docs/Part24.md](Part24.md) : 可観測性設計
- [docs/Part25.md](Part25.md) : 統合ツール構成

### sources/
- _imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md : 原文（「3. 工程別AI割当」「10. 付録：フォールバックの"型"」）
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_ai_assignment.ps1` : 工程別AI割当確認（未作成）
- `checks/verify_artifact_format.ps1` : 成果物フォーマット確認（未作成）

### evidence/
- `evidence/ai_assignment/` : 各工程のAI割当記録
- `evidence/artifacts/` : 各工程の成果物
- `evidence/fallback/` : フォールバック記録
- `evidence/handover/` : 工程間引き継ぎ記録

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
