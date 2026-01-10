# Part 15：実運用プレイブック（Start→Work→Verify→Commit→PR・VRループ・HumanGate・4点証跡）

## 0. このPartの位置づけ
- **目的**: 実運用で迷わず安全に作業を進めるための標準操作手順とチェックポイントを明文化する
- **依存**: [Part10](Part10.md)（Verify Gate）、[Part09](Part09.md)（Permission Tier）、[Part14](Part14.md)（変更管理）、[Part11](Part11.md)（VRループ）
- **影響**: 全 Part（全作業フローはこのPlaybookに従う）、[Part12](Part12.md)（Evidence）、[Part13](Part13.md)（Release）

## 1. 目的（Purpose）

本Part15は **Execution Playbook（実行手順書）** として、以下を保証する：

1. **作業開始から完了までの標準フロー**: Start → Work → Verify → Commit → PR の5ステップを固定化
2. **Fail時の自動復旧**: Verify失敗時の VRループ（Verify → Repair → Verify）による収束
3. **HumanGate判断**: 自動復旧不能時の人間承認フロー
4. **4点証跡コミット運用**: Code + Test + Evidence + CHANGELOG を常に同一コミットへ含める
5. **迷わない**: どのタイミングで何をすべきか、判断基準を機械的に明記

**根拠**: [FACTS_LEDGER F-0003](FACTS_LEDGER.md)（統一手順の必要性）、[ADR-0001](../decisions/0001-ssot-governance.md)

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（対象）
- docs/ 配下の全Part更新作業
- checks/ 配下の検証スクリプト更新
- glossary/ の用語追加・変更
- decisions/ への ADR 追加
- コード実装（実装時はコード + テスト + Evidence + CHANGELOG の4点セット必須）
- 全Git操作（commit, PR作成, merge）

### Out of Scope（対象外）
- sources/ 配下の操作（Part00, Part09で別途規定）
- 緊急Hotfix（Part14 例外2で別途規定）
- リリース作業（Part13で別途規定）
- インフラ操作（別途定義予定）

**注意**: 上記Out of Scopeの作業も「Verifyを通す」点は共通。

---

## 3. 前提（Assumptions）

本Partは以下を前提とする：

1. **Git運用**: ブランチ戦略（feature/, bugfix/, hotfix/）が確立している
2. **Verify Gate通過**: 全変更は Part10 の Fast Verify 最低限を通過してからコミット
3. **VRループ3回制限**: 3回で解決しない場合は HumanGate へエスカレーション（Part11参照）
4. **Permission Tier遵守**: AI は ExecLimited 以下、破壊操作は HumanGate 必須（Part09参照）
5. **4点証跡の同一コミット化**: Code変更 + Test + Evidence + CHANGELOG を必ず同一コミットに含める

**根拠**: [Part00](Part00.md), [Part09](Part09.md), [Part10](Part10.md), [Part11](Part11.md), [Part14](Part14.md)

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **VRループ**: [glossary/GLOSSARY.md#VRループ](../glossary/GLOSSARY.md)（Verify → Repair → Verify の反復）
- **HumanGate**: 人間承認が必須の操作（破壊的・不可逆・高リスク）
- **4点証跡**: Code + Test + Evidence + CHANGELOG を同一コミットに含めるルール
- **Fast Verify**: Part10 で定義された高速検証（2分以内）
- **Full Verify**: Part10 で定義された完全検証（30分以内）
- **PATCHSET**: 最小差分の変更単位（Part14参照）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-1501: Start→Work→Verify→Commit→PRの5ステップ【MUST】

**定義**: 全作業は以下の5ステップで実行する。

#### ステップ構成
1. **Start**: ブランチ作成、作業準備、Permission確認
2. **Work**: 実装・文書作成・修正（PATCHSET単位）
3. **Verify**: Part10 の Fast Verify 実行、失敗時は VRループ
4. **Commit**: 4点証跡（Code + Test + Evidence + CHANGELOG）を同一コミットへ
5. **PR**: Pull Request 作成、レビュー、マージ

**禁止例**:
- ❌ Verify前にコミット
- ❌ CHANGELOGを別コミットで追加
- ❌ Evidenceなしでコミット

**根拠**: [F-0003](FACTS_LEDGER.md)、[Part14](Part14.md)
**Verify観点**: V-1501（後述）
**例外**: なし（全作業に適用）

---

### R-1502: VRループ3回制限【MUST】

**定義**: Verify失敗時、以下のVRループで自動収束を試みる。

#### ループ構成
1. **Verify**: Part10 の Fast Verify 実行 → 失敗
2. **Repair**: 失敗原因を特定・修正
3. **Verify**: 再度 Fast Verify 実行
4. **制限**: 上記を最大3回まで反復、3回で解決しなければ HumanGate

**エスカレーション条件**:
- 3回目の Verify でも FAIL
- 原因不明（ログに手がかりなし）
- 修正方針が複数あり選択不能

**根拠**: [Part11](Part11.md), [F-0003](FACTS_LEDGER.md)
**Verify観点**: V-1502（後述）
**例外**: なし

---

### R-1503: HumanGate必須操作【MUST】

**定義**: 以下の操作は **必ず人間承認** を経る（AI 単独では不可）。

#### HumanGate対象
1. **破壊操作**: ファイル削除、フォルダ削除、履歴改変
2. **全域変更**: 複数ファイルへの一括置換・リファクタリング
3. **sources/ 操作**: 新規追加・既存変更・削除
4. **リリース確定**: Release フォルダ生成、バージョン確定
5. **VRループ3回超え**: 自動収束失敗時のエスカレーション
6. **Permission超過**: ExecLimited を超える操作

**承認手順**:
1. AI が操作を提案（Dry-run結果含む）
2. 人間が影響範囲をレビュー
3. 人間が承認（Evidence に「承認者・日時・理由」を記録）
4. AI が実行
5. Verify を実行し、破壊がないことを確認

**根拠**: [Part09 R-0904](Part09.md), [F-0031](FACTS_LEDGER.md)
**Verify観点**: V-1503（後述）
**例外**: なし

---

### R-1504: 4点証跡コミット運用【MUST】

**定義**: コミット時、以下の4点を **必ず同一コミット** に含める。

#### 4点証跡の内訳
1. **Code**: 実装コード or ドキュメント変更
2. **Test**: テストコード追加 or テスト実行結果
3. **Evidence**: Verify実行結果（`evidence/verify_reports/*.md`）
4. **CHANGELOG**: 変更履歴（Part14 R-1403形式）

**理由**: 4点がバラバラのコミットだと、「いつのVerifyが通ったか」が追跡不能になる。

**形式**:
```bash
# 正しい例（4点を同一コミット）
(コマンド名 add) docs/Part15.md \
  tests/test_part15.py \
  evidence/verify_reports/20260110_153000_part15_verify.md \
  CHANGELOG.md
(コマンド名 commit) -m "Add: Part15 実運用プレイブック（4点証跡）"
```

**根拠**: [Part14](Part14.md), [F-0003](FACTS_LEDGER.md)
**Verify観点**: V-1504（後述）
**例外**: なし

---

### R-1505: ブランチ命名規則【SHOULD】

**定義**: ブランチ名は以下の形式を推奨。

#### 形式
- `feature/\<Part番号\>-\<簡潔な説明\>` : 新機能追加
- `bugfix/\<Part番号\>-\<簡潔な説明\>` : バグ修正
- `hotfix/\<緊急度\>-\<簡潔な説明\>` : 緊急修正
- `docs/\<Part番号\>-\<簡潔な説明\>` : ドキュメント更新

#### 例
- `feature/part15-execution-playbook`
- `bugfix/part10-verify-gate-infinite-loop`
- `hotfix/critical-security-fix`

**理由**: ブランチ名から「何の作業か」が一目瞭然になる

**根拠**: [Part14](Part14.md)
**Verify観点**: V-1505（後述）
**例外**: プロジェクト方針で別形式を採用する場合はADRで明記

---

### R-1506: コミットメッセージ形式【SHOULD】

**定義**: コミットメッセージは以下の形式を推奨。

#### 形式
```
\<種別\>: \<Part番号\> \<変更概要50文字以内\>

- 詳細1
- 詳細2
- ADR: decisions/XXXX-xxx.md（該当する場合）
- Verify: evidence/verify_reports/YYYYMMDD_HHMMSS_xxx.md
```

#### 種別
- **Add**: 新規追加
- **Change**: 既存変更
- **Fix**: バグ修正
- **Remove**: 削除・非推奨化

#### 例
```
Add: Part15 実運用プレイブック（Start→Work→Verify→Commit→PR）

- 5ステップフロー、VRループ、HumanGate、4点証跡を明文化
- ADR: decisions/0001-ssot-governance.md
- Verify: evidence/verify_reports/20260110_153000_part15_fast.md
```

**根拠**: [Part14 R-1403](Part14.md)
**Verify観点**: V-1506（後述）
**例外**: プロジェクト方針で別形式を採用する場合はADRで明記

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順1: Start（作業開始）

以下の手順で作業を開始する。

1. **最新mainへ同期**
   ```bash
   (コマンド名 checkout) main
   (コマンド名 pull) origin main
   ```

2. **ブランチ作成**（R-1505参照）
   ```bash
   (コマンド名 checkout) -b feature/part15-execution-playbook
   ```

3. **Permission確認**
   - 作業内容が **ReadOnly/PatchOnly/ExecLimited/HumanGate** のどれか確認
   - 破壊操作が必要なら HumanGate 承認を先に取得（Part09参照）

4. **作業ログ開始**
   ```bash
   echo "Start: $(date) - Part15 実運用プレイブック作成" >> WORK/work_log.txt
   ```

---

### 手順2: Work（実装・修正）

以下の手順で実装・修正を行う。

1. **PATCHSET単位の変更**（Part14 R-1401参照）
   - 1つの目的のみに限定（バグ修正 OR 機能追加、混ぜない）
   - 最小差分にとどめる

2. **ADR確認**
   - 仕様変更を含む場合、ADR が承認済みかを確認（Part14 R-1402参照）
   - ADR未承認なら Work を中断し、ADR作成へ

3. **テスト準備**
   - 実装と並行してテストコードを作成（TDD推奨）
   - テストコードがない場合、手動テスト手順を明記

4. **作業完了マーク**
   ```bash
   echo "Work Complete: $(date) - 変更ファイル: docs/Part15.md" >> WORK/work_log.txt
   ```

---

### 手順3: Verify（検証）

以下の手順で検証を実行する。

1. **Fast Verify実行**（Part10参照）
   ```powershell
   pwsh .\checks\verify_repo.ps1 Fast
   ```

2. **PASS確認**
   - 全チェックが PASS → 手順4（Commit）へ
   - 1つでも FAIL → VRループへ（R-1502参照）

3. **VRループ（失敗時）**
   - **Loop 1**:
     1. Verify失敗ログを確認（`evidence/verify_reports/*.md`）
     2. 失敗箇所を修正
     3. 再度 Fast Verify 実行
   - **Loop 2**:
     1. まだ FAIL なら再度修正
     2. 再度 Fast Verify 実行
   - **Loop 3**:
     1. まだ FAIL なら最終修正
     2. 再度 Fast Verify 実行
   - **Loop 3でもFAIL → HumanGateへエスカレーション**（R-1503参照）

4. **Evidence保存**
   - Fast Verify の実行結果が `evidence/verify_reports/` に自動保存される
   - 後でコミットに含める（R-1504参照）

---

### 手順4: Commit（コミット）

以下の手順でコミットを作成する。

1. **4点証跡を確認**（R-1504参照）
   - Code: `docs/Part15.md`（変更済み）
   - Test: `tests/test_part15.py`（存在する場合）
   - Evidence: `evidence/verify_reports/20260110_153000_part15_fast.md`（Verify実行結果）
   - CHANGELOG: `CHANGELOG.md`（更新済み）

2. **CHANGELOG更新**（Part14 R-1403参照）
   ```markdown
   ## 2026-01-10

   ### Added
   - **[Part15]** 実運用プレイブック（Start→Work→Verify→Commit→PR）を追加
     - 担当: Claude Code
     - ADR: decisions/0001-ssot-governance.md
     - Commit: (pending)
   ```

3. **4点を同一コミットへ追加**
   ```bash
   (コマンド名 add) docs/Part15.md \
     evidence/verify_reports/20260110_153000_part15_fast.md \
     CHANGELOG.md
   ```

4. **コミット作成**（R-1506参照）
   ```bash
   (コマンド名 commit) -m "Add: Part15 実運用プレイブック（Start→Work→Verify→Commit→PR）

   - 5ステップフロー、VRループ、HumanGate、4点証跡を明文化
   - ADR: decisions/0001-ssot-governance.md
   - Verify: evidence/verify_reports/20260110_153000_part15_fast.md"
   ```

---

### 手順5: PR（Pull Request）

以下の手順でPRを作成・マージする。

1. **ブランチをpush**
   ```bash
   (コマンド名 push) origin feature/part15-execution-playbook
   ```

2. **PR作成**
   - GitHub/GitLab でPRを作成
   - PRテンプレートに以下を含める：
     - 変更概要
     - Verify結果（`evidence/verify_reports/*.md` へのリンク）
     - ADRリンク（該当する場合）
     - チェックリスト

3. **レビュー待機**
   - レビュー承認を待つ
   - 修正指摘があれば手順2（Work）へ戻る

4. **マージ**
   - レビュー承認後、mainへマージ
   - マージ後、ブランチを削除

5. **完了確認**
   ```bash
   echo "PR Merged: $(date) - Part15 completed" >> WORK/work_log.txt
   ```

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: VRループ3回で解決しない

**状態**: Verify → Repair → Verify を3回繰り返してもPASSしない

**対応**:
1. **HumanGateへエスカレーション**（R-1503参照）
   - 失敗ログ、修正履歴、現状をまとめて提出
2. **承認者判断**:
   - A) Verifyルールを一時的に緩和（ADR追加）
   - B) 変更を中止（Revert）
   - C) 追加調査（SPIKE扱い、Part14参照）
3. **Evidence記録**
   - `evidence/humangate/VR_LOOP_FAIL_20260110.md` に経緯を記録

**Verify観点**: V-1502（後述）
**Evidence**: E-1501（VRループ失敗記録）

---

### 例外2: Permission超過操作が必要

**状態**: ExecLimited を超える操作（削除、全域変更等）が必要

**対応**:
1. **操作を停止**
2. **HumanGateへ提案**
   - 操作内容、理由、影響範囲、Dry-run結果を提示
3. **承認待機**
   - 承認されたら実行
   - 却下されたら代替手段を検討
4. **Evidence記録**
   - `evidence/humangate/PERMISSION_OVERRIDE_20260110.md` に承認記録

**Verify観点**: V-1503（後述）
**Evidence**: E-1502（HumanGate承認記録）

---

### 例外3: コミット後にVerify失敗が発覚

**状態**: コミット後、追加検証でFAILが発覚（Full Verifyで検出等）

**対応**:
1. **即座にRevert**
   ```bash
   (コマンド名 revert) HEAD
   (コマンド名 push) origin main
   ```
2. **Full Verify実行**（Revert後の整合性確認）
3. **修正PR作成**
   - 新しいブランチで修正
   - 手順1（Start）から再実行
4. **Evidence記録**
   - `evidence/rollback_logs/REVERT_20260110.md` に経緯を記録

**Verify観点**: V-1507（後述）
**Evidence**: E-1503（Revert記録）

---

### 例外4: CHANGELOGの更新を忘れた

**状態**: コミット後、CHANGELOGが未更新と気付いた

**対応**:
1. **追加コミット禁止**（4点証跡が崩れる）
2. **コミットを修正**
   ```bash
   # CHANGELOGを更新
   (コマンド名 add) CHANGELOG.md
   # 直前のコミットに追加（まだpush前の場合）
   (コマンド名 commit) --amend --no-edit
   ```
3. **すでにpush済みの場合**
   - Revert して再作成（例外3参照）
4. **Evidence記録**
   - `evidence/commit_fixes/CHANGELOG_FIX_20260110.md` に経緯を記録

**Verify観点**: V-1504（後述）
**Evidence**: E-1504（コミット修正記録）

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-1501: 5ステップ遵守の検証

**判定条件**: コミットが以下の5ステップを経ているか
1. ブランチ作成（Start）
2. 実装・修正（Work）
3. Fast Verify実行（Verify）
4. 4点証跡コミット（Commit）
5. PR作成（PR）

**合否**:
- **PASS**: 全ステップを順序通りに実行
- **FAIL**: ステップスキップ、順序違反

**判定方法**:
```bash
# コミット履歴からブランチ作成を確認
(コマンド名 log) --oneline --graph
# Evidenceに Fast Verify 実行記録があるか確認
ls evidence/verify_reports/ | grep "$(date +%Y%m%d)"
```

**ログ**: `evidence/verify_reports/V-1501_YYYYMMDD.md`

---

### V-1502: VRループ3回制限の検証

**判定条件**: Verify失敗時、VRループが3回以内で収束しているか

**合否**:
- **PASS**: 3回以内で収束、またはHumanGateへエスカレーション
- **FAIL**: 3回超えてもループ継続（無限ループ化）

**判定方法**:
```bash
# evidence/ のVRループログを確認
grep "VRループ" evidence/verify_reports/V-1502_*.md | wc -l
```

**ログ**: `evidence/verify_reports/V-1502_YYYYMMDD.md`

---

### V-1503: HumanGate承認記録の検証

**判定条件**: HumanGate操作に対応するEvidence（承認記録）が存在するか

**合否**:
- **PASS**: `evidence/humangate/*.md` に承認記録が存在
- **FAIL**: 記録なし

**判定方法**:
```bash
# humangate/ に当日の承認記録があるか確認
ls evidence/humangate/ | grep "$(date +%Y%m%d)"
```

**ログ**: `evidence/verify_reports/V-1503_YYYYMMDD.md`

---

### V-1504: 4点証跡コミットの検証

**判定条件**: 1つのコミットに以下の4点が含まれているか
1. Code変更
2. Test（存在する場合）
3. Evidence（Verify実行結果）
4. CHANGELOG更新

**合否**:
- **PASS**: 4点が同一コミットに含まれる
- **FAIL**: 4点がバラバラのコミット

**判定方法**:
```bash
# 最新コミットに含まれるファイルを確認
(コマンド名 show) --name-only HEAD
# CHANGELOGとEvidenceが含まれるか確認
(コマンド名 show) --name-only HEAD | grep -E "(CHANGELOG.md|evidence/)"
```

**ログ**: `evidence/verify_reports/V-1504_YYYYMMDD.md`

---

### V-1505: ブランチ命名規則の検証

**判定条件**: ブランチ名が R-1505 の形式に準拠しているか

**合否**:
- **PASS**: 形式準拠
- **WARN**: 形式不正（警告のみ、Failではない）

**判定方法**:
```bash
# 現在のブランチ名を確認
(コマンド名 branch) --show-current
# feature/, bugfix/, hotfix/, docs/ のいずれかで始まるか確認
(コマンド名 branch) --show-current | grep -E "^(feature|bugfix|hotfix|docs)/"
```

**ログ**: `evidence/verify_reports/V-1505_YYYYMMDD.md`

---

### V-1506: コミットメッセージ形式の検証

**判定条件**: コミットメッセージが R-1506 の形式に準拠しているか

**合否**:
- **PASS**: 形式準拠
- **WARN**: 形式不正（警告のみ、Failではない）

**判定方法**:
```bash
# 最新コミットメッセージを確認
(コマンド名 log) -1 --pretty=%B
# 種別（Add/Change/Fix/Remove）で始まるか確認
(コマンド名 log) -1 --pretty=%B | head -1 | grep -E "^(Add|Change|Fix|Remove):"
```

**ログ**: `evidence/verify_reports/V-1506_YYYYMMDD.md`

---

### V-1507: Revert後のFull Verify検証

**判定条件**: Revert実行後、Full Verify（Part10参照）がPASSしているか

**合否**:
- **PASS**: Full Verify がPASS
- **FAIL**: Full Verify が1つでもFAIL

**判定方法**:
```bash
# Revertコミットを検出
(コマンド名 log) --oneline --grep="Revert"
# Full Verify実行
pwsh .\checks\verify_repo.ps1 Full
```

**ログ**: `evidence/verify_reports/V-1507_YYYYMMDD.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-1501: VRループ失敗記録

**内容**: VRループ3回で解決しなかった場合の記録

**形式**:
```markdown
# VRループ失敗記録

- **日時**: 2026-01-10 15:30
- **Part**: Part15
- **失敗内容**: Fast Verify の V-0901（禁止コマンド検出）が3回ともFAIL
- **ループ履歴**:
  - Loop 1: V-0901 FAIL（理由: バッククオート忘れ）
  - Loop 2: V-0901 FAIL（理由: 全角スペース混入）
  - Loop 3: V-0901 FAIL（理由: 正規表現誤検出）
- **エスカレーション先**: HumanGate
- **承認者**: @approver_name
- **対応**: Verifyルールを一時的に緩和（ADR-0005追加）
```

**保存先**: `evidence/humangate/VR_LOOP_FAIL_20260110_153000.md`

---

### E-1502: HumanGate承認記録

**内容**: HumanGate操作の承認履歴

**形式**:
```markdown
# HumanGate承認記録

- **日時**: 2026-01-10 16:00
- **操作内容**: docs/ → documentation/ へのフォルダ名変更
- **理由**: 外部ツールとの命名規則統一
- **影響範囲**: 全Partのリンク切れ（約50箇所）
- **Dry-run結果**: 移行スクリプトで全リンク自動修正可能
- **承認者**: @approver_name
- **ロールバック計画**: Revert可能（履歴に残る）
- **実行結果**: PASS（Full Verify通過）
```

**保存先**: `evidence/humangate/PERMISSION_OVERRIDE_20260110_160000.md`

---

### E-1503: Revert記録

**内容**: コミット後のRevert履歴

**形式**:
```markdown
# Revert記録

- **日時**: 2026-01-10 17:00
- **対象コミット**: abc1234（Part15追加）
- **Revert理由**: Full Verifyで V-0001（リンク切れ）が発覚
- **Revertコミット**: def5678
- **Full Verify結果**: PASS（全リンク復旧）
- **再作成PR**: PR-456（修正済み）
```

**保存先**: `evidence/rollback_logs/REVERT_20260110_170000.md`

---

### E-1504: コミット修正記録

**内容**: コミット後の修正（amend等）履歴

**形式**:
```markdown
# コミット修正記録

- **日時**: 2026-01-10 18:00
- **対象コミット**: ghi9012（Part15追加）
- **修正理由**: CHANGELOG更新忘れ
- **修正内容**: CHANGELOG.mdを追加し amend
- **修正後コミット**: ghi9013
- **Verify結果**: PASS
```

**保存先**: `evidence/commit_fixes/CHANGELOG_FIX_20260110_180000.md`

---

### E-1505: 作業ログ

**内容**: Start→Work→Verify→Commit→PRの実行履歴

**形式**:
```markdown
# 作業ログ

- **Start**: 2026-01-10 14:00 - ブランチ feature/part15-execution-playbook 作成
- **Work**: 2026-01-10 14:30 - Part15.md作成完了
- **Verify**: 2026-01-10 15:00 - Fast Verify PASS
- **Commit**: 2026-01-10 15:30 - 4点証跡コミット（abc1234）
- **PR**: 2026-01-10 16:00 - PR-123作成
- **Merge**: 2026-01-10 17:00 - PR-123マージ完了
```

**保存先**: `WORK/work_log_20260110.txt`

---

## 10. チェックリスト

- [x] R-1501: Start→Work→Verify→Commit→PRの5ステップが定義されている
- [x] R-1502: VRループ3回制限が定義されている
- [x] R-1503: HumanGate必須操作が定義されている
- [x] R-1504: 4点証跡コミット運用が定義されている
- [x] R-1505: ブランチ命名規則が定義されている
- [x] R-1506: コミットメッセージ形式が定義されている
- [x] 手順1〜5が「人間がそのまま実行できる粒度」で記述されている
- [x] 例外処理1〜4が「失敗分岐・復旧・エスカレーション」を含む
- [x] V-1501〜V-1507が「判定条件・合否・ログ」を含む
- [x] E-1501〜E-1505が「形式・保存先」を含む
- [x] 全ルールに根拠（F-XXXX or Part番号）が明記されている
- [x] 禁止コマンドが文字列として出現していない（全て分割表記または全角化）

---

## 11. 未決事項（推測禁止）

（本Partは運用手順の明文化であり、未決事項なし）

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法（真実順序）
- [docs/Part09.md](Part09.md) : Permission Tier（HumanGate定義）
- [docs/Part10.md](Part10.md) : Verify Gate（Fast/Full Verify）
- [docs/Part11.md](Part11.md) : VRループ運用
- [docs/Part14.md](Part14.md) : 変更管理（PATCHSET/ADR/CHANGELOG）
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-0003, F-0031）

### checks/
- `checks/verify_repo.ps1` : Fast/Full Verify実行スクリプト

### evidence/
- `evidence/verify_reports/` : Verify実行結果
- `evidence/humangate/` : HumanGate承認記録
- `evidence/rollback_logs/` : Revert記録
- `evidence/commit_fixes/` : コミット修正記録

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義
