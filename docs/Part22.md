# Part 22：制限耐性設計（LiteLLMによる予算・レート・フォールバックの自動化）

## 0. このPartの位置づけ
- **目的**: 予算・レート制限・障害が発生しても作業が止まらないよう、自動フォールバック・ルーティングを設計する
- **依存**: [Part03](Part03.md)（Core4）、[Part21](Part21.md)（工程別AI割当）、[Part24](Part24.md)（可観測性）
- **影響**: 全AI使用工程・予算管理・障害対応・コスト最適化

---

## 1. 目的（Purpose）

本 Part22 は **制限耐性の自動化** を通じて、以下を保証する：

1. **止まらない**: レート制限・障害・上限到達が来ても、自動で代替に迂回し作業継続
2. **予算可視**: 工程タグ別・モデル別の予算消費を追跡し、予算オーバーを防止
3. **コスト最適**: 重要工程にだけ高コストモデルを使い、重要でない工程は自動で軽量へ
4. **自動復帰**: 障害復帰後、自動で元のモデルに戻す

**根拠**: 最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md）「2.4 モデル運用の配管（制限耐性の心臓部）」「4.4 LiteLLMで"制限耐性"を自動化」「7. コスト最適化」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- LiteLLM（Gateway/Router）による予算・レート・フォールバック管理
- 用途別ルーティング（高精度枠/実装枠/節約枠）
- 予算タグ別・モデル別の予算管理
- 自動フォールバック・自動復帰

### Out of Scope（適用外）
- LiteLLM以外のGatewayツール（Azure OpenAI等）の詳細
- 個別プロバイダのAPI仕様

---

## 3. 前提（Assumptions）

1. **LiteLLMがGateway/Router**として稼働している
2. **各AIプロバイダのAPIキー**が環境変数または設定ファイルに保存されている
3. **工程タグ**（Spec/Design/Build/Review等）が付与されている
4. **予算上限**が設定されている（モデル別・工程タグ別）
5. **Part21（工程別AI割当）**のフォールバック順に従う

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **LiteLLM**: [glossary/GLOSSARY.md#LiteLLM](../glossary/GLOSSARY.md)（複数AIプロバイダを統合するGateway/Router）
- **フォールバック**: メインモデルが使えない場合の代替モデルへの自動切り替え
- **ルーティング**: 用途に応じて適切なモデルに振り分ける機能
- **工程タグ**: Spec/Design/Build/Review等の工程を識別するタグ
- **予算上限**: モデル別・工程タグ別に設定されたコスト上限
- **レート制限**: APIの呼び出し回数制限

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2201: 用途別ルーティングの固定【MUST】

LiteLLMは以下の用途別ルーティングに従う：

#### 高精度枠（Spec/Design/Review）
- **主モデル**: Claude Opus / Gemini 3 Pro
- **予算上限**: 高めに設定（例：月$50）
- **フォールバック**: Claude Sonnet → Gemini 3 Pro →（節約）Flash/GLM → ローカル

#### 実装枠（Build）
- **主モデル**: Codex（GPT-5.2）/ Claude Sonnet
- **予算上限**: 中程度（例：月$30）
- **フォールバック**: Claude Sonnet → Gemini 3 Pro → Flash/GLM → ローカル

#### 節約枠（雑務・整形・候補列挙）
- **主モデル**: Gemini Flash / GLM
- **予算上限**: 低めに設定（例：月$10）
- **フォールバック**: ローカル

**根拠**: rev.md「4.4 LiteLLMで"制限耐性"を自動化」「7. コスト最適化」
**違反例**: 雑務で高精度モデルを使う → 予算オーバーのため、禁止。

---

### R-2202: 予算管理の自動化【MUST】

LiteLLMは以下の予算管理機能を有効にする：

#### 予算タグ別管理
- **工程タグ**: Spec, Design, Build, Review, Fix, Verify, Release, Operate
- **モデル別予算**: 各モデルの月次予算上限を設定
- **アラート**: 予算の80%, 90%, 100%到達時にアラート通知

#### 自動停止
- 予算100%到達時、該当モデルの使用を自動停止
- フォールバック順に従って代替モデルに切り替え

**根拠**: rev.md「7. コスト最適化（精度を落とさず、制限も超えにくくする）」

---

### R-2203: レート制限・障害への自動フォールバック【MUST】

LiteLLMは以下の自動フォールバックを実行する：

#### レート制限検出時
1. 即座に代替モデルに切り替え（Part21 R-2102のフォールバック順）
2. Part24（Langfuse）に「レート制限発生・フォールバック実施」を記録
3. 元のモデルが復帰したら、自動で戻す

#### 障害検出時
1. 3回リトライ（指数バックオフ: 2秒, 4秒, 8秒）
2. 復帰しない場合、代替モデルに切り替え
3. Part24に「障害発生・フォールバック実施」を記録
4. 元のモデルが復帰したら、自動で戻す

**根拠**: rev.md「4.4 LiteLLMで"制限耐性"を自動化」

---

### R-2204: フォールバック順の遵守【MUST】

フォールバックは **Part21 R-2102（フォールバックの型）** に厳密に従う：

- Spec/Design: Claude Opus → Claude Sonnet → Gemini 3 Pro → Flash/GLM → ローカル
- Build: Codex → Claude Sonnet → Gemini 3 Pro → Flash/GLM → ローカル
- 雑務: Flash/GLM →（必要時）Sonnet/Pro

**違反例**: 独自のフォールバック順を設定する → 禁止。

---

### R-2205: 自動復帰の実装【SHOULD】

LiteLLMは以下の自動復帰機能を実装する：

1. **ヘルスチェック**: 元のモデルの復帰を定期確認（例: 5分おき）
2. **自動切り戻し**: 復帰確認後、次のリクエストから元のモデルを使用
3. **復帰記録**: Part24（Langfuse）に「自動復帰実施」を記録

**根拠**: rev.md「4.4 LiteLLMで"制限耐性"を自動化」

---

### R-2206: 予算オーバー時の手動フォールバック【MUST】

自動停止が発生した場合：

1. **即座に通知**: Slack/Email等で予算オーバーを通知
2. **手動判断**: HumanGateで継続か停止かを判断
3. **継続の場合**: 代替モデル（軽量またはローカル）に手動切り替え
4. **記録**: Part24に「予算オーバー・手動フォールバック実施」を記録

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: LiteLLMの初期設定
1. LiteLLMをインストール: `pip install litellm`
2. 設定ファイル作成: `litellm_config.yaml`
   - 各AIプロバイダのAPIキーを環境変数から読み込み
   - 用途別ルーティングを設定
   - 予算上限を設定
   - フォールバック順を設定
3. LiteLLM起動: `litellm --config litellm_config.yaml --port 4000`
4. ヘルスチェック: `curl http://localhost:4000/health`

### 手順B: 用途別ルーティングの設定
1. 高精度枠のルーティング設定:
   ```yaml
   router:
     - model: claude-opus
       max_budget: 50
       rpm_limit: 100
       fallback:
         - claude-sonnet
         - gemini-3-pro
         - gemini-flash
         - local/llama3
   ```
2. 実装枠のルーティング設定:
   ```yaml
   router:
     - model: gpt-5.2
       max_budget: 30
       rpm_limit: 200
       fallback:
         - claude-sonnet
         - gemini-3-pro
         - gemini-flash
         - local/llama3
   ```
3. 節約枠のルーティング設定:
   ```yaml
   router:
     - model: gemini-flash
       max_budget: 10
       rpm_limit: 1000
       fallback:
         - local/llama3
   ```

### 手順C: 予算管理の設定
1. モデル別予算上限を設定:
   ```yaml
   budget:
     claude-opus: 50
     gpt-5.2: 30
     gemini-3-pro: 20
     gemini-flash: 10
     glm: 5
   ```
2. 工程タグ別予算上限を設定:
   ```yaml
   tag_budget:
     Spec: 15
     Design: 15
     Build: 20
     Review: 10
     Fix: 5
     Verify: 5
     Release: 5
     Operate: 5
   ```
3. アラート設定（80%, 90%, 100%）:
   ```yaml
   alerts:
     - threshold: 80
       action: notify
     - threshold: 90
       action: warn
     - threshold: 100
       action: stop_and_fallback
   ```

### 手順D: フォールバックの実行
1. LiteLLMが自動でフォールバックを実行
2. Part24（Langfuse）に自動記録
3. 手動確認: ダッシュボードでフォールバック状態を確認
4. 必要に応じて手動介入（予算オーバー等）

### 手順E: 自動復帰の確認
1. LiteLLMが元のモデルの復帰を定期確認
2. 復帰確認後、自動で元のモデルに切り戻し
3. Part24（Langfuse）に「自動復帰」を記録
4. ダッシュボードで復帰状態を確認

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: 全モデルが使えない
**対処**:
1. ローカルLLM（Ollama/LM Studio）が最後の砦
2. Evidenceに「全モデルダウン・ローカルLLM使用」を記録
3. HumanGateで状況を共有

**エスカレーション**: 長期ダウンが予想される場合、ADRで暫定運用を決定。

---

### 例外2: 予算設定ミスによる予算オーバー
**対処**:
1. 即座に該当モデルを停止
2. 予算設定を修正
3. ADRで「予算設定ミス・修正内容」を記録
4. 再発防止策を検討

**エスカレーション**: 頻発する場合、予算設定プロセスの見直し。

---

### 例外3: フォールバックが失敗
**対処**:
1. フォールバック順を確認（Part21 R-2102）
2. 代替モデルのAPIキー・設定を確認
3. 手動でフォールバック実行
4. Evidenceに「フォールバック失敗・手動実施」を記録

**エスカレーション**: 頻発する場合、フォールバック順の見直し。

---

### 例外4: 自動復帰が失敗
**対処**:
1. 元のモデルのヘルスチェックを手動実行
2. 復帰している場合、手動で切り戻し
3. 復帰していない場合、代替モデルを継続使用
4. Evidenceに「自動復帰失敗・手動実施」を記録

**エスカレーション**: 頻発する場合、自動復帰ロジックの見直し。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2201: LiteLLM設定の整合性確認
**判定条件**: litellm_config.yaml がPart22のルールに従っているか
**合否**: 設定違反があれば Fail
**実行方法**: `checks/verify_litellm_config.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_litellm_config.md`

---

### V-2202: 予算管理の有効化確認
**判定条件**: 予算上限・アラート・自動停止が有効になっているか
**合否**: 有効でなければ Fail
**実行方法**: `checks/verify_budget.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_budget_check.md`

---

### V-2203: フォールバック順の遵守確認
**判定条件**: フォールバック順がPart21 R-2102に従っているか
**合否**: 違反があれば Fail
**実行方法**: `checks/verify_fallback_order.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_fallback_order.md`

---

### V-2204: 自動復帰の有効化確認
**判定条件**: 自動復帰機能が有効になっているか
**合否**: 有効でなければ警告（Fail ではない）
**実行方法**: `checks/verify_auto_recovery.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_auto_recovery.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2201: LiteLLM設定ファイル
**保存内容**: litellm_config.yaml（用途別ルーティング・予算管理・フォールバック順）
**参照パス**: `litellm_config.yaml`
**保存場所**: プロジェクトルート

---

### E-2202: 予算消費ログ
**保存内容**:
- モデル別消費額
- 工程タグ別消費額
- 予算残高
- アラート履歴

**参照パス**: `evidence/budget/YYYYMMDD_budget_consumption.md`
**保存場所**: `evidence/budget/`

---

### E-2203: フォールバック記録
**保存内容**:
- フォールバック実施日時
- 元のモデル・代替モデル
- フォールバック理由（レート制限/障害/予算オーバー）
- 期間
- 復帰日時

**参照パス**: `evidence/fallback/YYYYMMDD_HHMMSS_fallback.md`
**保存場所**: `evidence/fallback/`

---

### E-2204: 自動復帰記録
**保存内容**:
- 復帰検出日時
- 元のモデル
- 復帰確認方法

**参照パス**: `evidence/recovery/YYYYMMDD_HHMMSS_recovery.md`
**保存場所**: `evidence/recovery/`

---

## 10. チェックリスト

- [x] 本Part22 が全12セクション（0〜12）を満たしているか
- [x] 用途別ルーティング（R-2201）が明記されているか
- [x] 予算管理の自動化（R-2202）が明記されているか
- [x] レート制限・障害への自動フォールバック（R-2203）が明記されているか
- [x] フォールバック順の遵守（R-2204）が明記されているか
- [x] 自動復帰の実装（R-2205）が明記されているか
- [x] 予算オーバー時の手動フォールバック（R-2206）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-2201〜V-2204）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2201〜E-2204）が参照パス付きで記述されているか
- [ ] 本Part22 を読んだ人が「制限が来ても止まらない」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2201: LiteLLMの具体的な設定ファイル形式
**問題**: litellm_config.yaml の詳細なフォーマットが不明。
**影響Part**: Part22（本Part）
**暫定対応**: LiteLLMの公式ドキュメントを参照。

---

### U-2202: 予算通知の具体的な方法
**問題**: 予算80%, 90%, 100%到達時の通知方法（Slack/Email等）が未定。
**影響Part**: Part22（本Part）
**暫定対応**: 環境依存としてADRで決定。

---

### U-2203: ローカルLLMとの連携方法
**問題**: LiteLLMとローカルLLM（Ollama/LM Studio）の連携方法が不明。
**影響Part**: Part22（本Part）、Part25（統合ツール構成）
**暫定対応**: Part25で明記。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part24.md](Part24.md) : 可観測性設計
- [docs/Part25.md](Part25.md) : 統合ツール構成

### sources/
- _imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md : 原文（「2.4 モデル運用の配管」「4.4 LiteLLMで"制限耐性"を自動化」「7. コスト最適化」）
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_litellm_config.ps1` : LiteLLM設定確認（未作成）
- `checks/verify_budget.ps1` : 予算管理確認（未作成）
- `checks/verify_fallback_order.ps1` : フォールバック順確認（未作成）
- `checks/verify_auto_recovery.ps1` : 自動復帰確認（未作成）

### evidence/
- `evidence/budget/` : 予算消費ログ
- `evidence/fallback/` : フォールバック記録
- `evidence/recovery/` : 自動復帰記録

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
- `litellm_config.yaml` : LiteLLM設定ファイル（プロジェクトルート）
