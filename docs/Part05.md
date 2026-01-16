# Part 05：Core4運用（Claude/GPT/Gemini/Z.ai等の役割固定・衝突裁定・エスカレーション）

## 0. このPartの位置づけ
- 目的：Core4の役割固定と衝突裁定を運用手順として固定し、SSOTの整合性を守る
- 依存：Part00（SSOT憲法）、Part03（AI Pack）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：AI運用の責任分界、作業境界、証跡と監査の整合

## 1. 目的（Purpose）
Core4の役割・権限・衝突裁定・エスカレーションを明文化し、  
作業が運用ループとVerify/Evidenceに整合するよう統一する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- Core4（Claude/GPT/Gemini/Z.ai）の役割運用と裁定手順
- 役割衝突時の記録・修正・検証・監査
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- 個別AIのプロンプト設計の詳細（別Part）
- 組織固有の承認者の人事規定

## 3. 前提（Assumptions）
1. Core4の役割定義は Part03 に従う
2. Permission Tierは Part09 に従う
3. Verify/Evidenceは Part00/Part10/Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Core4**: 4つの課金AIの役割固定
- **衝突裁定**: 役割の衝突や判断差を解消する手続き
- **エスカレーション**: HumanGateへの承認要求

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-0501: 役割固定の遵守【MUST】
Core4の役割は Part03 の定義に従い、越境を行わない。

### R-0502: 衝突裁定の記録【MUST】
判断差が出た場合は発見・記録・修正・検証・監査の順で裁定する。

### R-0503: Permission Tierの順守【MUST】
権限外の操作は行わず、必要ならHumanGateで承認を得る。

### R-0504: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-0505: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-0506: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：役割衝突や判断差を特定し、影響範囲と参照根拠を確認する。
2. 記録：発見内容、根拠、対象ファイル、作業メモの保存先を記録する。
3. 修正：最小差分で裁定内容を反映し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、裁定結果を確定する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 役割衝突が解消できない
- HumanGateで裁定者を指定し、決定理由を記録する。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-0501: 役割裁定の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-0502: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-0501: 裁定記録
**内容**: 判断差、裁定理由、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-0502: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### 9.3 証跡4点（最小セット）
**内容**: link_check / parts_integrity / forbidden_patterns / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] 役割裁定と参照根拠が記録されている

## 11. 未決事項（推測禁止）
- 未決事項なし（現時点）

## 12. 参照（パス）
- docs/
- sources/
- evidence/
- decisions/
### docs/
- [Part00](./Part00.md) : SSOT憲法
- [Part02](./Part02.md) : 用語・表記
- [Part03](./Part03.md) : AI Pack / Core4
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
