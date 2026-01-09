# Part 10：Verify Gate（Fast/Full/VRループ・機械判定・収束設計）

## 0. このPartの位置づけ
- **目的**: 機械判定可能な検証（Verify）を設計し、VRループ（Verify-Repair Loop）で収束を保証する。
- **依存**: [Part00](Part00.md)（Truth Order）、[Part01](Part01.md)（DoD）、[Part09](Part09.md)（Permission Tier）
- **影響**: 全Part（すべてのタスクが Verify を通過する）

---

## 1. 目的（Purpose）

本 Part10 は **Verify Gate（検証ゲート）** を通じて、以下を保証する：

1. **Fast Verify**: 最短で壊れを検出（lint + unit + 型/静的解析の一部）
2. **Full Verify**: CI相当の全検査（integration/e2e + security + SBOM + 再現実行）
3. **VRループ（Verify-Repair Loop）**: 失敗を分類して収束させる
4. **機械判定可能**: 人間の「感覚」ではなく、コマンド実行で Pass/Fail を判定

**根拠**: [FACTS_LEDGER F-0056](FACTS_LEDGER.md)（Verify Gate）、[F-0057](FACTS_LEDGER.md)（VRループ）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 本リポジトリ内の全タスク（TICKET）
- Fast Verify（開発中の高速検証）
- Full Verify（リリース前の完全検証）
- VRループ（失敗修正・収束）

### Out of Scope（適用外）
- 外部プロジェクトの検証
- 手動テスト（E2Eの一部は手動OK、ただし記録必須）
- パフォーマンステスト（別途 Part11 で扱う）

---

## 3. 前提（Assumptions）

1. **Verify なき変更は「存在しない」**（Part00 R-0001）。
2. **Verify は機械判定可能**である（人間の「たぶん動く」は不可）。
3. **VRループは3回で収束**を目標とする（3回超えたら設計見直し）。
4. **Fast Verify は5分以内**、**Full Verify は30分以内**を目標とする。
5. **Verify レポートは Evidence に保存**される（削除禁止）。

**根拠**: [Part00 R-0001](Part00.md)（Truth Order）、[Part01 R-0103](Part01.md)（失敗定義）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Verify**: [glossary/GLOSSARY.md#Verify](../glossary/GLOSSARY.md)（機械判定可能な検証）
- **VRループ**: [glossary/GLOSSARY.md#VRループ](../glossary/GLOSSARY.md)（Verify-Repair Loop）
- **Fast Verify**: 高速検証（lint/unit/型チェック）
- **Full Verify**: 完全検証（integration/e2e/security/SBOM）
- **SBOM**: [glossary/GLOSSARY.md#SBF](../glossary/GLOSSARY.md)（Software Bill of Materials）
- **DoD**: [glossary/GLOSSARY.md#DoD](../glossary/GLOSSARY.md)（Definition of Done）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-1001: Fast Verify の必須カテゴリ【MUST】
Fast Verify は以下の **4カテゴリを必ず含む**（5分以内を目標）：

1. **正しさ**: unit tests（重要な関数のみ）
2. **一貫性**: format/lint/type（全ファイル）
3. **安全（軽量）**: secrets 検出（例: gitleaks）
4. **リンク切れ**: docs/ 内の参照パス（checks/verify_repo.ps1）

**根拠**: [FACTS_LEDGER F-0056](FACTS_LEDGER.md)
**用途**: 開発中の高速フィードバック（commit 前）

**実行例**:
```bash
pwsh checks/verify_repo.ps1 -Mode Fast
```

---

### R-1002: Full Verify の必須カテゴリ【MUST】
Full Verify は以下の **7カテゴリを必ず含む**（30分以内を目標）：

1. **正しさ**: tests（unit + integration + e2e）
2. **一貫性**: format/lint/type（全ファイル）
3. **安全**: secrets/依存脆弱性/静的解析（例: Trivy, Snyk, Semgrep）
4. **供給網**: SBOM / provenance（可能なら）
5. **再現性**: クリーン環境で同じ結果（Docker/CI）
6. **リンク切れ**: docs/ 内の参照パス
7. **禁止コマンド**: docs/ に禁止コマンドが記載されていないか

**根拠**: [FACTS_LEDGER F-0056](FACTS_LEDGER.md)
**用途**: リリース前・PR マージ前の完全検証

**実行例**:
```bash
pwsh checks/verify_repo.ps1 -Mode Full
```

---

### R-1003: Verify レポートの必須成果物【MUST】
Verify 実行後、以下を **必ず Evidence に保存**する：

- **実行コマンド**（正確に）
- **成否**（Pass/Fail）
- **失敗ログ抜粋**（重要部のみ）
- **参照ログへのパス**（全ログは別途保存）
- **主要メトリクス**（実行時間・テスト数・カバレッジ等、任意）

**保存先**: `evidence/verify_reports/YYYYMMDD_HHMMSS_<check_name>.md`
**根拠**: [FACTS_LEDGER F-0056](FACTS_LEDGER.md)、[Part00 R-0005](Part00.md)（Evidence保存義務）

---

### R-1004: VRループ（Verify-Repair Loop）【MUST】
Verify 失敗時、以下の手順で収束させる：

1. **失敗を分類**（後述の4分類）
2. **分類に応じて修正**（最小差分）
3. **Verify 再実行**
4. **3回ループしても通らない場合**、HumanGate（設計変更/分割/範囲縮小）

**根拠**: [FACTS_LEDGER F-0057](FACTS_LEDGER.md)、[Part01 R-0103](Part01.md)（失敗定義）
**違反例**: Verify 失敗を放置して「次へ進む」→ Part01 R-0103 違反。

---

### R-1005: 失敗分類（4分類）【MUST】
Verify 失敗は以下の **4分類** で対処する：

#### 1. Spec系（前提が違う/受入基準が曖昧）
- **対処**: Spec を修正し、再度 Spec Freeze
- **エスカレーション**: ChatGPT（司令塔）へ戻す

#### 2. 依存/環境系（バージョン衝突/OS差）
- **対処**: Docker/lock ファイル/CI で環境を固定
- **エスカレーション**: Part03（環境設計）を見直す

#### 3. 実装系（局所バグ）
- **対処**: Claude Code で最小修正
- **エスカレーション**: 3回ループしても直らない場合、Spec へ戻す

#### 4. テスト系（テスト不足/壊れたテスト）
- **対処**: テストを直し、意図を Spec へ反映
- **エスカレーション**: Part11（テスト設計）を見直す

**根拠**: [FACTS_LEDGER F-0057](FACTS_LEDGER.md)

---

### R-1006: ループ制限（暴走防止）【MUST】
同じ失敗が **3回を超えたら**、以下を実施：

1. Z.ai でログ要約
2. ChatGPT で根本原因分析
3. Claude Code で修正に切り替える
4. それでも収束しない場合、**HumanGate**（設計変更/分割/範囲縮小）

**根拠**: [FACTS_LEDGER F-0057](FACTS_LEDGER.md)
**理由**: 無限ループを防ぐ。3回は経験則（大抵の問題は3回以内に収束する）。

---

### R-1007: Verify の並列実行【SHOULD】
Fast Verify のカテゴリ（lint/unit/type/secrets）は **並列実行可能**。

**実行例**:
```bash
pwsh checks/verify_repo.ps1 -Mode Fast -Parallel
```

**理由**: Fast Verify の時間を短縮（5分 → 2分）。
**制約**: Full Verify の integration/e2e は順次実行（環境衝突を防ぐ）。

---

### R-1008: Verify の冪等性【MUST】
Verify は **何度実行しても同じ結果**を返す。

**違反例**:
- テストが時刻依存（`Date.now()` を使う）
- テストが順序依存（テスト間で状態を共有）

**対処**: Part11（テスト設計）で冪等性を担保。

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: Fast Verify の実行
1. タスク（TICKET）の実装完了後、commit 前に実行
2. `pwsh checks/verify_repo.ps1 -Mode Fast` を実行
3. Pass なら commit
4. Fail なら VRループ（手順C）へ

### 手順B: Full Verify の実行
1. PR 作成前 or リリース前に実行
2. `pwsh checks/verify_repo.ps1 -Mode Full` を実行
3. Pass なら PR 作成 or リリース承認
4. Fail なら VRループ（手順C）へ

### 手順C: VRループの実行
1. Verify の失敗ログを確認
2. 失敗を4分類（Spec/依存・環境/実装/テスト）に分類
3. 分類に応じて修正：
   - Spec系 → Spec を修正
   - 依存/環境系 → Docker/lock を修正
   - 実装系 → コードを修正
   - テスト系 → テストを修正
4. Verify 再実行
5. Pass なら完了
6. Fail なら回数をカウント（1回目 → 2回目 → 3回目）
7. 3回超えたら HumanGate（設計変更/分割/範囲縮小）

### 手順D: Verify レポートの保存
1. Verify 実行結果を markdown で記録
2. 保存先: `evidence/verify_reports/YYYYMMDD_HHMMSS_<check_name>.md`
3. 記録内容（R-1003 参照）：
   - 実行コマンド
   - 成否（Pass/Fail）
   - 失敗ログ抜粋
   - 参照ログへのパス
   - 主要メトリクス

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: Verify が3回ループしても通らない
**対処**:
1. HumanGate で設計変更を検討
2. ADR で「一時的に Verify を緩和」を提案（期限付き）
3. 緩和条件を明記（例: 「Part11 完成まで e2e を無効化」）
4. 緩和条件が満たされたら、元の Verify に戻す

**エスカレーション**: Part01 例外1 を参照。

---

### 例外2: Fast Verify が5分を超える
**対処**:
1. 重いテストを Full Verify へ移動
2. テストの並列実行を検討（R-1007）
3. テストのキャッシュを導入（例: pytest-cache）

**エスカレーション**: Part11（テスト設計）を見直す。

---

### 例外3: Full Verify が30分を超える
**対処**:
1. CI の並列実行を検討
2. 重いテストを夜間バッチへ移動
3. テスト範囲の縮小（重要テストのみ）

**エスカレーション**: Part11（テスト設計）を見直す。

---

### 例外4: Verify が環境依存で失敗
**対処**:
1. Docker で環境を固定
2. lock ファイル（package-lock.json, Cargo.lock等）を commit
3. CI 環境を本番環境と一致させる

**エスカレーション**: Part03（環境設計）を見直す。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-1001: Fast Verify の実行確認
**判定条件**: Fast Verify が実行され、Pass しているか
**合否**: 実行されていないか Fail なら Fail
**実行方法**: `checks/verify_repo.ps1 -Mode Fast`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_fast_verify.md`

---

### V-1002: Full Verify の実行確認
**判定条件**: Full Verify が実行され、Pass しているか
**合否**: 実行されていないか Fail なら Fail
**実行方法**: `checks/verify_repo.ps1 -Mode Full`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_full_verify.md`

---

### V-1003: VRループ回数の記録
**判定条件**: VRループが何回実行されたか
**合否**: 3回超えたら警告（Fail ではない、ただし HumanGate 必須）
**実行方法**: `evidence/vr_loops/` のファイル数をカウント
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_vr_loop_count.md`

---

### V-1004: Verify レポートの存在確認
**判定条件**: Verify 実行後、Evidence にレポートが存在するか
**合否**: レポートがなければ Fail
**実行方法**: `checks/verify_repo.ps1` の `Test-VerifyReportExists` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_report_check.md`

---

### V-1005: Verify の冪等性確認
**判定条件**: Verify を2回実行して、同じ結果を返すか
**合否**: 結果が異なれば Fail
**実行方法**: `checks/verify_repo.ps1 -Mode Fast -Repeat 2`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_idempotency.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-1001: Verify 実行結果
**保存内容**:
- 実行コマンド
- 成否（Pass/Fail）
- 失敗ログ抜粋
- 参照ログへのパス
- 主要メトリクス（実行時間・テスト数・カバレッジ等）

**参照パス**: `evidence/verify_reports/YYYYMMDD_HHMMSS_<check_name>.md`
**保存場所**: `evidence/verify_reports/`（削除禁止）

---

### E-1002: VRループのログ
**保存内容**:
- Verify 失敗回数
- 修正内容（diff）
- 収束までの時間
- 失敗分類（Spec/依存・環境/実装/テスト）

**参照パス**: `evidence/vr_loops/YYYYMMDD_HHMMSS_vr_<task_id>.md`
**保存場所**: `evidence/vr_loops/`

---

### E-1003: 失敗分類の記録
**保存内容**:
- 失敗分類（4分類）
- 対処内容
- エスカレーション先（ChatGPT/Part03/Part11等）

**参照パス**: `evidence/failure_classification/YYYYMMDD_HHMMSS_classification.md`
**保存場所**: `evidence/failure_classification/`

---

### E-1004: Verify 時間のメトリクス
**保存内容**:
- Fast Verify の実行時間
- Full Verify の実行時間
- 推移（前回比）

**参照パス**: `evidence/metrics/YYYYMMDD_verify_metrics.md`
**保存場所**: `evidence/metrics/`

---

### E-1005: HumanGate エスカレーション記録
**保存内容**:
- エスカレーション理由（3回ループしても通らない）
- 設計変更内容
- 緩和条件（期限・取り消し条件）

**参照パス**: `evidence/humangate/YYYYMMDD_HHMMSS_verify_escalation.md`
**保存場所**: `evidence/humangate/`

---

## 10. チェックリスト

- [x] 本Part10 が全12セクション（0〜12）を満たしているか
- [x] Fast Verify の必須カテゴリ（R-1001）が明記されているか
- [x] Full Verify の必須カテゴリ（R-1002）が明記されているか
- [x] Verify レポートの必須成果物（R-1003）が明記されているか
- [x] VRループ（R-1004）が明記されているか
- [x] 失敗分類（R-1005）が明記されているか
- [x] ループ制限（R-1006）が明記されているか
- [x] Verify の並列実行（R-1007）が明記されているか
- [x] Verify の冪等性（R-1008）が明記されているか
- [x] 各ルールに FACTS_LEDGER への参照が付いているか
- [x] Verify観点（V-1001〜V-1005）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-1001〜E-1005）が参照パス付きで記述されているか
- [ ] checks/verify_repo.ps1 が実装されているか（次タスク）
- [ ] 本Part10 を読んだ人が「Verify の回し方」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-1001: Fast Verify の時間目標
**問題**: 5分が「速すぎる」「遅すぎる」のか不明。プロジェクト規模依存。
**影響Part**: Part10（本Part）
**暫定対応**: 5分を目標。運用開始後、実測値を見て調整。

---

### U-1002: Full Verify の並列実行
**問題**: integration/e2e を並列実行するか、順次実行するか不明。
**影響Part**: Part10（本Part）、Part11（テスト設計）
**暫定対応**: 順次実行（環境衝突を防ぐ）。テストが独立していれば並列化を検討。

---

### U-1003: VRループの回数上限
**問題**: 3回が「多すぎる」「少なすぎる」のか不明。
**影響Part**: Part10（本Part）
**暫定対応**: 3回を上限。運用開始後、実測値を見て調整。

---

### U-1004: SBOM 生成ツールの選定
**問題**: CycloneDX と SPDX のどちらを標準とするか不明（Part01 U-0102 と重複）。
**影響Part**: Part10（本Part）、Part13（Release Package）
**暫定対応**: CycloneDX を優先。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法（Truth Order）
- [docs/Part01.md](Part01.md) : 目標・DoD・失敗定義
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-0056, F-0057）
- [docs/Part02.md](Part02.md) : 用語運用ルール
- [docs/Part04.md](Part04.md) : 作業管理（TICKET）
- [docs/Part09.md](Part09.md) : Permission Tier
- [docs/Part11.md](Part11.md) : テスト設計（未作成）
- [docs/Part13.md](Part13.md) : Release Package（未作成）

### sources/
- [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md) : 原文（L667-693）

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_repo.ps1` : Verify 実行スクリプト（次タスクで作成予定）

### evidence/
- `evidence/verify_reports/` : Verify 実行結果
- `evidence/vr_loops/` : VRループログ
- `evidence/failure_classification/` : 失敗分類記録
- `evidence/metrics/` : Verify 時間メトリクス
- `evidence/humangate/` : HumanGate エスカレーション記録

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
