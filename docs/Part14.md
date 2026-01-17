# Part 14：変更管理（PATCHSET/RFC/ADR・例外ルート・互換/移行・凍結解除ルール）

## 0. このPartの位置づけ
- **目的**: SSOT更新の手順・承認フロー・バージョン管理・破壊的変更の扱いを統一し、矛盾蓄積を防ぐ
- **依存**: Part00（SSOT憲法・真実順序）、Part09（Permission Tier・承認フロー）、Part10（Verify Gate）
- **影響**: 全Part（変更時は必ず本Partの手順に従う）、Part12（Evidence）、Part13（Release）、Part17（Rollback）

## 1. 目的（Purpose）

VCG/VIBE 2026 設計書SSOTを運用するには、**誰が・何を・どの順序で変更してよいか** を明確にしなければ、すぐに矛盾が蓄積し、SSOTが破壊される。

本Partでは以下を達成する：

1. **変更の正当性**: 仕様変更の根拠がないまま docs/ を書き換えると、後から「なぜこうなったか」が追跡不能になる → **ADR先行ルール** で防止
2. **最小差分原則**: 複数の目的を混ぜた巨大PATCHは、失敗時の切り分けが困難 → **PATCHSET単位** で単一目的に限定
3. **バージョン管理**: 「いつ」「誰が」「何を」変更したかを追跡できなければ、ロールバック不能 → **CHANGELOG必須**
4. **破壊的変更の制御**: 互換性を破壊する変更は、移行手順・ロールバック計画なしに実施禁止 → **HumanGate承認**
5. **凍結解除の透明性**: Spec凍結前の実装禁止ルールに対し、例外承認の記録を残す

**根拠**: [F-0003](../docs/FACTS_LEDGER.md#F-0003), [ADR-0001](../decisions/0001-ssot-governance.md)

## 2. 適用範囲（Scope / Out of Scope）

### Scope（対象）
- docs/ 配下の全Part（Part00〜Part20）の変更
- glossary/ の用語追加・定義変更
- decisions/ への ADR 追加（変更承認記録）
- checks/ の検証スクリプト追加・修正
- 互換性を破壊する変更（フォルダ構造変更、ファイル名変更、API仕様変更）
- Spec凍結前の実装開始（例外承認が必要）

### Out of Scope（対象外）
- sources/ 配下のファイル（改変・削除禁止、Part00で固定）
- evidence/ 配下のログ・レポート（Append-only、削除は Part09 HumanGate）
- WORK/ 配下の作業ファイル（個人の裁量、VERIFYを通せば自由）
- コード実装の変更（本Partはドキュメント変更のみ、コードは別途 Part04 VIBEKANBAN）

**注意**: 上記Out of Scopeの変更は **別のルール** で管理される（Part00, Part05, Part09参照）。

## 3. 前提（Assumptions）

本Partは以下を前提とする：

1. **Git運用**: 本リポジトリはGit管理されており、ブランチ・PR・コミットログが利用可能
2. **ADR承認権限**: decisions/ への ADR 追加は **HumanGate** または **指定承認者** のみ可能（Part09で定義）
3. **Verify Gate通過**: 変更は必ず Part10 で定義された検証を通過してからマージ（通過しない変更はマージ禁止）
4. **PATCHSET最小単位**: 1つの変更は「1つの目的」に限定し、複数目的を混ぜない
5. **CHANGELOG維持**: 更新のたびに `CHANGELOG.md` を更新し、「いつ・誰が・何を」を記録
6. **CI強制**: main/integrate へのマージはCIでVerify PASSが必須

**根拠**: [F-0003](../docs/FACTS_LEDGER.md#F-0003), [ADR-0001](../decisions/0001-ssot-governance.md)

## 4. 用語（Glossary参照：Part02）

本Partで使用する用語：

- **PATCHSET**: 最小差分の変更単位。1つの目的（バグ修正/機能追加/用語統一）のみを含む
- **ADR (Architecture Decision Record)**: 意思決定記録。変更理由・選択肢・影響範囲を明記し、承認されてから docs/ へ反映
- **RFC (Request for Comments)**: 変更提案。ADRの前段階、議論中の提案（本プロジェクトではADRに統合）
- **CHANGELOG**: 変更履歴。YYYY-MM-DD 形式の日付、変更概要、担当者を記録
- **Spec Freeze**: 仕様凍結。Spec完成後、実装開始前に凍結宣言を行い、以降の仕様変更は例外承認必須
- **破壊的変更**: 既存の参照・フォルダ構造・API仕様を破壊する変更。移行手順・ロールバック計画が必須
- **HumanGate**: 人間の承認が必須の操作。破壊的変更・全域変更・リリース確定など（Part09で定義）

**参照**: [glossary/GLOSSARY.md](../glossary/GLOSSARY.md), [Part02](./Part02.md)

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-1401: PATCHSET最小単位【MUST】

**定義**: SSOTの更新は「PATCHSET」として作成し、以下の条件を満たす。

#### 条件
1. **単一目的**: 1つのPATCHSETは1つの目的（バグ修正/機能追加/用語統一/ADR追加）のみを含む
2. **最小差分**: 目的達成に必要な最小限の変更にとどめる（無関係な整理・リファクタリングを混ぜない）
3. **VERIFYを通過**: Part10 で定義された検証（Fast Verify最低限）を通過してからマージ
4. **失敗時の即座対応**: VERIFYが失敗した場合、即座にロールバックまたはRevert（放置禁止）

#### 禁止例
- ❌ バグ修正 + 用語統一 + フォルダ整理 を1つのPRに混ぜる
- ❌ 10ファイル同時変更で、うち3ファイルは無関係な整理
- ❌ VERIFYを通さずにマージ

**根拠**: [F-0003](../docs/FACTS_LEDGER.md#F-0003)
**Verify観点**: V-1401（後述）
**例外**: なし（全変更に適用）

---

### R-1402: ADR先行ルール【MUST】

**定義**: 仕様・運用を変更する場合、**必ず以下の順序** で実施する。

#### 手順
1. **decisions/** に ADR を追加（変更理由・選択肢・影響範囲を明記）
2. ADR が承認されたら、**docs/** の該当 Part を更新
3. **checks/** の検証手順を実行し、矛盾がないことを確認
4. **CHANGELOG.md** に変更履歴を記録

#### 違反例（禁止）
- ❌ ADR を書かずに docs/ を直接変更
- ❌ 変更理由を口頭・チャットだけで済ます
- ❌ 検証を省略して push
- ❌ CHANGELOG を更新せずにマージ

#### ADR免除条件（例外）
以下の変更は ADR 不要（軽微な変更）：
- 誤字脱字修正（用語定義に影響しない）
- コメント追加（ルールの追加・変更ではない）
- チェックリスト項目追加（ルール変更を伴わない）

**ただし、CHANGELOG への記録は必須**（軽微な変更でも記録する）。

**根拠**: [ADR-0001](../decisions/0001-ssot-governance.md#1-変更手順must)
**Verify観点**: V-1402（後述）
**例外**: 上記「ADR免除条件」のみ

---

### R-1403: CHANGELOG必須【MUST】

**定義**: 更新のたびに `CHANGELOG.md` を更新し、以下の形式で記録する。

#### 形式
```markdown
## YYYY-MM-DD

### 変更種別（Added / Changed / Fixed / Removed）
- **[Part番号]** 変更概要（1行、50文字以内）
  - 担当: @username または AI名（ChatGPT/Claude Code/Gemini）
  - ADR: decisions/0001-example.md（該当する場合）
  - Commit: abc1234
```

#### 例
```markdown
## 2026-01-10

### Added
- **[Part14]** 変更管理（PATCHSET/ADR/CHANGELOG）を追加
  - 担当: Claude Code
  - ADR: decisions/0001-ssot-governance.md
  - Commit: 0dd189d

### Fixed
- **[Part10]** Verify Gate の V-0901 でバッククオート内の禁止コマンドを除外
  - 担当: Claude Code
  - Commit: b375057
```

#### 変更種別の定義
- **Added**: 新規Part追加、新規ルール追加、新規用語追加
- **Changed**: 既存ルールの変更、手順の変更、用語定義の変更
- **Fixed**: バグ修正、誤字脱字修正、リンク切れ修正
- **Removed**: Part削除、ルール削除、非推奨化

**根拠**: [F-0003](../docs/FACTS_LEDGER.md#F-0003)
**Verify観点**: V-1403（後述）
**例外**: なし（全変更に適用）

---

### R-1404: 破壊的変更の制御【MUST】

**定義**: 既存の参照・フォルダ構造・API仕様を破壊する変更は、以下の条件を満たしてから実施する。

#### 破壊的変更の例
- Part番号変更（Part14 → Part15など、他Partからの参照が破壊される）
- フォルダ名変更（docs/ → documentation/ など、パス参照が破壊される）
- ファイル名変更（FACTS_LEDGER.md → LEDGER.md など、リンクが破壊される）
- 用語変更（PATCHSET → PATCH_SET など、grep検索が破壊される）
- API仕様変更（MCP ReadOnly → WriteAll など、互換性が破壊される）

#### 実施条件【MUST】
1. **ADR必須**: decisions/ に破壊的変更の ADR を追加（移行手順・ロールバック計画を含む）
2. **HumanGate承認**: Part09 で定義された承認フローを通過
3. **移行手順明記**: 既存の参照を全て洗い出し、移行スクリプト or 手動手順を用意
4. **Dry-run実施**: 本番適用前に、テスト環境で移行を実行し、失敗がゼロであることを確認
5. **ロールバック計画**: 失敗時の復旧手順（git revert / バックアップ復元）を事前に用意
6. **Full Verify通過**: Part10 の Full Verify（7カテゴリ、<30分）を通過

**根拠**: [F-0002](../docs/FACTS_LEDGER.md#F-0002), [F-0031](../docs/FACTS_LEDGER.md#F-0031), [Part09](./Part09.md)
**Verify観点**: V-1404（後述）
**例外**: なし（全破壊的変更に適用）

---

### R-1405: Spec凍結前の実装禁止【MUST】

**定義**: Specが凍結されるまでBuildしない（仕様が流動的なまま実装すると、手戻りで事故率が急上昇）。

#### 凍結宣言の条件
1. **Acceptance（受入条件）が機械判定可能**: Part10 の Verify 観点で判定可能な形式
2. **未決事項ゼロ**: 「未決事項」セクションが空、または「未決でも実装可能」と明記
3. **ADR承認**: Spec凍結の ADR が承認済み

#### 例外承認（Spec凍結前に実装開始が許可されるケース）
1. **SPIKE（調査用スパイク）**: 実装可能性を調査するための試作。以下の条件を満たす：
   - 隔離環境（WORK/SPIKE/）で実施
   - 成果は「仕様へ移すまで本流に混ぜない」
   - SPIKE完了後、Specに反映してから本流実装
2. **Proof of Concept（PoC）**: 技術検証。SPIKE同様に隔離し、成果をSpecへ反映
3. **緊急修正（Hotfix）**: 本番障害の緊急対応。以下の条件を満たす：
   - HumanGate承認（Part09）
   - 事後にSpecへ反映（ADR追加）

**根拠**: [F-0002](../docs/FACTS_LEDGER.md#F-0002), [F-0032](../docs/FACTS_LEDGER.md#F-0032)
**Verify観点**: V-1405（後述）
**例外**: 上記「例外承認」のみ（ADR必須）

---

### R-1406: バージョン番号ルール【SHOULD】

**定義**: リリース時のバージョン番号は YYYY-MM-DD 形式を推奨（セマンティックバージョニングは任意）。

#### 形式
- **推奨**: `RELEASE_20260110_153000`（タイムスタンプ形式）
- **任意**: `v1.2.3`（セマンティックバージョニング、運用判断）

#### 理由
- タイムスタンプ形式は「いつリリースされたか」が一目瞭然
- セマンティックバージョニング（Major.Minor.Patch）は、互換性の判定には有用だが、「いつ」が不明
- **両方併記も可**（例: `v1.2.3 (RELEASE_20260110)`）

**根拠**: [F-0003](../docs/FACTS_LEDGER.md#F-0003), [F-0006](../docs/FACTS_LEDGER.md#F-0006)
**Verify観点**: V-1406（後述）
**例外**: プロジェクト方針でセマンティックバージョニング採用の場合はADRで明記

---

### R-1407: CIによるVerify強制【MUST】

**定義**: main/integrate へのマージは CI で Verify Gate が PASS した場合のみ許可する。

#### 条件
1. **Required Status Checks** に Verify Fast を登録
2. **main へのマージ**は Verify Full も PASS していること
3. **CIログの参照**を evidence/ に記録する（参照パスのみで可）

**根拠**: [Part10](./Part10.md)
**Verify観点**: V-1410（後述）
**例外**: HumanGate 承認（緊急対応のみ）

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順1: PATCHSET作成（docs/ 変更時）

以下の手順で最小差分の変更を作成する。

1. **ブランチ作成**
   ```powershell
   git checkout -b feature/fix-part14-typo
   ```

2. **変更実施**（1つの目的のみ）
   - 例: Part14 の誤字修正のみ
   - 禁止: 誤字修正 + 用語統一 を混ぜる

3. **Fast Verify実行**（Part10参照）
   ```powershell
   pwsh .\checks\verify_repo.ps1 -Mode Fast
   ```

4. **失敗時は即座修正**（3ループ以内、Part10参照）
   - 修正 → Verify → 修正 → Verify → ...
   - 3ループで解決しなければ HumanGate（Part09参照）

5. **CHANGELOG更新**
   ```markdown
   ## 2026-01-10
   ### Fixed
   - **[Part14]** 誤字修正（PATCHSET → PatchSet の表記揺れ）
     - 担当: Claude Code
     - Commit: abc1234
   ```

6. **コミット**
   ```powershell
   git add docs/Part14.md CHANGELOG.md
   git commit -m "Fix: Part14 誤字修正（PATCHSET表記統一）"
   ```

7. **PR作成 & マージ**
   - PRテンプレートに「Verify結果」を添付
   - レビュー承認後、マージ

---

### 手順2: ADR追加（仕様変更時）

仕様・運用を変更する場合、以下の手順で ADR を先行追加する。

1. **decisions/ADR_TEMPLATE.md をコピー**
   ```powershell
   cp decisions/ADR_TEMPLATE.md decisions/0002-change-patchset-format.md
   ```

2. **ADR記入**（以下のセクションを必ず埋める）
   - **背景**: なぜ変更が必要か（現状の問題）
   - **決定**: 何をどう変更するか（選択肢A/B/Cと採用理由）
   - **影響範囲**: どのPartに影響するか、互換/移行の扱い
   - **実行計画**: 手順・ロールバック・検証観点

3. **承認依頼**
   - HumanGate または 指定承認者 にレビュー依頼
   - 承認されるまで docs/ は変更しない

4. **ADR承認後、docs/ 更新**
   - ADRで決定した内容を該当Partへ反映
   - CHANGELOGに記録

5. **Verify実行**
   ```powershell
   pwsh .\checks\verify_repo.ps1 -Mode Fast
   ```

6. **コミット & PR**
   ```powershell
   git add decisions/0002-*.md docs/Part*.md CHANGELOG.md
   git commit -m "Add: ADR-0002（PATCHSET形式変更）& Part14更新"
   ```

---

### 手順3: 破壊的変更の実施（フォルダ名変更など）

既存の参照を破壊する変更は、以下の手順で慎重に実施する。

1. **ADR作成**（手順2参照）
   - 「背景」に「なぜ破壊が必要か」を明記
   - 「影響範囲」に「全リンク切れ箇所」を列挙
   - 「実行計画」に「移行手順」「ロールバック」を明記

2. **HumanGate承認**（Part09参照）
   - ADRを承認者に提出
   - 承認されるまで実施禁止

3. **Dry-run（テスト環境）**
   ```powershell
   # 例: docs/ → documentation/ へ変更
   git checkout -b test/rename-docs
   git mv docs documentation
   # 全リンク更新スクリプト実行（適宜 PowerShell 版を作成または使用）
   # pwsh .\scripts\update_links.ps1 docs documentation
   # Verify実行
   pwsh .\checks\verify_repo.ps1 -Mode Fast
   ```

4. **Dry-run成功を確認**
   - VERIFYが全て [PASS]
   - リンク切れゼロ

5. **本番実施**
   ```powershell
   git checkout -b feature/rename-docs
   git mv docs documentation
   # pwsh .\scripts\update_links.ps1 docs documentation
   git add .
   git commit -m "Breaking: docs/ → documentation/ へ変更（ADR-0003）"
   ```

6. **Full Verify実行**（Part10参照）
   ```powershell
   pwsh .\checks\verify_repo.ps1 -Mode Full
   ```

7. **ロールバック計画確認**
   - git revert可能であることを確認
   - バックアップがあることを確認

8. **PR & マージ**
   - PRに「破壊的変更」ラベル付与
   - ADRリンク、Verify結果、ロールバック手順を添付

---

### 手順4: Spec凍結宣言（実装開始前）

Specが完成したら、以下の手順で凍結を宣言する。

1. **未決事項ゼロ確認**
   - 該当Partの「11. 未決事項」セクションが空
   - または「未決でも実装可能」と明記

2. **Acceptance（受入条件）確認**
   - Part10 の Verify 観点で機械判定可能
   - 手動判定が必要な場合は「判定手順」を明記

3. **ADR作成**
   ```markdown
   # ADR-0004: Part14 Spec凍結宣言

   ## 決定
   Part14（変更管理）のSpecを凍結し、実装開始を許可する。

   ## 受入条件
   - V-1401〜V-1406 が全てPASS
   - CHANGELOGが更新されている
   - ADR先行ルールが守られている
   ```

4. **凍結マーク追加**（該当Partのヘッダに追記）
   ```markdown
   # Part 14：変更管理（PATCHSET/RFC/ADR）

   **Status**: Spec Freeze（2026-01-10）
   **ADR**: decisions/0004-part14-spec-freeze.md
   ```

5. **実装開始許可**
   - 凍結後は「仕様変更は例外承認必須」
   - 実装中に仕様変更が必要な場合はADR追加

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: VERIFYが3ループで解決しない

**状態**: Part10 の VRループで3回修正しても VERIFY が PASS しない

**対応**:
1. **HumanGateへエスカレーション**（Part09参照）
   - 失敗ログ、修正履歴、現状をまとめて提出
2. **承認者判断**:
   - A) 一時的に VERIFY を緩和（ADR追加）
   - B) 変更を中止（Revert）
   - C) 追加調査（SPIKE扱い）

**Verify観点**: V-1407（後述）
**Evidence**: E-1401（VRループ失敗ログ）

---

### 例外2: 緊急Hotfix（Spec凍結前の実装）

**状態**: 本番障害で緊急修正が必要、Spec凍結前だが実装開始せざるを得ない

**対応**:
1. **HumanGate承認**（Part09参照）
   - 障害内容、影響範囲、修正方針を提出
2. **Hotfixブランチ作成**
   ```powershell
   git checkout -b hotfix/critical-bug-20260110
   ```
3. **最小限の修正**（追加機能を混ぜない）
4. **Fast Verify実行**（可能な範囲）
5. **マージ後、Specへ反映**
   - ADR追加（事後承認）
   - Specに「Hotfix履歴」セクション追加

**Verify観点**: V-1408（後述）
**Evidence**: E-1402（Hotfix承認記録）

---

### 例外3: 破壊的変更のロールバック

**状態**: 破壊的変更をマージ後、予期しない副作用が発生

**対応**:
1. **即座にRevert**
   ```bash
   git revert abc1234
   git push origin main
   ```
2. **Full Verify実行**（Revert後の整合性確認）
3. **事後報告**
   - ADRに「ロールバック実施」セクション追加
   - 失敗原因、対策を記録

**Verify観点**: V-1409（後述）
**Evidence**: E-1403（ロールバック記録）

---

### 例外4: ADR免除の濫用

**状態**: 「軽微な変更」を理由に ADR を省略しているが、実際はルール変更を含む

**検知方法**:
- Verify時に「CHANGELOG にあるが ADR がない変更」を検出
- 「Changed」種別なのに ADR リンクがない

**対応**:
1. **Verify失敗**（V-1402）
2. **修正指示**: ADR を事後追加、またはCHANGELOGを「Fixed」に訂正
3. **繰り返す場合**: Permission降格（Part09参照、PatchOnly → ReadOnly）

**Verify観点**: V-1402（後述）
**Evidence**: E-1404（ADR免除濫用記録）

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-1401: PATCHSET最小単位の検証

**判定条件**:
1. 1つのPRに含まれる変更が「単一目的」であること
2. 無関係なファイル変更が混入していないこと

**合否**:
- **PASS**: 変更が1つの目的（バグ修正/機能追加/用語統一）のみ
- **FAIL**: 複数目的が混在（例: バグ修正 + 用語統一 + フォルダ整理）

**判定方法**:
```bash
# PRのdiffを目視確認（自動化は困難、レビュー時に判定）
git diff main...feature/fix-part14
```

**ログ**: evidence/verify_reports/V-1401_YYYYMMDD.md

---

### V-1402: ADR先行ルールの検証

**判定条件**:
1. docs/ の変更を含むPRに、対応するADRが存在すること
2. ADRの承認日が、docs/ 変更コミット日より前であること

**合否**:
- **PASS**: ADR が decisions/ に存在し、承認済み
- **FAIL**: ADR なしで docs/ を直接変更

**判定方法**:
```bash
# CHANGELOGの「Changed」エントリに ADR リンクがあるか確認
grep -E "^### Changed" CHANGELOG.md -A 5 | grep "ADR:"
```

**ログ**: evidence/verify_reports/V-1402_YYYYMMDD.md

**例外**: 軽微な変更（誤字脱字、コメント追加）はADR免除

---

### V-1403: CHANGELOG更新の検証

**判定条件**:
1. docs/ を変更するPRに、CHANGELOG.md の更新が含まれること
2. CHANGELOG の形式が正しい（日付、種別、Part番号、担当、Commit）

**合否**:
- **PASS**: CHANGELOG が更新され、形式が正しい
- **FAIL**: CHANGELOG が未更新、または形式不正

**判定方法**:
```bash
# 最新コミットにCHANGELOG.mdが含まれるか確認
git diff HEAD~1 --name-only | grep CHANGELOG.md
```

**ログ**: evidence/verify_reports/V-1403_YYYYMMDD.md

---

### V-1404: 破壊的変更の検証

**判定条件**:
1. フォルダ名変更、ファイル名変更、Part番号変更が含まれる場合、ADR必須
2. ADRに「移行手順」「ロールバック計画」が明記されていること
3. Dry-runの実行ログが evidence/ に保存されていること

**合否**:
- **PASS**: 上記3条件を全て満たす
- **FAIL**: 1つでも満たさない

**判定方法**:
```bash
# git mv または rm の履歴を検出
git log --oneline --name-status | grep -E "^(R|D)"
# ADRに「移行手順」セクションがあるか確認
grep "移行手順" decisions/0003-*.md
```

**ログ**: evidence/verify_reports/V-1404_YYYYMMDD.md

---

### V-1405: Spec凍結前の実装禁止の検証

**判定条件**:
1. 「Status: Spec Freeze」マークがないPartに対し、実装PRが作成されていないこと
2. SPIKE/PoC/Hotfix の場合、ADRに例外承認が記録されていること

**合否**:
- **PASS**: 凍結済みPartのみ実装、または例外承認あり
- **FAIL**: 未凍結Partに対し実装PR作成

**判定方法**:
```bash
# Partファイルに「Status: Spec Freeze」があるか確認
grep "Status: Spec Freeze" docs/Part14.md
# なければ実装PRの存在をチェック
git log --oneline --grep="Impl:" | grep Part14
**ログ**: evidence/verify_reports/V-1405_YYYYMMDD.md

---

### V-1406: バージョン番号形式の検証

**判定条件**:
1. RELEASE/ 配下のフォルダ名が `RELEASE_YYYYMMDD_HHMMSS` 形式であること

**合否**:
- **PASS**: 形式が正しい
- **FAIL**: 形式が不正（例: `RELEASE_v1.2.3`）

**判定方法**:
```powershell
# RELEASE/配下のフォルダ名を確認
ls -d RELEASE/RELEASE_* | grep -E "RELEASE_[0-9]{8}_[0-9]{6}"
```

**ログ**: evidence/verify_reports/YYYYMMDD_HHMMSS_sources_integrity.md（フォルダ名整合性として）

---

### V-1407: VRループ3回制限の検証

**判定条件**:
1. 同一変更に対し、VERIFY失敗 → 修正 → VERIFY のループが3回以内であること

**合否**:
- **PASS**: 3回以内で解決
- **FAIL**: 3回超えても [PASS] しない → HumanGateへエスカレーション

**判定方法**:
```powershell
# evidence/ のレポート数を確認
ls evidence/verify_reports/ | Measure-Object
```

**ログ**: evidence/verify_reports/YYYYMMDD_HHMMSS_*.md（複数回実行の証跡）

---

### V-1408: Hotfix事後承認の検証

**判定条件**:
1. Hotfixブランチのマージ後、7日以内にADRが追加されていること

**合否**:
- **PASS**: 7日以内にADR追加
- **FAIL**: 7日経過してもADR未追加

**判定方法**:
```powershell
# hotfix/ ブランチのマージ日を確認
git log --merges --oneline --grep="hotfix/"
# 7日以内のADR追加を確認
Get-ChildItem decisions/ -Filter "*.md" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }
```

**ログ**: evidence/verify_reports/V-1408_YYYYMMDD.md

---

### V-1409: ロールバック記録の検証

**判定条件**:
1. git revert が実行された場合、ADRに「ロールバック実施」セクションが追加されていること

**合否**:
- **PASS**: ロールバック記録がADRに存在
- **FAIL**: revert実行後、ADR未更新

**判定方法**:
```powershell
# git revert のコミットを検出
git log --oneline --grep="Revert"
# ADRに「ロールバック」セクションがあるか確認
Select-String "ロールバック" decisions/*.md
```

**ログ**: evidence/verify_reports/V-1409_YYYYMMDD.md

---

### V-1410: CI強制の検証

**判定条件**:
1. Required Status Checks に `verify-gate-windows` が登録されていること
2. main/integrate へのPRのChecksに `verify-gate-windows` が表示され、PASSであること

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: CI結果未付与、または [FAIL]

**判定方法**:
- GitHub Branch Protection / Rulesets で Required checks を確認
- PRのChecksタブで `verify-gate-windows` の [PASS] を確認
- 参照URLを evidence/verify_reports/V-1410_YYYYMMDD.md に記録

**ログ**: evidence/verify_reports/V-1410_YYYYMMDD.md

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-1401: VRループ失敗ログ

**内容**: VERIFY失敗 → 修正 → VERIFY のループ履歴

**形式**:
```json
{
  "pr_id": "PR-123",
  "loop_count": 3,
  "failures": [
    {"loop": 1, "verify_id": "V-1403", "reason": "CHANGELOG未更新"},
    {"loop": 2, "verify_id": "V-1403", "reason": "日付形式不正"},
    {"loop": 3, "verify_id": "V-1403", "reason": "PASS"}
  ],
  "escalation": false
}
```

**保存先**: evidence/verify_reports/VR_LOOP_20260110_PR123.json

---

### E-1402: Hotfix承認記録

**内容**: 緊急修正の承認履歴

**形式**:
```markdown
# Hotfix承認記録

- **日時**: 2026-01-10 15:30
- **承認者**: @approver_name
- **障害内容**: 本番環境でPart10のVerify Gateが無限ループ
- **修正方針**: V-0901のバッククオート除外ロジック追加
- **影響範囲**: Part10のみ、他Partへの影響なし
- **事後ADR**: decisions/0005-hotfix-verify-gate.md（7日以内追加予定）
```

**保存先**: evidence/hotfix_approvals/HOTFIX_20260110_153000.md

---

### E-1403: ロールバック記録

**内容**: 破壊的変更のロールバック履歴

**形式**:
```markdown
# ロールバック記録

- **日時**: 2026-01-10 18:00
- **対象変更**: docs/ → documentation/ へのフォルダ名変更（Commit: abc1234）
- **ロールバック理由**: 外部ツールの参照が全てdocs/前提で、移行スクリプト漏れ
- **Revertコミット**: def5678
- **Full Verify結果**: PASS（全リンク復旧）
- **対策**: 次回は外部ツール依存を事前調査
```

**保存先**: evidence/rollback_logs/ROLLBACK_20260110_180000.md

---

### E-1404: ADR免除濫用記録

**内容**: ADR免除ルールの不正利用履歴

**形式**:
```markdown
# ADR免除濫用記録

- **日時**: 2026-01-10 20:00
- **PR**: PR-456
- **問題**: 「誤字修正」として免除を主張したが、実際はルール変更（R-1401の条件追加）
- **検知方法**: V-1402でCHANGELOGの種別が「Changed」だがADRリンクなし
- **対応**: PR差し戻し、ADR追加を指示
- **再発防止**: Permission降格（PatchOnly → ReadOnly）を検討
```

**保存先**: evidence/adr_abuse_logs/ADR_ABUSE_20260110_200000.md

---

### E-1405: Spec凍結宣言

**内容**: Specが凍結され、実装開始が許可された記録

**形式**:
```markdown
# Spec凍結宣言

- **Part**: Part14（変更管理）
- **凍結日**: 2026-01-10
- **ADR**: decisions/0004-part14-spec-freeze.md
- **未決事項**: ゼロ
- **Acceptance**: V-1401〜V-1410 が全てPASS
- **実装開始許可**: 承認済み
```

**保存先**: evidence/spec_freeze/SPEC_FREEZE_Part14_20260110.md

---

### E-1406: CI強制ログ

**内容**: CIでVerify GateがPASSした参照情報

**形式**:
```markdown
# CI Verify Gate ログ

- **PR**: PR-123
- **Verify**: Fast PASS / Full PASS
- **CI Run URL**: https://github.com/ORG/REPO/actions/runs/123456
- **対象ブランチ**: integrate / main
```

**保存先**: evidence/verify_reports/CI_VERIFY_20260110_PR123.md

---

## 10. チェックリスト

- [x] R-1401: PATCHSET最小単位が定義され、違反例が明記されている
- [x] R-1402: ADR先行ルールが定義され、免除条件が明記されている
- [x] R-1403: CHANGELOG必須が定義され、形式が明記されている
- [x] R-1404: 破壊的変更の制御が定義され、実施条件が明記されている
- [x] R-1405: Spec凍結前の実装禁止が定義され、例外承認が明記されている
- [x] R-1406: バージョン番号ルールが定義されている
- [x] R-1407: CIによるVerify強制が定義されている
- [x] 手順1〜4が「人間がそのまま実行できる粒度」で記述されている
- [x] 例外処理1〜4が「失敗分岐・復旧・エスカレーション」を含む
- [x] V-1401〜V-1410が「判定条件・合否・ログ」を含む
- [x] E-1401〜E-1406が「形式・保存先」を含む
- [x] 全ルールに根拠（F-XXXX or ADR-XXXX）が明記されている

## 11. 未決事項（推測禁止）

### U-1403: CHANGELOG の集約
**問題**: CHANGELOG.md が長大化した場合、過去ログをアーカイブするか未定義

**影響**: 1ファイルが数千行になり、検索・編集が困難

**対応**: 年単位でアーカイブ（CHANGELOG_2026.md）する案をADRで検討

---

### U-1404: セマンティックバージョニング
**問題**: バージョン番号にセマンティックバージョニング（v1.2.3）を採用するか、タイムスタンプ（YYYYMMDD）を採用するか、プロジェクト方針が未定義

**影響**: リリースごとに表記が揺れる

**対応**: ADRで方針統一（R-1406では「推奨」にとどめた）

---

## 12. 参照（パス）

### docs/
- [Part00](./Part00.md) : SSOT憲法（真実順序、ADR→docs workflow）
- [Part02](./Part02.md) : 用語管理（GLOSSARY統一）
- [Part09](./Part09.md) : Permission Tier（HumanGate承認フロー）
- [Part10](./Part10.md) : Verify Gate（Fast/Full、VRループ）
- [Part12](./Part12.md) : Evidence管理（ログ保存形式）
- [Part13](./Part13.md) : Release Package（不変リリース）
- [Part17](./Part17.md) : Rollback（復旧手順）
- [FACTS_LEDGER.md](./FACTS_LEDGER.md) : F-0002, F-0003, F-0006, F-0031, F-0032

### sources/
- （なし: 本Partは主にADR-0001を根拠とする）

### evidence/
- evidence/verify_reports/ : V-1401〜V-1410のログ
- evidence/hotfix_approvals/ : E-1402（Hotfix承認記録）
- evidence/rollback_logs/ : E-1403（ロールバック記録）
- evidence/adr_abuse_logs/ : E-1404（ADR免除濫用記録）
- evidence/spec_freeze/ : E-1405（Spec凍結宣言）

### decisions/
- [ADR-0001](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス（変更手順・根拠・検証の統治）
- [ADR_TEMPLATE.md](../decisions/ADR_TEMPLATE.md) : ADRの書き方
- [ADR-0004](../decisions/0004-humangate-approvers.md) : HumanGate承認者・SLA
