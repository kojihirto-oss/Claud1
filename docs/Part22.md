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

## 6.5. Runbook：フェイルオーバー条件と判定基準

### 6.5.1. フェイルオーバーをトリガーする条件

LiteLLMは以下の条件を検出した場合、自動的にフォールバックを開始する。

#### HTTPステータスコード別の条件

| ステータスコード | 意味 | 対応 |
|----------------|------|------|
| 429 Too Many Requests | レート制限超過 | 即座に代替モデルにフォールバック |
| 500 Internal Server Error | プロバイダ内部エラー | 3回リトライ後、代替モデルへ |
| 502 Bad Gateway | ゲートウェイエラー | 3回リトライ後、代替モデルへ |
| 503 Service Unavailable | サービス一時停止 | 3回リトライ後、代替モデルへ |
| 504 Gateway Timeout | タイムアウト | 3回リトライ後、代替モデルへ |

#### エラー種別の条件

| エラー種別 | 具体的な症状 | 対応 |
|----------|-------------|------|
| 予算上限到達 | max_budgetに到達 | 即座に代替モデルにフォールバック |
| APIキー無効 | authentication_failed | 該当キーを無効化し代替へ |
| モデル廃止 | model_not_found | 該当モデルを除外し代替へ |
| タイムアウト | request_timeout（30秒以上） | 3回リトライ後、代替モデルへ |
| レート制限 | rate_limit_exceeded | 即座に代替モデルにフォールバック |
| コンテンツフィルタ | content_filter | 別プロバイダの代替モデルへ |

#### 予算関連の条件

- **80%到達**: 警告通知（Slack/Email）を送信
- **90%到達**: 警告通知＋強化モニタリング
- **100%到達**: 該当モデルの使用を自動停止し、代替モデルにフォールバック

**一次情報**: [LiteLLM Fallbacks - Proxy Reliability](https://docs.litellm.ai/docs/proxy/reliability)

---

## 6.6. Runbook：自動フォールバック手順

### 6.6.1. フォールバック実行の流れ

#### ステップ1: エラー検出（LiteLLM自動）

```yaml
# litellm_config.yaml の設定例
fallbacks:
  - claude-opus  # 主モデル
    - claude-sonnet  # 第1代替
    - gemini-2.5-flash  # 第2代替
    - local/llama3  # 最終代替（ローカル）

retry_policy:
  num_retries: 3
  retry_delay: 2  # 秒（指数バックオフ）
  timeout: 30  # 秒
```

#### ステップ2: リトライ実行

1. 同じモデルで3回リトライ（2秒、4秒、8秒の間隔で指数バックオフ）
2. レート制限（429）の場合は即座にフォールバック（リトライなし）
3. 予算上限到達の場合は即座にフォールバック（リトライなし）

#### ステップ3: 代替モデルへの切り替え

1. Part21 R-2102のフォールバック順に従って代替モデルを選択
2. 切り替え時にPart24（Langfuse）に以下を記録：
   - 元のモデル名
   - 代替モデル名
   - フォールバック理由（HTTPステータスコード/エラーメッセージ）
   - 切り替え日時

#### ステップ4: ヘルスチェック開始

1. 元のモデルの復帰を5分おきに確認
2. 復帰したら自動で元のモデルに切り戻し

**一次情報**: [LiteLLM Routing, Loadbalancing & Fallbacks](https://docs.litellm.ai/docs/routing-load-balancing)

---

## 6.7. Runbook：手動介入ポイント（HumanGate）

### 6.7.1. 手動介入が必要な状況

自動フォールバックで対処できない以下の場合、HumanGate（人間の判断）が必要：

#### 介入条件1: 予算設定の見直し

- **トリガー**: 月次予算の80%到達が複数月連続で発生
- **判断項目**:
  1. 使用量の増加が一時的か継続的か
  2. モデル選択が適切か（高精度枠で雑務を使用していないか）
  3. 予算上限を引き上げるか、使用効率を改善するか
- **決定フロー**:
  ```
  予算80%到達（2ヶ月連続）
  → 使用パターン分析（Part24のログ確認）
  → 効率化可能か？
     YES → 使用効率化（工程タグの見直し）
     NO → 予算引き上げのADR作成 → 承認
  ```

#### 介入条件2: 全モデルダウン

- **トリガー**: 全てのクラウドモデルが使用不能
- **判断項目**:
  1. ローカルLLMのキャパシティ確認
  2. 作業の優先順位付け（高精度枠の作業を優先）
  3. 作業の一時停止判断
- **決定フロー**:
  ```
  全クラウドモデルダウン
  → ローカルLLMのリソース確認
  → 重要作業のみ継続か全面停止か
     継続 → ローカルLLMで重要作業のみ実施
     停止 → 障害復旧まで待機（ADR記録）
  ```

#### 介入条件3: 新モデルの追加/削除

- **トリガー**: モデルの廃止/新規リリース
- **判断項目**:
  1. 新モデルの性能/コスト評価
  2. フォールバック順の更新必要性
  3. 予算配分の調整
- **決定フロー**:
  ```
  モデル廃止の通知
  → 代替モデルの調査・評価
  → フォールバック順の更新（ADR作成）
  → 設定変更と検証
  ```

#### 介入条件4: 異常コスト増加

- **トリガー**: 通常の1.5倍以上のコスト増加
- **判断項目**:
  1. 不正使用の有無
  2. 設定ミスの有無
  3. 緊急停止の要否
- **決定フロー**:
  ```
  コスト異常増大（1.5倍以上）
  → Part24ログで原因特定
  → 不正使用 or 設定ミス or 正常な使用増
     不正使用 → 緊急停止＋調査
     設定ミス → 設定修正
     正常な使用増 → 予算引き上げ検討
  ```

**一次情報**: [LiteLLM Budget Manager](https://docs.litellm.ai/docs/budget_manager)

---

## 6.8. Runbook：コスト上限と制御

### 6.8.1. 予算設定の階層構造

```yaml
# 予算設定の階層
budget_levels:
  # レベル1: プロキシ全体
  proxy_level:
    max_budget: 100  # 月次全体予算
    budget_duration: monthly

  # レベル2: モデル別
  model_level:
    claude-opus:
      max_budget: 50
      budget_duration: monthly
    gemini-2.5-flash:
      max_budget: 10
      budget_duration: monthly

  # レベル3: タグ別（工程タグ）
  tag_level:
    Spec:
      max_budget: 15
      budget_duration: monthly
    Design:
      max_budget: 15
      budget_duration: monthly
    Build:
      max_budget: 20
      budget_duration: monthly
    Review:
      max_budget: 10
      budget_duration: monthly

  # レベル4: ユーザー/キー別
  user_level:
    user_1:
      max_budget: 30
      budget_duration: monthly
```

### 6.8.2. アラート設定

| 閾値 | アクション | 通知方法 |
|-----|----------|---------|
| 80% | 警告通知 | Slack + Email |
| 90% | 警告通知 + 強化モニタリング | Slack + Email |
| 95% | 警告通知 + 使用状況レポート | Slack + Email + ダッシュボード |
| 100% | 自動停止 + フォールバック | Slack + Email + 緊急通知 |

### 6.8.3. 例外手順

#### 緊急時の予算一時引き上げ

1. **状況**: 予算100%到達だが、緊急の作業が必要
2. **手順**:
   - ADRで緊急予算承認を申請
   - 承認後、一時的に予算を引き上げ
   - 作業完了後、通常予算に戻す
3. **記録**: Part24に「緊急予算使用実施」を記録

**一次情報**:
- [LiteLLM Budgets, Rate Limits](https://docs.litellm.ai/docs/proxy/users)
- [LiteLLM Tag Budgets](https://docs.litellm.ai/docs/proxy/tag_budgets)
- [LiteLLM Alerting / Webhooks](https://docs.litellm.ai/docs/proxy/alerting)

---

## 6.9. Runbook：ログの見方とトラブルシューティング

### 6.9.1. 確認すべきログと場所

| ログ種別 | 場所 | 確認内容 |
|---------|------|---------|
| 予算消費ログ | `evidence/budget/YYYYMMDD_budget_consumption.md` | モデル別・タグ別の消費額、予算残高 |
| フォールバック記録 | `evidence/fallback/YYYYMMDD_HHMMSS_fallback.md` | フォールバックの理由、元モデル・代替モデル |
| 自動復帰記録 | `evidence/recovery/YYYYMMDD_HHMMSS_recovery.md` | 復帰検出日時、元モデルの復帰状況 |
| Part24（Langfuse） | Langfuseダッシュボード | リクエスト数、エラー率、レイテンシ |
| LiteLLMログ | LiteLLM標準ログ | プロキシ経由の全リクエスト/レスポンス |

### 6.9.2. 典型的なトラブルパターンと対処

#### パターン1: レート制限の頻発

**症状**: 429エラーが多数発生

**ログ確認**:
1. Part24で429エラーの発生頻度を確認
2. 予算消費ログでRPM（Requests Per Minute）を確認
3. 特定の工程タグで集中していないか確認

**対処**:
1. 一時的にRPM制限を緩和（litellm_config.yamlの`rpm_limit`調整）
2. 負荷分散のため、代替モデルの割合を増やす
3. 定常的に発生する場合は、予算やプランの見直しを検討

#### パターン2: 予算の早期枯渇

**症状**: 月の半ばで予算80%到達

**ログ確認**:
1. 予算消費ログでどのモデル/タグで消費しているか確認
2. Part24でリクエスト数と平均コストを確認

**対処**:
1. 不正使用や設定ミスがないか確認
2. 高精度枠で雑務を使用していないか確認
3. 使用効率化（工程タグの見直し）または予算引き上げの検討

#### パターン3: 特定モデルでのエラー多発

**症状**: 特定のモデルで500/502/503エラーが多発

**ログ確認**:
1. Part24でエラー発生の時間帯とパターンを確認
2. プロバイダのステータスページを確認

**対処**:
1. 一時的に該当モデルを除外し、代替モデルに切り替え
2. プロバイダ障害情報を確認
3. 復帰後、自動で元のモデルに戻ることを確認

#### パターン4: タイムアウト頻発

**症状**: 30秒以上のリクエストが増加

**ログ確認**:
1. Part24でレイテンシの推移を確認
2. 特定のプロンプトやモデルで発生していないか確認

**対処**:
1. タイムアウト値の調整（`timeout: 60`等に増加）
2. プロンプトの長さを見直し
3. より高速なモデルへの切り替え検討

**一次情報**: [LiteLLM Reliability - Retries, Fallbacks](https://docs.litellm.ai/docs/completion/reliable_completions)

---

## 6.10. Runbook：復旧手順

### 6.10.1. 障害からの復旧フロー

#### ステップ1: 原因特定

1. **ログ確認**: Part24、予算消費ログ、フォールバック記録を確認
2. **エラー種別の特定**: レート制限/予算オーバー/プロバイダ障害/設定ミス
3. **影響範囲の特定**: どの工程/モデル/ユーザーに影響しているか

#### ステップ2: 即時対応

| エラー種別 | 即時対応 |
|----------|---------|
| レート制限 | 代替モデルへの切り替え（LiteLLM自動） |
| 予算オーバー | 該当モデルの停止、代替モデルへの切り替え |
| プロバイダ障害 | 該当プロバイダの除外、他プロバイダへ切り替え |
| APIキー失効 | キーの再発行、設定更新 |

#### ステップ3: 元の状態への復帰

1. **ヘルスチェック**: 元のモデル/プロバイダの復帰を確認
2. **設定の復元**: litellm_config.yamlを元に戻す（必要な場合）
3. **自動復帰の確認**: LiteLLMが自動で元のモデルに戻ったことを確認
4. **動作確認**: テストリクエストを送信し正常動作を確認

#### ステップ4: 再発防止

1. **ADRの作成**: 障害内容と対応策を記録
2. **設定の見直し**: 同様の障害を防ぐための設定調整
3. **監視強化**: 該当エラーのアラート設定を強化

### 6.10.2. 復旧確認チェックリスト

- [ ] 元のモデルが正常に応答しているか
- [ ] エラー率が通常レベルに戻っているか（Part24確認）
- [ ] フォールバック記録に復帰が記録されているか
- [ ] 予算消費が正常に記録されているか
- [ ] 全ての工程タグで正常にAIが使用できるか
- [ ] ADRが作成され、再発防止策が記述されているか

---

## 6.11. Runbook：「壊れ方別」チェックリスト

### 6.11.1. 通信障害

**症状**: タイムアウト、接続エラー

| 確認項目 | 対処 |
|---------|------|
| ネットワーク接続 | インターネット接続、プロキシ設定を確認 |
| DNS解決 | プロバイダのAPIエンドポイントが名前解決できるか確認 |
| ファイアウォール | ポート443（HTTPS）が許可されているか確認 |
| プロバイダステータス | プロバイダのステータスページを確認 |

**一次情報**: 各プロバイダのステータスページ（OpenAI、Anthropic、Google等）

---

### 6.11.2. 認証エラー

**症状**: `authentication_failed`、`invalid_api_key`

| 確認項目 | 対処 |
|---------|------|
| APIキーの有効期限 | キーが失効していないか確認 |
| 環境変数 | `.env`ファイルに正しく設定されているか確認 |
| キーの権限 | キーに必要な権限が付与されているか確認 |
| キーの使用量 | キーの使用量上限に達していないか確認 |

**対処**: 新しいAPIキーを発行し、環境変数を更新してLiteLLMを再起動

---

### 6.11.3. キー失効

**症状**: `api_key_disabled`、`account_suspended`

| 確認項目 | 対処 |
|---------|------|
| アカウント状況 | プロバイダのダッシュボードでアカウント状況を確認 |
| 支払い状況 | 未払いがないか確認 |
| ポリシー違反 | 利用規約に違反していないか確認 |

**対処**: プロバイダに連絡し、状況を確認。代替キーまたは代替プロバイダを使用

---

### 6.11.4. リージョン問題

**症状**: 特定リージョンからのみアクセスできない

| 確認項目 | 対処 |
|---------|------|
| リージョン制限 | プロバイダが該当リージョンでサービス提供しているか確認 |
| レイテンシ | リージョン間の通信レイテンシが問題ないか確認 |
| フェイルオーバー | 他リージョンのエンドポイントに切り替え |

**対処**: litellm_config.yamlで複数リージョンのエンドポイントを設定

---

### 6.11.5. レート制限

**症状**: `429 Too Many Requests`、`rate_limit_exceeded`

| 確認項目 | 対処 |
|---------|------|
| RPM/TPM | 現在のリクエスト数を確認（Part24） |
| 設定値 | litellm_config.yamlの`rpm_limit`、`tpm_limit`を確認 |
| バースト | 短時間に大量のリクエストをしていないか確認 |

**対処**:
1. 即座に代替モデルにフォールバック（LiteLLM自動）
2. 必要に応じてRPM/TPM制限を調整
3. 負荷分散のため複数のモデル/キーを使用

---

### 6.11.6. モデル廃止

**症状**: `model_not_found`、`model_deprecated`

| 確認項目 | 対処 |
|---------|------|
| モデル名 | モデル名が正しいか確認 |
| 廃止通知 | プロバイダから廃止通知が出ていないか確認 |
| 代替モデル | 代替モデルが利用可能か確認 |

**対処**:
1. 廃止モデルをlitellm_config.yamlから削除
2. 代替モデルを設定
3. ADRで「モデル廃止・代替モデル切り替え」を記録

---

### 6.11.7. 予算上限到達

**症状**: `budget_exceeded`、`max_budget_reached`

| 確認項目 | 対処 |
|---------|------|
| 予算残高 | 予算消費ログで残高を確認 |
| 予算設定 | 予算設定が適切か確認 |
| 使用効率 | 高精度枠で雑務を使用していないか確認 |

**対処**:
1. 該当モデルの使用を停止（LiteLLM自動）
2. 代替モデルにフォールバック
3. 必要に応じてADRで予算引き上げを申請

---

### 6.11.8. プロバイダ全停止

**症状**: プロバイダ全体で障害が発生

| 確認項目 | 対処 |
|---------|------|
| ステータスページ | プロバイダの公式ステータスページを確認 |
| 他プロバイダ | 他プロバイダは正常に稼働しているか確認 |
| ローカルLLM | ローカルLLMが使用可能か確認 |

**対処**:
1. 障害プロバイダを全てのフォールバック先から除外
2. 他プロバイダまたはローカルLLMを使用
3. 復帰後、元の設定に戻す

**一次情報**: [LiteLLM Load Balancing](https://docs.litellm.ai/docs/proxy/load_balancing)

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
- [x] 本Part22 を読んだ人が「制限が来ても止まらない」を理解できるか

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
- [LiteLLM Budget Manager](https://docs.litellm.ai/docs/budget_manager) : 予算管理クラス
- [LiteLLM Budgets, Rate Limits](https://docs.litellm.ai/docs/proxy/users) : 予算・レート制限設定
- [LiteLLM Tag Budgets](https://docs.litellm.ai/docs/proxy/tag_budgets) : タグ別予算設定
- [LiteLLM Alerting / Webhooks](https://docs.litellm.ai/docs/proxy/alerting) : アラート・Webhook設定
- [LiteLLM Email Notifications](https://docs.litellm.ai/docs/proxy/email) : メール通知設定
- [LiteLLM Reliable Completions - Retries, Fallbacks](https://docs.litellm.ai/docs/completion/reliable_completions) : リトライ・フォールバック機能
- [LiteLLM Proxy Load Balancing](https://docs.litellm.ai/docs/proxy/load_balancing) : ロードバランシング設定
- [LiteLLM Proxy Config Settings](https://docs.litellm.ai/docs/proxy/config_settings) : プロキシ設定全般
- [LiteLLM Customers / End-User Budgets](https://docs.litellm.ai/docs/proxy/customers) : エンドユーザー別予算設定

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
