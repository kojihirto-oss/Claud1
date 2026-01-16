# Part 01：目的・成功条件・失敗定義（トップクラス精度を運用で定義）

## 0. このPartの位置づけ
- **目的**: プロジェクトの最終ゴール・成功条件・失敗定義を明文化し、運用の判断基準を固定する。
- **依存**: [Part00](Part00.md)（SSOT憲法）
- **影響**: 全Part（目標がブレると全体が破綻する）

---

## 1. 目的（Purpose）

本プロジェクト（VCG/VIBE 2026 設計書SSOT）の最終ゴールは以下の3つを同時達成すること：

### 1.1 迷いゼロ（Zero Ambiguity）
- 次に何をすべきかが **常に一意** である
- タスクの優先順位・実行手順・完了条件が明確
- SSOT/ダッシュボード/VIBEKANBAN を見れば、次アクションが即座に分かる

### 1.2 事故ゼロ（Zero Accidents）
以下の事故を **未然防止** する：
- 誤削除/誤上書き
- 依存壊し/ビルド不能化
- セキュリティ事故（鍵混入、脆弱性放置）
- 「動いてる気がする」状態の放置（Verify/Evidence なき成功）

### 1.3 トップクラス精度（Top-Tier Precision）
- 仕様準拠が **機械的に担保** される
- 変更が最小化される（最小差分・影響範囲の限定）
- 検証・証跡・再現性・ロールバックが常備される
- **すべての変更が説明可能**（全コミットがタスク/ADR/証跡と紐づく）

**根拠**: [FACTS_LEDGER F-0020](FACTS_LEDGER.md)（プロジェクト目的）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 本リポジトリ（vibe-spec-ssot）内の全作業
- SSOT（docs/）の作成・更新・検証
- Verify/Evidence/Release の運用
- タスク（TICKET）単位の完了判定
- リリース単位の品質保証

### Out of Scope（適用外）
- 外部プロジェクト（他リポジトリ）の目標設定
- 個人の学習目標・スキル向上計画（本プロジェクトの運用目標とは別）
- 運用開始前の「理想の状態」議論（具体的な DoD が優先）

---

## 3. 前提（Assumptions）

1. **DoD（Definition of Done）が成功の唯一の基準** である。
2. **失敗定義に該当したら、即座に VRループ（Verify-Repair Loop）を回す**。
3. **メトリクスは運用改善のために計測** するが、計測自体が目的ではない。
4. **成功条件は機械判定可能** でなければならない（人間の「感覚」では判定しない）。
5. 本Part01 は **Part00（SSOT憲法）に従属** する（矛盾した場合は Part00 が優先）。

**根拠**: [Part00 R-0001](Part00.md)（真実の優先順位）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **DoD（Definition of Done）**: [glossary/GLOSSARY.md#DoD](../glossary/GLOSSARY.md)
- **Verify**: [glossary/GLOSSARY.md#Verify](../glossary/GLOSSARY.md)
- **Evidence**: [glossary/GLOSSARY.md#Evidence](../glossary/GLOSSARY.md)
- **Release**: [glossary/GLOSSARY.md#Release](../glossary/GLOSSARY.md)
- **VRループ**: [glossary/GLOSSARY.md#VRループ](../glossary/GLOSSARY.md)
- **SBOM**: [glossary/GLOSSARY.md#SBOM](../glossary/GLOSSARY.md)（Software Bill of Materials）
- **VIBEKANBAN**: [glossary/GLOSSARY.md#VIBEKANBAN](../glossary/GLOSSARY.md)（※要定義）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-0101: タスク（TICKET）DoD【MUST】
タスクは以下の **5条件を全て満たした時のみ** 完了とする：

1. **Spec（仕様）が凍結** され、Acceptance（受入条件）が機械判定可能である
2. **Build（実装）がSpecに一致** し、差分が最小である
3. **Verify（テスト・静的解析・スキャン）が全てGreen** である
4. **Evidence（ログ・diff・manifest・sha256・実行結果）が保存** されている
5. **Release（必要な場合）は版管理** され、復元できる

**根拠**: [FACTS_LEDGER F-0021](FACTS_LEDGER.md)
**違反例**: 「テストは後で書く」→ Verify が Green でないため、未完了。

---

### R-0102: リリースDoD【MUST】
リリースは以下の **4条件を全て満たした時のみ** 成功とする：

1. **リリースフォルダが READ-ONLY**（改変不能）である
2. **バイナリ/生成物の整合性（sha256）** が取れている
3. **SBOM が生成** され、依存が追跡できる（最小でも CycloneDX または SPDX）
4. **主要なセキュリティスキャンが実施** され、重大な問題がゼロか、例外が承認済み（例外には期限がある）

**根拠**: [FACTS_LEDGER F-0022](FACTS_LEDGER.md)
**違反例**: sha256 を取らずにリリース → 改ざん検証不能のため、失敗。

---

### R-0103: 失敗定義（Failure）【MUST NOT】
以下の状態は **即座に失敗と見なし、VRループを回す**：

1. **Verifyに失敗したまま「次へ進む」**
2. **Evidenceが残っていない**
3. **変更理由が説明できない**（誰がなぜ何をしたか不明）
4. **「後で直す」タスクが増殖** して収束しない（VRループが回っていない）
5. **依存や環境差で再現できない**

**根拠**: [FACTS_LEDGER F-0030](FACTS_LEDGER.md)、[Part00 R-0009](Part00.md)
**対処**: [Part10](Part10.md)（Verify Gate）で VRループを回す。

---

### R-0104: 仕様凍結前の実装禁止【MUST NOT】
Spec が凍結されるまで Build しない。

**理由**: 曖昧さ・矛盾・用語ゆれは「実装で埋めない」。必ず Spec へ戻す。
**根拠**: [FACTS_LEDGER F-0032](FACTS_LEDGER.md)
**例外**: 調査用スパイクは「SPIKE」扱いで隔離し、成果は仕様へ移すまで本流に混ぜない。

---

### R-0105: メトリクスの計測【SHOULD】
以下のメトリクスを **定期的に計測** し、運用精度を可視化する：

1. **収束性**: VRループが何回で Green に戻るか
2. **再現性**: クリーン環境で Verify が通るか
3. **変更最小性**: パッチ行数/ファイル数/影響範囲
4. **事故率**: 破壊的変更の回数、鍵混入、ロールバック回数
5. **迷いゼロ指数**: 次アクションが SSOT/ダッシュボードで明確か

**根拠**: [FACTS_LEDGER F-0023](FACTS_LEDGER.md)
**保存先**: `evidence/metrics/YYYYMMDD_metrics.md`

---

### R-0106: 成功の再定義禁止【MUST NOT】
DoD を「緩和」して成功扱いすることを禁止する。

**理由**: 「80%できたから成功」では、残り20%が永遠に放置される。
**例外**: 一時的な緩和は ADR（decisions/）で明文化し、期限を設ける。

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: タスク完了判定
1. タスクの Acceptance（受入条件）を確認
2. Verify を実行（`checks/` 内のスクリプト or 手順書）
3. 全て Green なら Evidence を保存（`evidence/verify_reports/`）
4. R-0101（タスクDoD）の5条件を確認
5. 全て満たしていれば、タスクを「完了」とマーク（VIBEKANBAN / TODO）

### 手順B: リリース判定
1. リリース対象の成果物を `RELEASE/RELEASE_YYYYMMDD_HHMMSS/` に配置
2. manifest.csv と sha256.csv を生成
3. SBOM を生成（CycloneDX or SPDX）
4. セキュリティスキャンを実施（例: Trivy, Snyk）
5. R-0102（リリースDoD）の4条件を確認
6. 全て満たしていれば、リリースを「承認」とマーク
7. リリースフォルダを READ-ONLY に変更

詳細は [Part13](Part13.md)（Release Package）を参照。

### 手順C: 失敗時の対処（VRループ）
1. Verify の失敗箇所を特定（ログ・diff を確認）
2. 修正（最小差分）
3. Verify 再実行
4. 3回ループしても通らない場合、ADR で緩和を検討
5. 緩和条件（期限・後続タスク）を明記

詳細は [Part10](Part10.md)（Verify Gate）を参照。

### 手順D: メトリクス計測
1. 月次（または週次）で以下を集計：
   - VRループ回数の平均
   - Verify 失敗率
   - ロールバック回数
   - 事故発生件数
2. `evidence/metrics/YYYYMMDD_metrics.md` に記録
3. 傾向分析（増加傾向なら運用改善の検討）

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: Verify が3回ループしても通らない
**対処**:
1. ADR（decisions/）で「一時的に Verify を緩和」を提案
2. 緩和理由・期限・後続タスクを明記
3. HumanGate で承認
4. 緩和条件が満たされたら、元の Verify に戻す

**エスカレーション**: 緩和が常態化する場合、Verify の設計を見直す（Part10）。

---

### 例外2: DoD を満たせない（技術的制約）
**対処**:
1. 「Non-Goals」（やらないこと）に明記
2. ADR で制約を記録
3. 代替手段を提示（例: 手動検証で代替）

**エスカレーション**: 制約が解消された時点で、DoD を再評価。

---

### 例外3: 事故が発生した（誤削除・鍵混入等）
**対処**:
1. 即座に作業を停止
2. Evidence に「事故の経緯・影響範囲・原因」を記録
3. ロールバック or 復旧手順を実施
4. ADR で「再発防止策」を明文化
5. Part09（Permission Tier）の見直しを検討

**エスカレーション**: 事故率が高い場合、運用プロセス全体を見直す。

---

### 例外4: メトリクスが悪化している
**対処**:
1. 悪化の原因を特定（タスクの複雑化？Verify の不備？）
2. ADR で改善策を提案（例: タスクサイズの縮小、Verify の追加）
3. 改善策を実施し、次回計測で効果を確認

**エスカレーション**: 改善策が効果なしの場合、外部レビューを検討。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-0101: タスクDoD充足率
**判定条件**: R-0101 の5条件が全て満たされているか
**合否**: 1つでも欠けていたら Fail
**実行方法**: `checks/verify_dod.ps1` の `Test-TaskDoD` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_task_dod.md`

---

### V-0102: リリースDoD充足率
**判定条件**: R-0102 の4条件が全て満たされているか
**合否**: 1つでも欠けていたら Fail
**実行方法**: `checks/verify_release.ps1` の `Test-ReleaseDoD` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_release_dod.md`

---

### V-0103: 失敗状態の検出
**判定条件**: R-0103 の5つの失敗状態に該当するか
**合否**: 1つでも該当したら Fail（VRループ起動）
**実行方法**: `checks/verify_failure.ps1` の `Test-FailureState` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_failure_check.md`

---

### V-0104: Spec凍結の確認
**判定条件**: タスクの Spec が「凍結」状態か（`STATUS.md` に明記）
**合否**: 凍結されていなければ、Build 開始は Fail
**実行方法**: `checks/verify_spec_freeze.ps1` の `Test-SpecFreeze` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_spec_freeze.md`

---

### V-0105: メトリクス計測の実施確認
**判定条件**: 過去30日以内にメトリクス計測が実施されているか
**合否**: 実施されていなければ警告（Fail ではない）
**実行方法**: `checks/verify_metrics.ps1` の `Test-MetricsRecency` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_metrics_check.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-0101: タスク完了時の Evidence
**保存内容**:
- Verify 実行結果（全 Green のログ）
- diff（変更前後）
- manifest/sha256
- 実行コマンド履歴

**参照パス**: `evidence/verify_reports/YYYYMMDD_HHMMSS_task_<ID>.md`
**保存場所**: `evidence/verify_reports/`（削除禁止）

---

### E-0102: リリース時の Evidence
**保存内容**:
- manifest.csv（ファイル一覧）
- sha256.csv（整合性検証）
- SBOM（CycloneDX or SPDX）
- セキュリティスキャン結果
- STATUS.md（DoD チェックリスト）

**参照パス**: `RELEASE/RELEASE_YYYYMMDD_HHMMSS/`
**保存場所**: `RELEASE/`（READ-ONLY）

---

### E-0103: 事故時の Evidence
**保存内容**:
- 事故の経緯・影響範囲・原因
- ロールバック手順・実行結果
- 再発防止策（ADR へのリンク）

**参照パス**: `evidence/incidents/YYYYMMDD_HHMMSS_incident_<type>.md`
**保存場所**: `evidence/incidents/`（削除禁止）

---

### E-0104: メトリクス計測結果
**保存内容**:
- 収束性・再現性・変更最小性・事故率・迷いゼロ指数の実測値
- 傾向分析（前回比）

**参照パス**: `evidence/metrics/YYYYMMDD_metrics.md`
**保存場所**: `evidence/metrics/`

---

### E-0105: VRループのログ
**保存内容**:
- Verify 失敗回数
- 修正内容（diff）
- 収束までの時間

**参照パス**: `evidence/vr_loops/YYYYMMDD_HHMMSS_vr_<task_id>.md`
**保存場所**: `evidence/vr_loops/`

---

## 10. チェックリスト

- [x] 本Part01 が全12セクション（0〜12）を満たしているか
- [x] プロジェクト目的（迷いゼロ/事故ゼロ/トップクラス精度）が明記されているか
- [x] タスクDoD（R-0101）が明記されているか
- [x] リリースDoD（R-0102）が明記されているか
- [x] 失敗定義（R-0103）が明記されているか
- [x] 仕様凍結前の実装禁止（R-0104）が明記されているか
- [x] メトリクス計測（R-0105）が明記されているか
- [x] 成功の再定義禁止（R-0106）が明記されているか
- [x] 各ルールに FACTS_LEDGER への参照が付いているか
- [x] Verify観点（V-0101〜V-0105）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-0101〜E-0105）が参照パス付きで記述されているか
- [ ] checks/verify_dod.ps1 が実装されているか（次タスク）
- [ ] 本Part01 を読んだ人が「成功とは何か」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-0101: メトリクス計測の頻度
**問題**: メトリクスを「毎日」「毎週」「毎月」のどのタイミングで計測するか不明。
**影響Part**: Part10（Verify Gate）
**暫定対応**: 月次計測（負荷が低い）。運用が安定したら週次に変更を検討。

---

### U-0102: SBOM生成ツールの選定
**問題**: CycloneDX と SPDX のどちらを標準とするか不明。
**影響Part**: Part13（Release Package）
**暫定対応**: CycloneDX を優先（ツールが豊富）。SPDX も生成可能なら両方出力。

---

### U-0103: セキュリティスキャンの閾値
**問題**: 「重大な問題ゼロ」の定義が曖昧（CVSS何点以上？）。
**影響Part**: Part10（Verify Gate）
**暫定対応**: CVSS 7.0以上を「重大」と定義。今後の運用で調整。

---

### U-0104: 事故時の責任範囲
**問題**: AI が事故を起こした場合、「誰が」責任を負うか不明。
**影響Part**: Part09（Permission Tier）
**暫定対応**: HumanGate が最終承認者として責任を負う。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法（真実の優先順位・禁止事項）
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-0020, F-0021, F-0022, F-0023, F-0030）
- [docs/Part02.md](Part02.md) : 用語運用ルール
- [docs/Part04.md](Part04.md) : 作業管理（タスクフォーマット）
- [docs/Part09.md](Part09.md) : Permission Tier（AI権限管理）
- [docs/Part10.md](Part10.md) : Verify Gate（検証手順・VRループ）
- [docs/Part13.md](Part13.md) : Release Package（リリース手順）

### sources/
- [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md) : 原文（L39-80）

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_dod.ps1` : DoD検証スクリプト（次タスクで作成予定）
- `checks/verify_release.ps1` : リリース検証スクリプト（次タスクで作成予定）
- `checks/verify_failure.ps1` : 失敗状態検出スクリプト（次タスクで作成予定）

### evidence/
- `evidence/verify_reports/` : Verify実行結果
- `evidence/metrics/` : メトリクス計測結果
- `evidence/incidents/` : 事故ログ
- `evidence/vr_loops/` : VRループログ

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール（最上位）
