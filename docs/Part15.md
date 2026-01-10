# Part 15：Playbook（品質・安全の運用手順）

## 0. このPartの位置づけ
- **目的**: 品質/安全の実務運用を「迷わず実行できる手順」に落とし込み、Verify・監査と連動させる
- **依存**: Part00（SSOT憲法・真実順序）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）
- **影響**: 全Part（運用時の標準手順として参照）、Part17（Rollback）

## 1. 目的（Purpose）

品質・安全に関する判断を属人化させず、**誰が実行しても同じ結果になるPlaybook**を提供する。  
Playbookは「発見 → 記録 → 修正 → 検証 → 監査」のループを標準化し、SSOTの整合性を維持する。

## 2. 適用範囲（Scope / Out of Scope）

### Scope（対象）
- docs/ の品質・安全に関する運用手順
- Verify Gateの実行・結果記録
- 例外発生時のエスカレーションと記録

### Out of Scope（対象外）
- sources/ の変更（禁止、Part00に従う）
- 実装コードの詳細手順（別途 Part04/Part05）
- 組織固有の人事評価や裁量権（本Partでは規定しない）

## 3. 前提（Assumptions）

1. **直近変更の確定ログが存在**する（本Part作成の起点）
2. **Verify Fast/Full の定義**は Part10 に準拠する
3. **Evidenceの保存先/形式**は Part12 に準拠する
4. **変更管理ルール**は Part14 に準拠する

## 4. 用語（Glossary参照：Part02）

- **Playbook**: 具体的な手順と分岐を含む運用指針（誰でも実行可能）
- **運用ループ**: 発見 → 記録 → 修正 → 検証 → 監査 の反復
- **Fast Verify**: 最小限の検証（Part10参照）
- **Full Verify**: 全検証（Part10参照）

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-1501: Playbook遵守【MUST】

**定義**: 品質・安全に関する作業は本PartのPlaybookに従う。

**理由**: 手順の逸脱はSSOTの矛盾と監査不整合を生む。

**根拠**: [F-0003](../docs/FACTS_LEDGER.md#F-0003), [Part10](./Part10.md)

---

### R-1502: 運用ループの記録【MUST】

**定義**: すべての修正は「発見 → 記録 → 修正 → 検証 → 監査」の順序で実施し、Evidenceに残す。

**必須記録**:
1. 発見内容（何が不具合か）
2. 修正内容（どこをどう直したか）
3. Verify結果（PASS/FAIL）
4. Evidenceの保存先

**根拠**: [Part12](./Part12.md), [Part14](./Part14.md)

---

### R-1503: 例外時のHumanGate【MUST】

**定義**: 3回のVRループで解決できない場合はHumanGateへ即時エスカレーションする。

**根拠**: [Part09](./Part09.md), [Part10](./Part10.md)

---

### R-1504: Playbook更新はADR先行【MUST】

**定義**: Playbookの手順や基準を変更する場合、ADRを先行追加する。

**根拠**: [ADR-0001](../decisions/0001-ssot-governance.md), [Part14](./Part14.md)

---

### R-1505: 最小差分の修正【SHOULD】

**定義**: 修正は最小差分で行い、無関係な整理を混在させない。

**根拠**: [Part14](./Part14.md)

## 6. 手順（実行可能な粒度、番号付き）

### 手順1: 問題の発見と記録

1. 問題を特定する（ログ、Verifyレポート、レビュー指摘）。
2. 影響範囲を確認する（該当Part・リンク・証跡）。
3. Evidenceの保存先を決める（Part12の形式に従う）。

### 手順2: 修正の実施

1. 修正対象ファイルを明確化する。
2. **最小差分**で修正する（無関係な変更を含めない）。
3. 修正理由と変更点を簡潔にメモする。

### 手順3: Verify実行

1. `pwsh .\checks\verify_repo.ps1 -Mode Fast` を実行する。
2. FAILの場合は修正に戻る（最大3ループ）。
3. PASSしたら証跡を確認する。

### 手順4: 証跡の整理

1. PASS証跡のみをコミット対象にする。
2. FAIL証跡はコミットしない（保管のみ）。
3. Evidence一覧を作業報告に反映する。

### 手順5: 監査と共有

1. 変更概要とVerify結果を作業報告にまとめる。
2. 必要に応じてHumanGate承認者へ提出する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: Verifyが3ループで通らない

**対応**:
1. HumanGateへエスカレーション（Part09）。
2. 失敗ログと修正履歴を提出。

### 例外2: 変更対象が複数にまたがる

**対応**:
1. 変更を分割し、PATCHSET単位で処理（Part14）。
2. どうしても分割できない場合はADRで理由を明記。

### 例外3: Evidenceが欠落している

**対応**:
1. 直近のVerifyを再実行してEvidenceを補完。
2. 再実行できない場合は理由と代替証跡を記録。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-1501: Playbook遵守の確認

**判定条件**:
1. 作業報告に「発見→修正→検証→証跡」が記載されている
2. PASS証跡のみがコミット対象になっている

**合否**:
- **PASS**: 上記を満たす
- **FAIL**: 作業報告欠落、FAIL証跡がコミット対象

**判定方法**:
```bash
# 作業報告とコミット対象を目視確認
git diff --name-only --cached
```

**ログ**: evidence/verify_reports/V-1501_YYYYMMDD.md

---

### V-1502: Verify実行の確認

**判定条件**:
1. Fast Verifyの実行ログが evidence/verify_reports/ に存在する

**合否**:
- **PASS**: 実行ログが存在
- **FAIL**: ログが存在しない

**判定方法**:
```bash
# 最新のverify_reportsを確認
ls evidence/verify_reports | tail -n 5
```

**ログ**: evidence/verify_reports/V-1502_YYYYMMDD.md

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-1501: 作業報告

**内容**: 変更概要、変更点、Verify結果、証跡一覧、次の一手

**保存先**: decisions/ または evidence/（運用ルールに従う）

---

### E-1502: Verify証跡（PASSのみ）

**内容**: Fast VerifyのPASSログ

**保存先**: evidence/verify_reports/

## 10. チェックリスト

- [ ] 作業対象・変更点が明確になっている
- [ ] Fast Verify を実行し、PASSを確認した
- [ ] PASS証跡のみがコミット対象になっている

## 11. 未決事項（推測禁止）

### U-1501: 作業報告の保存先統一
**問題**: 作業報告を decisions/ と evidence/ のどちらに保存するか未定義  
**影響**: 場所が統一されず監査が困難  
**対応**: Part12 に「作業報告の保存先」を追記するADRを検討

## 12. 参照（パス）

### docs/
- [Part00](./Part00.md) : SSOT憲法（真実順序）
- [Part09](./Part09.md) : Permission Tier（HumanGate）
- [Part10](./Part10.md) : Verify Gate（Fast/Full）
- [Part12](./Part12.md) : Evidence管理
- [Part14](./Part14.md) : 変更管理（PATCHSET/ADR）
- [Part17](./Part17.md) : Rollback
- [FACTS_LEDGER.md](./FACTS_LEDGER.md) : F-0003

### sources/
- （なし）

### evidence/
- evidence/verify_reports/

### decisions/
- [ADR-0001](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス
