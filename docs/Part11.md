# Part 11：Repair（VRループ）運用（失敗分類→修正→再検証・収束戦略・ループ制限）

## 0. このPartの位置づけ
- **目的**: Verify失敗時の修正プロセスを体系化し、暴走を防ぎながら確実にGreenへ収束させる
- **依存**: Part10（Verify Gate・Fast/Full）、Part09（Permission Tier・HumanGate）、Part12（Evidence・ログ保存）
- **影響**: 全実装タスク（BUILD/VERIFY/REPAIRサイクル）、Part16（Metrics・収束性指標）

## 1. 目的（Purpose）

VCG/VIBE 2026 では「Verify失敗 → 修正 → 再検証」のループ（**VRループ**）を体系化し、以下を達成する：

1. **失敗分類の体系化**: 失敗を4カテゴリ（Spec/依存/実装/テスト）に分類し、適切な担当（GPT/Claude/HumanGate）へエスカレーション
2. **収束性の保証**: ループ制限（3回）を設け、暴走を防ぎながら確実にGreenへ収束
3. **ログの蓄積**: 全失敗をEvidenceへ保存し、「なぜ失敗したか」「どう修正したか」を追跡可能に
4. **再現性の確保**: 同じ失敗が再発した場合、過去のRepairログから解決策を検索可能に
5. **学習の促進**: 失敗パターンを蓄積し、SpecやAcceptance（受入条件）へフィードバック

**根拠**: [F-0057](../docs/FACTS_LEDGER.md#F-0057), [Part10](./Part10.md)

## 2. 適用範囲（Scope / Out of Scope）

### Scope（対象）
- BUILD後のVerify失敗（Fast Verify / Full Verify）
- Verify失敗の分類（4カテゴリ: Spec/依存/実装/テスト）
- 修正→再検証のループ（最大3回）
- HumanGateへのエスカレーション（3ループ超過時）
- Repairログの保存（evidence/repair_logs/）

### Out of Scope（対象外）
- Verify前の失敗（ビルドエラー、構文エラー）→ 即座修正（ループ不要）
- Spec自体の矛盾（Specの問題）→ Part00 ADR→docs workflow で修正
- リリース後の障害（本番障害）→ Part17 Rollback で対応
- 人為的なミス（コミット忘れ、ファイル未保存）→ 即座修正（ログ不要）

**注意**: 上記Out of Scopeの失敗は、別のルールで管理される（Part00, Part14, Part17参照）。

## 3. 前提（Assumptions）

本Partは以下を前提とする：

1. **Verify Gateの存在**: Part10 で定義された Fast/Full Verify が実装済み
2. **Evidence保存の整備**: Part12 で定義された evidence/ フォルダが利用可能
3. **HumanGate承認フロー**: Part09 で定義された HumanGate へのエスカレーション手順が確立
4. **失敗ログの形式**: Verifyツール（pytest/jest/lint）が構造化ログ（JSON/XML）を出力可能
5. **AI Role分離**: ChatGPT（Spec担当）、Claude Code（実装担当）、Z.ai（ログ要約）の役割が明確（Part03参照）

**根拠**: [F-0057](../docs/FACTS_LEDGER.md#F-0057), [Part09](./Part09.md), [Part10](./Part10.md)

## 4. 用語（Glossary参照：Part02）

本Partで使用する用語：

- **VRループ**: Verify失敗 → Repair（修正）→ 再Verify を繰り返すループ。最大3回で収束させる
- **収束**: Verifyが全てPASSし、Greenに戻ること。「収束しない」= 3ループ超えてもFAILが残る
- **失敗分類**: Verify失敗を4カテゴリ（Spec/依存/実装/テスト）に分類し、適切な担当へ振り分ける
- **Spec系失敗**: 前提条件違い、受入基準曖昧 → ChatGPT（Spec担当）へ戻す
- **依存/環境系失敗**: バージョン衝突、OS差異 → Docker/lock/CIで固定
- **実装系失敗**: 局所バグ、ロジックミス → Claude Code（実装担当）で最小修正
- **テスト系失敗**: テスト不足、壊れたテスト → テストを修正し、意図をSpecへ反映
- **暴走防止**: 同じ失敗が無限ループするのを防ぐため、ループ制限（3回）を設ける
- **HumanGateへエスカレーション**: 3ループ超過時、人間判断（設計変更/分割/範囲縮小）へ移行

**参照**: [glossary/GLOSSARY.md](../glossary/GLOSSARY.md), [Part02](./Part02.md)

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-1101: VRループ3回制限【MUST】

**定義**: 同じVerify失敗に対し、修正→再検証のループは **最大3回** で収束させる。

#### 条件
1. **ループカウント**: 同一のVerifyID（例: V-1001）が連続でFAILした回数を記録
2. **1ループ = 修正1回 + Verify1回**: 修正してVerifyを実行した時点で1ループ消費
3. **3ループ以内に収束**: 3回目のVerifyでPASSすること
4. **3ループ超過時はHumanGate**: 3回目のVerifyでFAILの場合、即座にHumanGateへエスカレーション

#### 例
```
Loop 1: Verify FAIL (V-1001: テスト3件失敗) → 修正 → Verify FAIL (V-1001: テスト1件失敗)
Loop 2: 修正 → Verify FAIL (V-1001: テスト1件失敗・同じ内容)
Loop 3: 修正 → Verify PASS
→ 収束成功（3ループ以内）
```

```
Loop 1: Verify FAIL → 修正 → Verify FAIL
Loop 2: 修正 → Verify FAIL
Loop 3: 修正 → Verify FAIL
→ 収束失敗 → HumanGateへエスカレーション（Part09参照）
```

**根拠**: [F-0057](../docs/FACTS_LEDGER.md#F-0057)
**Verify観点**: V-1101（後述）
**例外**: なし（全VRループに適用）

---

### R-1102: 失敗分類4カテゴリ【MUST】

**定義**: Verify失敗を以下の4カテゴリに分類し、適切な担当へエスカレーションする。

#### 分類基準

##### 1. Spec系失敗
- **症状**: 前提条件違い、受入基準曖昧、仕様矛盾
- **例**: 「この機能は〇〇の場合も動作すべき」だが、Specに記載なし
- **担当**: ChatGPT（Spec担当）→ Specを修正（Part00 ADR→docs workflow）
- **対応**: Specに前提条件・受入基準を追記 → ADR追加 → Verify再実行

##### 2. 依存/環境系失敗
- **症状**: バージョン衝突、OS差異、ライブラリ不足
- **例**: `python 3.9` で動くが `3.11` で失敗、`npm install` のバージョン不一致
- **担当**: Claude Code（実装担当）→ Docker/lock/CIで固定
- **対応**: `requirements.txt`, `package-lock.json`, `Dockerfile` を更新 → Verify再実行

##### 3. 実装系失敗
- **症状**: 局所バグ、ロジックミス、エッジケース未対応
- **例**: `if x > 0` だが `x == 0` のケースが未処理
- **担当**: Claude Code（実装担当）→ 最小修正
- **対応**: バグ箇所を特定 → 修正 → Verify再実行

##### 4. テスト系失敗
- **症状**: テスト不足、壊れたテスト、Flaky Test（不安定なテスト）
- **例**: テストが `assert x == 1` だが、実際は `x == 2` が正しい
- **担当**: Claude Code（実装担当）→ テストを修正
- **対応**: テストの意図をSpecへ反映 → テスト修正 → Verify再実行

**根拠**: [F-0057](../docs/FACTS_LEDGER.md#F-0057)
**Verify観点**: V-1102（後述）
**例外**: 複合失敗（複数カテゴリ混在）は、優先度順（Spec > 依存 > 実装 > テスト）で対応

---

### R-1103: Repairログ必須【MUST】

**定義**: 全Verify失敗と修正内容を `evidence/repair_logs/` に保存する。

#### 保存内容
1. **失敗時のVerifyログ**: どのVerifyID（V-XXXX）がFAILしたか
2. **失敗分類**: 4カテゴリのどれか（Spec/依存/実装/テスト）
3. **ループ回数**: 現在何ループ目か（1〜3）
4. **修正内容**: どのファイルを・どう変更したか（diff）
5. **再Verify結果**: 修正後のVerify結果（PASS/FAIL）

#### 形式
```markdown
# Repair Log

- **Timestamp**: 2026-01-10 12:00
- **VerifyID**: V-1001
- **FailureCategory**: 実装系（局所バグ）
- **Loop**: 1/3
- **FailureLog**: テスト3件失敗（test_user_login, test_user_logout, test_user_profile）
- **RootCause**: user.py L42 で `if password == ""` の判定漏れ
- **Fix**: user.py L42 に `if password == "" or password is None` を追加
- **Diff**: `git diff abc1234..def5678`
- **ReVerifyResult**: PASS（全テスト成功）
```

**根拠**: [F-0057](../docs/FACTS_LEDGER.md#F-0057), [Part12](./Part12.md)
**Verify観点**: V-1103（後述）
**例外**: なし（全Repairに適用）

---

### R-1104: HumanGateエスカレーション【MUST】

**定義**: 3ループ超過時、または根本原因不明時、HumanGateへエスカレーションする。

#### エスカレーション条件
1. **3ループ超過**: 3回目のVerifyでもFAILが残る
2. **根本原因不明**: Z.aiのログ要約、ChatGPTの分析でも原因特定できない
3. **設計変更必要**: Spec自体に矛盾があり、実装では解決不能

#### エスカレーション内容
- 失敗ログ（3ループ分）
- 分類結果（4カテゴリ）
- 試みた修正内容（diff）
- 現状（FAIL箇所の詳細）

#### 承認者の判断
- **A) 設計変更**: Specを修正（ADR追加 → Part00 workflow）
- **B) タスク分割**: 大きすぎるタスクを分割（Part04 VIBEKANBAN）
- **C) 範囲縮小**: 一部機能を削除し、まずは動くものをリリース
- **D) 調査SPIKE**: 原因不明のため、調査専用タスクを作成（隔離）

**根拠**: [F-0057](../docs/FACTS_LEDGER.md#F-0057), [Part09](./Part09.md)
**Verify観点**: V-1104（後述）
**例外**: なし（全HumanGateに適用）

---

### R-1105: 収束性指標の記録【SHOULD】

**定義**: VRループの収束性を定量的に記録し、プロジェクト健全性の指標とする。

#### 指標
1. **平均ループ回数**: 全タスクの平均ループ回数（目標: 1.5回以下）
2. **3ループ超過率**: 全タスク中、HumanGateへエスカレーションした割合（目標: 5%以下）
3. **失敗カテゴリ分布**: Spec/依存/実装/テストの失敗割合（改善ポイント特定）
4. **Flaky Test率**: 同じテストが複数回FAIL→PASSを繰り返す割合（目標: 0%）

#### 記録先
- `evidence/metrics/vr_loop_metrics.json`
- Dashboard（Part15参照）で可視化

**根拠**: [F-0023](../docs/FACTS_LEDGER.md#F-0023), [Part16](./Part16.md)
**Verify観点**: V-1105（後述）
**例外**: プロジェクト初期は指標蓄積不要（データ不足）

---

### R-1106: 同じ失敗の再発防止【SHOULD】

**定義**: 過去のRepairログを検索し、同じ失敗パターンを早期検出する。

#### 手順
1. **Verify失敗時**: 失敗メッセージ（エラーコード、スタックトレース）を抽出
2. **過去ログ検索**: `evidence/repair_logs/` から類似失敗を検索（grep/全文検索）
3. **同じパターン検出**: 過去に同じエラーで修正した履歴があるか確認
4. **修正方法の適用**: 過去の修正内容（diff）を参考に、同じ修正を適用
5. **Spec反映**: 同じ失敗が2回以上発生した場合、Specに「注意事項」として追記

**根拠**: [F-0002](../docs/FACTS_LEDGER.md#F-0002), [Part12](./Part12.md)
**Verify観点**: V-1106（後述）
**例外**: 初回失敗は検索不要（過去ログなし）

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順1: Verify失敗時の初動対応

Verifyが失敗したら、以下の手順で対応する。

1. **失敗ログを確認**
   ```bash
   # Verifyツール（pytest/jest/lint）の出力を確認
   pytest tests/ --verbose
   # 失敗箇所を特定
   ```

2. **VerifyIDを記録**
   - どのVerifyID（V-XXXX）がFAILしたか記録
   - 例: V-1001（ユニットテスト）、V-0901（禁止コマンド）

3. **ループカウント初期化**
   - 今回が1ループ目であることを記録
   - `evidence/repair_logs/VR_LOOP_<timestamp>_<VerifyID>.md` を作成

4. **失敗分類を実施**（手順2へ）

---

### 手順2: 失敗分類（4カテゴリ判定）

失敗ログを元に、4カテゴリのどれかを判定する。

1. **Spec系失敗の判定**
   - **症状**: 「この場合も動作すべき」だが、Specに記載なし
   - **判定基準**: Acceptanceに該当ケースが定義されていない
   - **対応**: ChatGPT（Spec担当）へエスカレーション → Spec修正

2. **依存/環境系失敗の判定**
   - **症状**: `ModuleNotFoundError`, `VersionConflict`, `OS差異`
   - **判定基準**: 依存ライブラリ、バージョン、環境変数が原因
   - **対応**: Claude Code（実装担当）→ Docker/lock/CI修正

3. **実装系失敗の判定**
   - **症状**: `AssertionError`, `IndexError`, `NullPointerException`
   - **判定基準**: コードロジックのバグ、エッジケース未対応
   - **対応**: Claude Code（実装担当）→ 最小修正

4. **テスト系失敗の判定**
   - **症状**: テストが間違っている、Flaky Test
   - **判定基準**: 実装は正しいが、テストの期待値が間違っている
   - **対応**: Claude Code（実装担当）→ テスト修正 + Spec反映

5. **分類結果を記録**
   ```markdown
   # Repair Log

   - **FailureCategory**: 実装系（局所バグ）
   ```

---

### 手順3: 修正実施（カテゴリ別）

分類結果に応じて、修正を実施する。

#### 3-1. Spec系失敗の場合

1. **ChatGPT（Spec担当）へエスカレーション**
   - 失敗ログ、Spec該当箇所を提示
   - 「この場合の動作仕様を明記してください」

2. **Spec修正**
   - ChatGPTが Spec（Part XX）を修正
   - ADR追加（Part00 workflow）

3. **再実装**
   - Claude Code（実装担当）が修正されたSpecに従い実装修正
   - Verify再実行

---

#### 3-2. 依存/環境系失敗の場合

1. **依存ファイル更新**
   ```bash
   # Python の場合
   pip freeze > requirements.txt
   # Node.js の場合
   npm install --package-lock
   ```

2. **Docker イメージ更新**
   ```dockerfile
   # Dockerfile
   FROM python:3.11-slim
   RUN pip install -r requirements.txt
   ```

3. **CI設定更新**
   ```yaml
   # .github/workflows/ci.yml
   - uses: actions/setup-python@v4
     with:
       python-version: '3.11'
   ```

4. **Verify再実行**
   ```bash
   docker build -t myapp .
   docker run myapp pytest tests/
   ```

---

#### 3-3. 実装系失敗の場合

1. **バグ箇所特定**
   ```bash
   # スタックトレースから該当ファイル・行番号を特定
   # 例: user.py:42 in login()
   ```

2. **最小修正**
   ```python
   # Before
   if password == "":
       raise ValueError("Password is empty")

   # After
   if password == "" or password is None:
       raise ValueError("Password is empty or None")
   ```

3. **Verify再実行**
   ```bash
   pytest tests/test_user.py -v
   ```

---

#### 3-4. テスト系失敗の場合

1. **テストの意図確認**
   - テストが期待する動作は何か？
   - 実装が正しいか、テストが正しいかを判定

2. **テスト修正**
   ```python
   # Before（間違ったテスト）
   assert user.age == 20

   # After（正しいテスト）
   assert user.age >= 18  # 成人であることを確認
   ```

3. **Specへ反映**
   - テストの意図をSpecに追記
   - 「ユーザーは18歳以上であること」

4. **Verify再実行**
   ```bash
   pytest tests/test_user.py -v
   ```

---

### 手順4: 再Verify実行

修正後、再度Verifyを実行する。

1. **Fast Verify実行**
   ```bash
   bash checks/verify_repo.sh
   ```

2. **結果判定**
   - **PASS**: 収束成功 → Repairログに「PASS」を記録 → 次タスクへ
   - **FAIL**: ループカウント+1 → 手順5（ループ継続判定）へ

---

### 手順5: ループ継続判定

再Verifyの結果に応じて、ループを継続するか判定する。

1. **ループ回数確認**
   - 現在のループ回数を確認（1, 2, 3）

2. **1〜2ループ目の場合**
   - 手順2（失敗分類）へ戻る
   - 別の修正アプローチを試す

3. **3ループ目でPASSの場合**
   - 収束成功
   - Repairログに「収束成功（3ループ）」を記録

4. **3ループ目でFAILの場合**
   - 収束失敗
   - HumanGateへエスカレーション（手順6へ）

---

### 手順6: HumanGateへエスカレーション

3ループ超過時、HumanGateへエスカレーションする。

1. **エスカレーション資料作成**
   ```markdown
   # HumanGate Escalation

   - **VerifyID**: V-1001
   - **FailureCategory**: 実装系（局所バグ）
   - **LoopCount**: 3/3
   - **FailureLogs**:
     - Loop 1: テスト3件失敗
     - Loop 2: テスト1件失敗（同じ内容）
     - Loop 3: テスト1件失敗（同じ内容）
   - **Fixes**:
     - Loop 1: user.py L42 修正
     - Loop 2: user.py L42 再修正
     - Loop 3: user.py L42 さらに修正
   - **CurrentStatus**: 依然として test_user_login が FAIL
   - **RootCause**: 不明（ログからは特定できず）
   ```

2. **承認者へ提出**
   - Part09 で定義された HumanGate 承認者へ提出
   - Slack/Email/Issue で通知

3. **承認者判断待ち**
   - 承認者が A) 設計変更 / B) 分割 / C) 範囲縮小 / D) SPIKE のいずれかを指示

4. **判断結果に従い対応**
   - A) Spec修正（ADR追加 → Part00 workflow）
   - B) タスク分割（Part04 VIBEKANBAN）
   - C) 範囲縮小（一部機能削除）
   - D) SPIKE作成（調査専用タスク、隔離）

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: 複合失敗（複数カテゴリ混在）

**状態**: 失敗が複数カテゴリにまたがる（例: Spec系 + 実装系）

**対応**:
1. **優先度順に対応**: Spec > 依存 > 実装 > テスト
2. **Spec系を先に修正**: Specが曖昧なまま実装修正しても無駄
3. **依存系を次に修正**: 環境が壊れていると実装テスト不能
4. **実装系を修正**: ロジックバグを修正
5. **テスト系を最後に修正**: 実装が正しくなってからテスト修正

**Verify観点**: V-1107（後述）
**Evidence**: E-1101（複合失敗ログ）

---

### 例外2: Flaky Test（不安定なテスト）

**状態**: 同じテストが FAIL → PASS → FAIL を繰り返す

**検知方法**:
- 同じVerifyIDが「PASS」後に再び「FAIL」になった場合

**対応**:
1. **Flaky Test判定**: 2回以上PASSとFAILを繰り返した場合
2. **テスト隔離**: 該当テストを `@pytest.mark.flaky` でマーク
3. **原因調査**: 非同期処理、タイムアウト、外部依存が原因か確認
4. **修正**: 非同期待機、モック化、タイムアウト延長
5. **Spec反映**: 「このテストは非同期処理のため不安定」を明記

**Verify観点**: V-1108（後述）
**Evidence**: E-1102（Flaky Testログ）

---

### 例外3: ループカウント不正（手動修正で増加）

**状態**: 自動カウントではなく、手動でコードを修正してVerifyを複数回実行

**検知方法**:
- Repairログが存在しないのに、Verify履歴が複数ある

**対応**:
1. **警告**: 「Repairログなしでの修正が検出されました」
2. **ログ補完**: 手動修正内容を Repairログへ追記
3. **ループカウント補正**: 実際の修正回数を推定してカウント

**Verify観点**: V-1109（後述）
**Evidence**: E-1103（手動修正検出ログ）

---

### 例外4: HumanGate承認待ちタイムアウト

**状態**: HumanGateへエスカレーション後、24時間以内に承認なし

**対応**:
1. **再通知**: Slack/Email で再度通知
2. **48時間後**: タスクを BLOCKED 状態へ移行（Part04 VIBEKANBAN）
3. **1週間後**: タスクを INBOX へ戻し、優先度を再評価

**Verify観点**: V-1110（後述）
**Evidence**: E-1104（HumanGate承認待ちログ）

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-1101: VRループ3回制限の検証

**判定条件**:
1. 同一VerifyIDに対し、ループ回数が3回以内であること

**合否**:
- **PASS**: ループ回数 ≤ 3 かつ 最終Verify結果がPASS
- **FAIL**: ループ回数 > 3 または 3回目でもFAIL

**判定方法**:
```bash
# evidence/repair_logs/ から該当VerifyIDのループ回数を集計
grep "Loop:" evidence/repair_logs/VR_LOOP_*_V-1001.md | wc -l
```

**ログ**: evidence/verify_reports/V-1101_YYYYMMDD.md

---

### V-1102: 失敗分類4カテゴリの検証

**判定条件**:
1. Repairログに「FailureCategory」が記録されていること
2. カテゴリが Spec/依存/実装/テスト のいずれかであること

**合否**:
- **PASS**: FailureCategoryが4カテゴリのいずれかに分類済み
- **FAIL**: FailureCategoryが未記入、または不正な値

**判定方法**:
```bash
# Repairログから FailureCategory を抽出
grep "FailureCategory:" evidence/repair_logs/VR_LOOP_*.md
```

**ログ**: evidence/verify_reports/V-1102_YYYYMMDD.md

---

### V-1103: Repairログ必須の検証

**判定条件**:
1. Verify失敗時、必ず Repairログが作成されていること
2. ログに必須項目（Timestamp, VerifyID, FailureCategory, Loop, Fix, ReVerifyResult）が含まれること

**合否**:
- **PASS**: Verify失敗の全件にRepairログあり
- **FAIL**: Repairログ未作成、または必須項目不足

**判定方法**:
```bash
# Verify失敗の件数とRepairログの件数が一致するか確認
grep -r "FAIL" evidence/verify_reports/ | wc -l
ls evidence/repair_logs/ | wc -l
```

**ログ**: evidence/verify_reports/V-1103_YYYYMMDD.md

---

### V-1104: HumanGateエスカレーションの検証

**判定条件**:
1. 3ループ超過時、HumanGateエスカレーションが記録されていること
2. エスカレーション資料に必須項目（VerifyID, LoopCount, FailureLogs, Fixes, RootCause）が含まれること

**合否**:
- **PASS**: 3ループ超過の全件にHumanGateエスカレーションあり
- **FAIL**: エスカレーション未記録、または必須項目不足

**判定方法**:
```bash
# 3ループ超過のRepairログを検出
grep "Loop: 3/3" evidence/repair_logs/*.md -A 1 | grep "FAIL"
# HumanGateエスカレーションログを確認
ls evidence/humangate_escalations/
```

**ログ**: evidence/verify_reports/V-1104_YYYYMMDD.md

---

### V-1105: 収束性指標の検証

**判定条件**:
1. `evidence/metrics/vr_loop_metrics.json` に指標が記録されていること
2. 指標に必須項目（平均ループ回数, 3ループ超過率, 失敗カテゴリ分布, Flaky Test率）が含まれること

**合否**:
- **PASS**: 指標ファイルが存在し、必須項目あり
- **FAIL**: 指標ファイル未作成、または必須項目不足

**判定方法**:
```bash
# 指標ファイルの存在確認
test -f evidence/metrics/vr_loop_metrics.json && echo "PASS" || echo "FAIL"
```

**ログ**: evidence/verify_reports/V-1105_YYYYMMDD.md

**例外**: プロジェクト初期（データ不足）は検証スキップ

---

### V-1106: 同じ失敗の再発防止検証

**判定条件**:
1. 過去に同じエラーメッセージで失敗した履歴があるか検索されていること
2. 同じ失敗が2回以上発生した場合、Specに「注意事項」が追記されていること

**合否**:
- **PASS**: 過去ログ検索が実施され、再発防止策が記録されている
- **FAIL**: 同じ失敗が2回以上発生しているが、Spec未反映

**判定方法**:
```bash
# 同じエラーメッセージが複数回出現するか確認
grep "ModuleNotFoundError: No module named 'foo'" evidence/repair_logs/*.md | wc -l
```

**ログ**: evidence/verify_reports/V-1106_YYYYMMDD.md

---

### V-1107: 複合失敗の優先度検証

**判定条件**:
1. 複合失敗時、優先度順（Spec > 依存 > 実装 > テスト）に対応されていること

**合否**:
- **PASS**: Repairログに「対応順序: Spec → 依存 → ...」が記録されている
- **FAIL**: 優先度無視（実装を先に修正してSpecは後回し）

**判定方法**:
```bash
# Repairログから対応順序を確認
grep "対応順序:" evidence/repair_logs/*.md
```

**ログ**: evidence/verify_reports/V-1107_YYYYMMDD.md

---

### V-1108: Flaky Test検出の検証

**判定条件**:
1. 同じテストが FAIL → PASS → FAIL を繰り返した場合、Flaky Testとして記録されていること

**合否**:
- **PASS**: Flaky Testログが存在し、隔離マーク（@pytest.mark.flaky）あり
- **FAIL**: Flaky Testが検出されたが、未対応

**判定方法**:
```bash
# 同じテストが複数回FAILとPASSを繰り返しているか確認
grep "test_user_login" evidence/repair_logs/*.md | grep -E "(FAIL|PASS)"
```

**ログ**: evidence/verify_reports/V-1108_YYYYMMDD.md

---

### V-1109: ループカウント不正検出

**判定条件**:
1. Verify履歴とRepairログのループ回数が一致すること

**合否**:
- **PASS**: Verify履歴回数 == Repairログのループ回数
- **FAIL**: Verify履歴回数 > Repairログのループ回数（手動修正の可能性）

**判定方法**:
```bash
# Verify履歴の回数
grep "V-1001" evidence/verify_reports/*.md | wc -l
# Repairログのループ回数
grep "Loop:" evidence/repair_logs/VR_LOOP_*_V-1001.md | wc -l
```

**ログ**: evidence/verify_reports/V-1109_YYYYMMDD.md

---

### V-1110: HumanGate承認待ちタイムアウト検証

**判定条件**:
1. HumanGateエスカレーション後、24時間以内に承認があること

**合否**:
- **PASS**: エスカレーション日時から24時間以内に承認記録あり
- **FAIL**: 24時間経過しても承認なし

**判定方法**:
```bash
# エスカレーション日時と承認日時を比較
grep "EscalationTime:" evidence/humangate_escalations/*.md
grep "ApprovalTime:" evidence/humangate_escalations/*.md
```

**ログ**: evidence/verify_reports/V-1110_YYYYMMDD.md

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-1101: Repairログ（VRループ履歴）

**内容**: Verify失敗 → 修正 → 再Verify のループ履歴

**形式**:
```markdown
# Repair Log

- **Timestamp**: 2026-01-10 12:00
- **VerifyID**: V-1001
- **FailureCategory**: 実装系（局所バグ）
- **Loop**: 1/3
- **FailureLog**: テスト3件失敗（test_user_login, test_user_logout, test_user_profile）
- **RootCause**: user.py L42 で `if password == ""` の判定漏れ
- **Fix**: user.py L42 に `if password == "" or password is None` を追加
- **Diff**:
  ```diff
  - if password == "":
  + if password == "" or password is None:
  ```
- **ReVerifyResult**: PASS（全テスト成功）
```

**保存先**: evidence/repair_logs/VR_LOOP_20260110_120000_V-1001.md

---

### E-1102: Flaky Testログ

**内容**: 不安定なテストの検出履歴

**形式**:
```markdown
# Flaky Test Log

- **Timestamp**: 2026-01-10 15:00
- **TestName**: test_user_login
- **Occurrences**:
  - 2026-01-10 12:00: FAIL
  - 2026-01-10 12:30: PASS
  - 2026-01-10 13:00: FAIL
- **RootCause**: 非同期処理のタイムアウト（外部API呼び出し）
- **Fix**: モック化 + タイムアウト延長（5秒 → 10秒）
- **IsolationMark**: `@pytest.mark.flaky(reruns=3)`
```

**保存先**: evidence/flaky_tests/FLAKY_TEST_20260110_150000.md

---

### E-1103: 手動修正検出ログ

**内容**: Repairログなしでの手動修正検出

**形式**:
```markdown
# Manual Fix Detection Log

- **Timestamp**: 2026-01-10 18:00
- **VerifyID**: V-1001
- **DetectionMethod**: Verify履歴3回 vs Repairログ1回
- **MissingLogs**: Loop 2, Loop 3 のRepairログなし
- **Action**: 手動でRepairログを補完依頼
```

**保存先**: evidence/manual_fix_detections/MANUAL_FIX_20260110_180000.md

---

### E-1104: HumanGateエスカレーションログ

**内容**: 3ループ超過時のHumanGate提出履歴

**形式**:
```markdown
# HumanGate Escalation Log

- **Timestamp**: 2026-01-10 20:00
- **VerifyID**: V-1001
- **LoopCount**: 3/3
- **FailureLogs**:
  - Loop 1: テスト3件失敗
  - Loop 2: テスト1件失敗（同じ内容）
  - Loop 3: テスト1件失敗（同じ内容）
- **Fixes**:
  - Loop 1: user.py L42 修正
  - Loop 2: user.py L42 再修正
  - Loop 3: user.py L42 さらに修正
- **CurrentStatus**: 依然として test_user_login が FAIL
- **RootCause**: 不明（ログからは特定できず）
- **EscalationTime**: 2026-01-10 20:00
- **ApprovalTime**: 2026-01-11 10:00（24時間以内）
- **Decision**: A) 設計変更（Specに「パスワードがNoneの場合も許容」を追記）
```

**保存先**: evidence/humangate_escalations/HUMANGATE_20260110_200000_V-1001.md

---

### E-1105: VRループ指標

**内容**: プロジェクト全体の収束性指標

**形式**:
```json
{
  "timestamp": "2026-01-10T23:00:00Z",
  "total_tasks": 50,
  "vr_loop_stats": {
    "average_loops": 1.4,
    "loop_distribution": {
      "1": 30,
      "2": 15,
      "3": 3,
      ">3": 2
    },
    "escalation_rate": 0.04
  },
  "failure_category_distribution": {
    "Spec": 10,
    "依存": 5,
    "実装": 25,
    "テスト": 10
  },
  "flaky_test_rate": 0.02
}
```

**保存先**: evidence/metrics/vr_loop_metrics.json

---

## 10. チェックリスト

- [x] R-1101: VRループ3回制限が定義され、HumanGateエスカレーションが明記されている
- [x] R-1102: 失敗分類4カテゴリ（Spec/依存/実装/テスト）が定義されている
- [x] R-1103: Repairログ必須が定義され、形式が明記されている
- [x] R-1104: HumanGateエスカレーション条件と手順が明記されている
- [x] R-1105: 収束性指標の記録が定義されている
- [x] R-1106: 同じ失敗の再発防止手順が明記されている
- [x] 手順1〜6が「人間がそのまま実行できる粒度」で記述されている
- [x] 例外処理1〜4が「失敗分岐・復旧・エスカレーション」を含む
- [x] V-1101〜V-1110が「判定条件・合否・ログ」を含む
- [x] E-1101〜E-1105が「形式・保存先」を含む
- [x] 全ルールに根拠（F-XXXX or Part XX）が明記されている

## 11. 未決事項（推測禁止）

### U-1101: Z.aiのログ要約能力
**問題**: 3ループ超過時に「Z.aiでログ要約 → GPTで根本原因」とあるが、Z.aiの要約精度が未検証

**影響**: ログが長大な場合、要約が不十分で根本原因特定できない可能性

**対応**: Z.aiの要約精度を検証し、不十分な場合は人間が要約（HumanGate）

---

### U-1102: Flaky Test自動検出
**問題**: Flaky Test（FAIL→PASS→FAIL）を自動検出する仕組みが未実装

**影響**: 手動で検出する必要があり、見落としの可能性

**対応**: CI/CDでテスト履歴を記録し、統計的に検出する仕組みを検討（ADRで決定）

---

### U-1103: HumanGate承認者の指定
**問題**: HumanGateへエスカレーション時の「承認者」が未定義（Part09でも未決）

**影響**: エスカレーション先が不明確で、承認待ちが長期化

**対応**: Part09（Permission Tier）で「HumanGateの承認者リスト」を定義

---

### U-1104: 収束性指標の閾値
**問題**: 平均ループ回数1.5回以下、3ループ超過率5%以下の閾値が「推奨値」であり、プロジェクト特性で変わる可能性

**影響**: プロジェクトによっては閾値が厳しすぎる/緩すぎる

**対応**: プロジェクト開始時にADRで閾値を決定（初期は推奨値で運用）

---

## 12. 参照（パス）

### docs/
- [Part00](./Part00.md) : SSOT憲法（ADR→docs workflow）
- [Part02](./Part02.md) : 用語管理（GLOSSARY統一）
- [Part03](./Part03.md) : AI Pack（Core4役割、ChatGPT/Claude/Z.ai）
- [Part04](./Part04.md) : ワーク管理（VIBEKANBAN, BLOCKED状態）
- [Part09](./Part09.md) : Permission Tier（HumanGate承認フロー）
- [Part10](./Part10.md) : Verify Gate（Fast/Full、VRループ開始点）
- [Part12](./Part12.md) : Evidence管理（ログ保存形式・フォルダ構造）
- [Part16](./Part16.md) : Metrics（収束性指標・ダッシュボード）
- [FACTS_LEDGER.md](./FACTS_LEDGER.md) : F-0002, F-0023, F-0057

### sources/
- （なし: 本Partは主にF-0057を根拠とする）

### evidence/
- evidence/repair_logs/ : E-1101（VRループ履歴）
- evidence/flaky_tests/ : E-1102（Flaky Testログ）
- evidence/manual_fix_detections/ : E-1103（手動修正検出ログ）
- evidence/humangate_escalations/ : E-1104（HumanGateエスカレーションログ）
- evidence/metrics/ : E-1105（VRループ指標）

### decisions/
- [ADR-0001](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス（Verify→Repair workflow）
