# Part 24：可観測性設計（Langfuseによるトレース・評価・コスト・改善ループ）

## 0. このPartの位置づけ
- **目的**: "どこで壊れたか"が一撃で分かるように、トレース・評価・コスト・遅延を追跡し、改善ループを回す
- **依存**: [Part10](Part10.md)（Verify Gate）、[Part21](Part21.md)（工程別AI割当）、[Part22](Part22.md)（制限耐性）、[Part23](Part23.md)（回帰防止）
- **影響**: 全AI使用工程・コスト管理・障害対応・品質改善

---

## 1. 目的（Purpose）

本 Part24 は **可観測性の統合** を通じて、以下を保証する：

1. **一撃特定**: どのモデル・どのプロンプト・どのツール呼び出しで失敗したか即座に特定
2. **再現可能**: "改善の再現"ができる（トレースにモデル・プロンプト・コンテキスト・コスト・遅延を記録）
3. **コスト可視**: 工程タグ別・モデル別のコスト消費を追跡
4. **改善ループ**: 失敗分析から改善までのサイクルを確立

**根拠**: 最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md）「2.6 可観測性（壊れた場所を一撃で特定）」「4.5 Langfuseで"どこで壊れたか"を一撃で分かるようにする」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- Langfuseによるトレース・評価・コスト管理
- 全AI使用工程（Spec/Research/Design/Build/Fix/Verify/Release/Operate）の追跡
- 失敗分析・改善ループ
- ダッシュボードによる可視化

### Out of Scope（適用外）
- Langfuse以外の可観測性ツール（他ツールを使う場合はADRで決定）

---

## 3. 前提（Assumptions）

1. **Langfuseサーバ**が稼働している（セルフホストまたはクラウド）
2. **各AIエージェント**がLangfuseにトレースを送信する
3. **工程タグ**（Spec/Design/Build等）が付与されている
4. **Part10（Verify Gate）** との連携が確立されている

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Langfuse**: [glossary/GLOSSARY.md#Langfuse](../glossary/GLOSSARY.md)（LLMのトレース・評価・コスト管理ツール）
- **トレース（Trace）**: AI実行の記録（モデル・プロンプト・コンテキスト・出力・コスト・遅延）
- **スパン（Span）**: トレース内の個別実行単位
- **工程タグ**: Spec/Design/Build等の工程を識別するタグ
- **評価（Evaluation）**: トレースに対する品質評価（スコア・判定）
- **改善ループ**: 失敗分析→改善→再評価のサイクル

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2401: トレース記録の必須項目【MUST】

Langfuseは以下の項目を記録する：

#### 共通項目（全工程共通）
- **trace_id**: トレースの一意識別子
- **timestamp**: 実行日時
- **model**: モデル名（例: claude-opus, gpt-5.2）
- **prompt**: プロンプト内容（またはバージョンID）
- **context**: コンテキスト（参照ファイル・タスクID等）
- **output**: 出力結果
- **cost**: コスト（USD）
- **latency**: 遅延（ms）

#### 工程別項目
- **工程タグ**: Spec/Research/Design/Build/Fix/Verify/Release/Operate
- **AI名**: ChatGPT/Claude/Gemini/Z.ai
- **ユーザID**: 実行者（人間またはエージェント）

**根拠**: rev.md「4.5 Langfuseで"どこで壊れたか"を一撃で分かるようにする」
**違反例**: トレース未記録でのAI実行 → 禁止。

---

### R-2402: 失敗時の自動記録【MUST】

失敗時は以下を自動記録する：

#### 失敗分類
1. **Spec系**: 前提が違う／受入基準が曖昧
2. **依存/環境系**: バージョン衝突／OS差
3. **実装系**: 局所バグ
4. **テスト系**: テスト不足／壊れたテスト
5. **モデル系**: レート制限・障害・予算オーバー

#### 記録項目
- 失敗分類
- エラーメッセージ
- スタックトレース（該当時）
- 関連trace_id
- 対処内容

**根拠**: rev.md「4.5 Langfuseで"どこで壊れたか"を一撃で分かるようにする」

---

### R-2403: コスト追跡の実装【MUST】

Langfuseは以下のコスト追跡を実装する：

#### 工程タグ別コスト
- Spec/Research/Design/Build/Fix/Verify/Release/Operate 別の消費額
- 月次集計・傾向分析

#### モデル別コスト
- claude-opus, gpt-5.2, gemini-3-pro 等の消費額
- 月次集計・傾向分析

#### アラート
- 予算の80%, 90%, 100%到達時にアラート
- 異常消費（急増等）を検出

**根拠**: rev.md「4.5 Langfuseで"どこで壊れたか"を一撃で分かるようにする」「7. コスト最適化」

---

### R-2404: 評価の実装【MUST】

Langfuseは以下の評価を実装する：

#### 自動評価
- promptfooとの連携（Part23）
- スコア・判定の記録

#### 手動評価
- 人間によるフィードバック
- スコア（1〜5）・判定（Pass/Fail）

#### 評価集計
- 平均スコア・Pass率
- 傾向分析（前回比）

---

### R-2405: 改善ループの確立【SHOULD】

以下の改善ループを確立する：

1. **失敗分析**: Langfuseで失敗トレースを特定
2. **原因究明**: 失敗分類・エラーメッセージ・関連trace_idから原因を特定
3. **改善策立案**: ADRで改善策を決定
4. **改善実施**: プロンプト修正・モデル変更・コード修正
5. **再評価**: Langfuseで結果を確認・評価記録

---

### R-2406: ダッシュボードの活用【SHOULD】

Langfuseのダッシュボードで以下を可視化する：

#### リアルタイム監視
- 実行中のトレース
- エラー率
- コスト消費
- 遅延

#### 定期レポート
- 日次・週次・月次レポート
- 品質トレンド
- コストトレンド

#### カスタムダッシュボード
- 工程別ダッシュボード
- モデル別ダッシュボード
- 失敗分析ダッシュボード

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: Langfuseの初期設定
1. Langfuseサーバのセットアップ（セルフホストまたはクラウド）
2. APIキーの取得・環境変数設定
3. 各AIエージェントにLangfuse SDKを統合
4. トレース送信の確認

### 手順B: トレース記録の実装
1. 各工程でトレース送信を実装:
   ```python
   from langfuse import Langfuse
   langfuse = Langfuse()

   trace = langfuse.trace(
       name="Spec生成",
       metadata={
           "process": "Spec",
           "ai": "Claude Opus",
           "user_id": "user123",
           "task_id": "TICKET-001"
       }
   )

   span = trace.span(
       name="PRD作成",
       input={"prompt": spec_prompt},
       output={"prd": prd_output},
       metadata={
           "model": "claude-opus",
           "cost": 0.05,
           "latency": 1500
       }
   )

   span.end()
   ```

### 手順C: 失敗時の記録
1. 例外ハンドリングで失敗をキャッチ
2. Langfuseに失敗トレースを記録:
   ```python
   try:
       result = ai_execute()
   except Exception as e:
       trace = langfuse.trace(
           name="Spec生成失敗",
           metadata={
               "process": "Spec",
               "error_type": "Spec系",
               "error_message": str(e),
               "stack_trace": traceback.format_exc()
           }
       )
       trace.end(status="error")
   ```

### 手順D: 改善ループの実行
1. 失敗分析: Langfuseダッシュボードで失敗トレースを確認
2. 原因究明: 失敗分類・エラーメッセージ・関連trace_idから原因を特定
3. 改善策立案: ADRで改善策を決定
4. 改善実施: プロンプト修正・モデル変更・コード修正
5. 再評価: Langfuseで結果を確認・評価記録

### 手順E: ダッシュボードの活用
1. リアルタイム監視: 実行中のトレース・エラー率・コスト消費・遅延を確認
2. 定期レポート: 日次・週次・月次レポートを確認
3. カスタムダッシュボード: 工程別・モデル別・失敗分析用ダッシュボードを作成

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: Langfuseサーバダウン
**対処**:
1. トレース送信をスキップ（AI実行は継続）
2. Evidenceに「Langfuseダウン・トレース未記録」を記録
3. 復帰後、再送を試みる

**エスカレーション**: 長期ダウンが予想される場合、ADRで暫定運用を決定。

---

### 例外2: トレース記録失敗
**対処**:
1. エラー内容を確認（APIキー問題？ネットワーク問題？）
2. 再試行（最大3回）
3. 復帰しない場合、Evidenceに「トレース記録失敗」を記録

**エスカレーション**: 頻発する場合、Langfuse設定の見直し。

---

### 例外3: コスト異常消費
**対処**:
1. 即座に該当モデルを停止（Part22）
2. 原因を特定（無限ループ？誤ったモデル選択？）
3. ADRで「コスト異常消費・原因・対策」を記録
4. 再発防止策を検討

**エスカレーション**: 頻発する場合、Part22（制限耐性）の見直し。

---

### 例外4: 改善策が効果なし
**対処**:
1. 改善前後のトレースを比較
2. 別の改善策を検討
3. ADRで「改善失敗・別策検討」を記録

**エスカレーション**: 3回以上改善失敗する場合、設計見直し。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2401: トレース記録の確認
**判定条件**: 全AI実行でトレースが記録されているか
**合否**: 未記録があれば Fail
**実行方法**: `checks/verify_langfuse_trace.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_langfuse_trace.md`

---

### V-2402: 失敗記録の確認
**判定条件**: 失敗時に自動記録されているか
**合否**: 未記録があれば Fail
**実行方法**: `checks/verify_failure_recording.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_failure_recording.md`

---

### V-2403: コスト追跡の確認
**判定条件**: 工程タグ別・モデル別のコストが追跡されているか
**合否**: 未追跡があれば Fail
**実行方法**: `checks/verify_cost_tracking.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_cost_tracking.md`

---

### V-2404: 評価の確認
**判定条件**: 自動評価・手動評価が実施されているか
**合否**: 未評価があれば警告（Fail ではない）
**実行方法**: `checks/verify_evaluation.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_evaluation.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2401: トレースデータ
**保存内容**: 全AI実行のトレース（trace_id・モデル・プロンプト・コンテキスト・出力・コスト・遅延）
**参照パス**: Langfuseダッシュボード（https://langfuse.example.com）
**保存場所**: Langfuseサーバ

---

### E-2402: 失敗記録
**保存内容**: 失敗分類・エラーメッセージ・関連trace_id・対処内容
**参照パス**: Langfuseダッシュボード（失敗分析フィルタ）
**保存場所**: Langfuseサーバ

---

### E-2403: コストレポート
**保存内容**: 工程タグ別・モデル別のコスト消費・月次集計・傾向分析
**参照パス**: `evidence/cost/YYYYMMDD_cost_report.md`
**保存場所**: `evidence/cost/`

---

### E-2404: 評価レポート
**保存内容**: 平均スコア・Pass率・傾向分析・改善提案
**参照パス**: `evidence/evaluation/YYYYMMDD_evaluation_report.md`
**保存場所**: `evidence/evaluation/`

---

### E-2405: 改善記録
**保存内容**: 失敗分析・原因究明・改善策・再評価結果
**参照パス**: `evidence/improvement/YYYYMMDD_improvement.md`
**保存場所**: `evidence/improvement/`

---

## 10. チェックリスト

- [x] 本Part24 が全12セクション（0〜12）を満たしているか
- [x] トレース記録の必須項目（R-2401）が明記されているか
- [x] 失敗時の自動記録（R-2402）が明記されているか
- [x] コスト追跡の実装（R-2403）が明記されているか
- [x] 評価の実装（R-2404）が明記されているか
- [x] 改善ループの確立（R-2405）が明記されているか
- [x] ダッシュボードの活用（R-2406）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-2401〜V-2404）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2401〜E-2405）が参照パス付きで記述されているか
- [ ] 本Part24 を読んだ人が「どこで壊れたかが一撃で分かる」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2401: Langfuseサーバのホスティング先
**問題**: セルフホストかクラウドか未定。
**影響Part**: Part24（本Part）
**暫定対応**: 環境依存としてADRで決定。

---

### U-2402: トレースの保持期間
**問題**: トレースデータをどの期間保持するか不明。
**影響Part**: Part24（本Part）
**暫定対応**: 90日保持・アーカイブ移動。

---

### U-2403: ダッシュボードの具体的なレイアウト
**問題**: どのダッシュボードをどのようにレイアウトするか未定。
**影響Part**: Part24（本Part）
**暫定対応**: 運用で調整。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part10.md](Part10.md) : Verify Gate
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part22.md](Part22.md) : 制限耐性設計
- [docs/Part23.md](Part23.md) : 回帰防止設計

### sources/
- _imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md : 原文（「2.6 可観測性」「4.5 Langfuseで"どこで壊れたか"を一撃で分かるようにする」）
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_langfuse_trace.ps1` : トレース記録確認（未作成）
- `checks/verify_failure_recording.ps1` : 失敗記録確認（未作成）
- `checks/verify_cost_tracking.ps1` : コスト追跡確認（未作成）
- `checks/verify_evaluation.ps1` : 評価確認（未作成）

### evidence/
- `evidence/cost/` : コストレポート
- `evidence/evaluation/` : 評価レポート
- `evidence/improvement/` : 改善記録

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
- Langfuseダッシュボード: https://langfuse.example.com（環境依存）
