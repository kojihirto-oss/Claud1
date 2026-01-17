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
   - 公式ドキュメント: [LiteLLM Documentation](https://docs.litellm.ai/docs/)
   - [LiteLLM GitHub](https://github.com/berriai/litellm)
2. **各AIプロバイダのAPIキー**が環境変数または設定ファイルに保存されている
3. **工程タグ**（Spec/Design/Build/Review等）が付与されている
4. **予算上限**が設定されている（モデル別・工程タグ別）
5. **Part21（工程別AI割当）**のフォールバック順に従う
6. **コスト最適化ベストプラクティス**が策定されている
   - [LLM Cost Optimization: Complete Guide](https://ai.koombea.com/blog/llm-cost-optimization) : コスト最適化包括ガイド
   - [LLM Cost Control: Practical LLMOps Strategies](https://radicalbit.ai/resources/blog/cost-control/) : 実用的LLMOps戦略
   - [API Rate Limits Explained: Best Practices](https://orq.ai/blog/api-rate-limit) : レート制限ベストプラクティス

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

## 6.1 運用ランブック（制限耐性の完全運用）

本節は、Part22の制限耐性設計を「日常運用で実際にどう扱うか」について、具体的な手順・閾値・判断基準を定める。

### 6.1.1 フェイルオーバー条件（具体的な閾値・トリガー）

#### (1) 予算ベースのフェイルオーバー

| 予算消費率 | アクション | 自動/手動 | 通知先 |
|-----------|----------|---------|--------|
| 80% | Warning通知 | 自動 | Slack #ai-budget-alert |
| 90% | Critical通知 + ログ記録 | 自動 | Slack #ai-budget-alert, Email |
| 100% | 該当モデル停止 + フォールバック | 自動 | Slack #ai-budget-alert, Email, HumanGate |
| 110%（緊急） | 全体停止 | 自動 | 全チャンネル |

**根拠**: LiteLLM公式ドキュメント `litellm_settings` のアラート機能（[sources/research_inbox/20260117_primary/litellm_proxy_configs.md](../../sources/research_inbox/20260117_primary/litellm_proxy_configs.md)）

#### (2) レート制限（RPM/TPM）ベースのフェイルオーバー

| 状況 | 検出方法 | アクション | 復帰条件 |
|------|---------|----------|---------|
| RPM制限超過 | HTTP 429 | 即座に代替モデルに切り替え | クールダウン期間終了後（デフォルト30秒） |
| TPM制限超過 | HTTP 429 | 即座に代替モデルに切り替え | クールダウン期間終了後 |
| 連続失敗 | allowed_fails回数到達 | クールダウン発動 + 代替モデル | cooldown_time経過 + ヘルスチェックOK |

**LiteLLM設定例**:
```yaml
litellm_settings:
  num_retries: 3              # リトライ回数
  request_timeout: 10         # タイムアウト（秒）
  allowed_fails: 3            # クールダウン発動閾値
  cooldown_time: 30           # クールダウン時間（秒）
```

**根拠**: [sources/research_inbox/20260117_primary/litellm_fallbacks_reliability.md](../../sources/research_inbox/20260117_primary/litellm_fallbacks_reliability.md)

#### (3) モデル停止・障害ベースのフェイルオーバー

| 事象 | 検出方法 | アクション | 復帰条件 |
|------|---------|----------|---------|
| APIサーバーダウン | 3回リトライ失敗 | 代替モデルに切り替え | ヘルスチェックOK（5分おき） |
| コンテンツポリシー違反 | 特定エラーコード | content_policy_fallbacks 実行 | 手動確認後復帰 |
| コンテキストウィンドウ超過 | 特定エラーコード | context_window_fallbacks 実行 | 手動確認後復帰 |

**根拠**: LiteLLM 3種類のフォールバック（[sources/research_inbox/20260117_primary/litellm_fallbacks_reliability.md](../../sources/research_inbox/20260117_primary/litellm_fallbacks_reliability.md)）

---

### 6.1.2 手動介入点（HumanGateの具体的な手順）

#### HumanGate判断フロー

```
予算100%到達 / 全モデルダウン / 予期せぬエラー
         ↓
    自動通知発信
         ↓
    HumanGate判断
         ↓
    ┌─────┴─────┐
    ↓           ↓
継続判断      停止判断
    ↓           ↓
代替モデルへ    全作業停止
手動切り替え     ↓
    ↓       原因調査・ADR作成
Part24に記録
```

#### 判断基準

| 状況 | 継続条件 | 停止条件 |
|------|---------|---------|
| 予算100%到達 | 代替モデルで業務に支障ない | 代替モデルも利用不可 / 精度要件を満たせない |
| 特定モデルダウン | フォールバック先が正常稼働 | 全モデルダウン / ローカルLLMも利用不可 |
| 予期せぬエラー | エラー影響範囲が限定されている | システム全体に影響 / セキュリティリスクあり |

#### HumanGate実施手順

1. **通知受信**: Slack/Emailでアラートを受信
2. **状況確認**: Part24ダッシュボードで以下を確認
   - 予算消費状況（モデル別・工程タグ別）
   - フォールバック履歴
   - エラーログ
3. **判断**: 上記判断基準に基づき継続か停止かを決定
4. **アクション実施**:
   - 継続場合: 代替モデルへ手動切り替え
   - 停止場合: 全作業停止 + 原因調査
5. **記録**: Part24に「HumanGate実施・判断結果」を記録

**根拠**: R-2206（予算オーバー時の手動フォールバック）

---

### 6.1.3 コスト上限（工程別の具体例）

#### 月次予算配分例（総予算 $100）

| 工程タグ | 予算上限 | 主モデル | 想定リクエスト数/月 | コスト/リクエスト |
|---------|---------|---------|-------------------|------------------|
| Spec | $15 | Claude Opus | 500 | $0.03 |
| Design | $15 | Claude Opus | 500 | $0.03 |
| Build | $20 | Codex (GPT-5.2) | 2,000 | $0.01 |
| Review | $10 | Claude Sonnet | 1,000 | $0.01 |
| Fix | $5 | Claude Sonnet | 500 | $0.01 |
| Verify | $5 | Gemini Flash | 2,000 | $0.0025 |
| Release | $5 | Gemini Flash | 2,000 | $0.0025 |
| Operate | $5 | Gemini Flash | 2,000 | $0.0025 |
| 雑務・その他 | $20 | ローカルLLM | - | $0 |

#### 予算超過時のフォールバック戦略

| 工程タグ | 予算超過時の代替モデル | 精度低下影響 |
|---------|---------------------|-------------|
| Spec | Claude Sonnet | 中（重要工程のため、早期予算警告必須） |
| Design | Claude Sonnet | 中（重要工程のため、早期予算警告必須） |
| Build | Gemini 3 Pro | 小〜中 |
| Review | Gemini 3 Pro | 小 |
| Fix | Gemini Flash | 小 |
| Verify | ローカルLLM | 検証用途のため許容 |
| Release | ローカルLLM | 単純作業のため許容 |
| Operate | ローカルLLM | 単純作業のため許容 |

**根拠**: R-2201（用途別ルーティングの固定）、R-2202（予算管理の自動化）

---

### 6.1.4 ログの見方（Part24 Langfuse連携の詳細）

#### Langfuseダッシュボードで確認する項目

| 確認項目 | 場所 | 確認内容 |
|---------|------|---------|
| **予算消費** | Budgetタブ | モデル別・工程タグ別の累積消費額、予算残高 |
| **フォールバック履歴** | Tracesタブ | フォールバック発生日時、元モデル→代替モデル、理由 |
| **エラーログ** | Observabilityタブ | エラーコード、回数、頻度 |
| **レイテンシ** | Metricsタブ | モデル別の平均応答時間、P95/P99 |
| **スループット** | Metricsタブ | RPM/TPMの推移、制限接近状況 |

#### 重大なログパターンと対応

| ログパターン | 意味 | 即時対応 |
|------------|------|---------|
| `HTTP 429` が1分間に5回以上 | レート制限接近 | LiteLLM設定のRPM制限値確認 |
| `fallback triggered` が連続 | 特定モデルが不安定 | 該当モデルの一時無効化 |
| `budget 100% reached` | 予算枯渇 | HumanGate判断 |
| `all models failed` | 全モデルダウン | ローカルLLMへ切り替え + 原因調査 |

#### ログ確認の推奨頻度

| 頻度 | 実施者 | 確認内容 |
|------|-------|---------|
| リアルタイム | 自動 | 重大アラート（予算100%、全モデルダウン） |
| 1日1回 | 運用担当 | 予算消費状況、エラー傾向 |
| 1週1回 | リーダー | コストトレンド、フォールバック頻度分析 |

**根拠**: Part24（可観測性設計）、R-2203（レート制限・障害への自動フォールバック）

---

### 6.1.5 復旧Runbook（手動復旧手順）

#### 復旧シナリオ別手順

##### シナリオ1: 特定モデルが復帰した場合

1. **復帰検出**: LiteLLMが自動でヘルスチェック（5分おき）
2. **自動切り戻し**: 復帰確認後、次のリクエストから元のモデルを使用
3. **記録**: Part24に「自動復帰実施」を記録
4. **確認**: ダッシュボードで元のモデルの使用状況を確認

**根拠**: R-2205（自動復帰の実装）

##### シナリオ2: 予算オーバーから復旧（翌月/予算増額）の場合

1. **予算リセット**: 月初または予算増額実施
2. **モデル手動再有効化**:
   ```bash
   # LiteLLM設定ファイルで該当モデルを再有効化
   litellm --config litellm_config.yaml --reload
   ```
3. **動作確認**: テストリクエストを送信し正常応答を確認
4. **Part24記録**: 「予算リセット・モデル再有効化」を記録

##### シナリオ3: 予算設定ミスによる誤停止から復旧

1. **原因特定**: Part24ログで予算設定ミスの箇所を特定
2. **設定修正**: litellm_config.yaml の予算設定を修正
3. **LiteLLM再起動**: `litellm --config litellm_config.yaml --port 4000 --reload`
4. **ADR作成**: 「予算設定ミス・修正内容」を記録（例外2の対処）
5. **再発防止策**: 予算設定プロセスの見直し

##### シナリオ4: 全モデルダウンから復旧

1. **ローカルLLMで稼働継続**: 最後の砦としてローカルLLMを使用
2. **原因調査**: プロバイダステータスページ、ネットワーク設定を確認
3. **復帰待機**: プロバイダ復帰を待機
4. **復帰確認**: 各モデルのヘルスチェックを実施
5. **段階的切り戻し**: 高優先度モデルから順に元のモデルに戻す
6. **ADR作成**: 「全モデルダウン・復旧手順」を記録

#### 復旧確認チェックリスト

- [ ] 元のモデルが正常応答しているか
- [ ] 予算消費が正常範囲内か
- [ ] フォールバック履歴に異常がないか
- [ ] Part24に復旧記録が残っているか
- [ ] 必要なADRが作成されているか

**根拠**: 例外処理（例外1〜4）、R-2206（予算オーバー時の手動フォールバック）

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

### LiteLLM公式一次情報
- [LiteLLM Documentation](https://docs.litellm.ai/docs/) : LiteLLM公式ドキュメント
- [LiteLLM GitHub Repository](https://github.com/berriai/litellm) : LiteLLM公式リポジトリ
- [LiteLLM Fallbacks - Proxy Reliability](https://docs.litellm.ai/docs/proxy/reliability) : フォールバック設定
- [LiteLLM Routing, Loadbalancing & Fallbacks](https://docs.litellm.ai/docs/routing-load-balancing) : ルーティング・ロードバランシング
- [Model Fallbacks w/ LiteLLM](https://docs.litellm.ai/docs/tutorials/model_fallbacks) : モデルフォールバックチュートリアル

### コスト最適化・レート制限一次情報
- [LLM Cost Optimization: Complete Guide to Reducing Costs](https://ai.koombea.com/blog/llm-cost-optimization) : LLMコスト最適化包括ガイド
- [LLM Cost Control: Practical LLMOps Strategies](https://radicalbit.ai/resources/blog/cost-control/) : 実用的LLMOps戦略
- [API Rate Limits Explained: Best Practices](https://orq.ai/blog/api-rate-limit) : レート制限ベストプラクティス
- [How to Reduce LLM Spending by 30% Without Sacrificing Performance](https://medium.com/@future_agi/how-to-reduce-llm-spending-by-30-without-sacrificing-performance-88101ddf8953) : コスト削減戦略
- [End-to-End Optimization for Cost-Efficient LLMs](https://arxiv.org/html/2504.13471v2) : コスト効率の良いLLMの最適化（学術論文）

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
