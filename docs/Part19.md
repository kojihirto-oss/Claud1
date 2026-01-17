# Part 19：Incident/監査/改善サイクル（Stop-the-line・再発防止・ルール改訂SOP）

## 0. このPartの位置づけ
- 目的：Incident/監査/改善サイクルを固定し、再発防止とルール改訂を安全に回す
- 依存：Part00（SSOT憲法）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：運用停止判断、改善ループ、監査証跡の整合

## 1. 目的（Purpose）
Incident発生時のStop-the-line、監査、改善、ルール改訂を標準化し、  
再発防止とSSOT整合を維持する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- Incident対応（Stop-the-line）
- 監査の実施と証跡保存
- 改善策の立案とルール改訂
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- 実装コードの詳細手順（別Part）
- 組織固有の人事評価・懲戒規定

## 3. 前提（Assumptions）
1. SSOTは docs/ に固定される
2. Permission Tierは Part09 に従う
3. Verify/Evidenceは Part00/Part10/Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Incident**: 事故・重大不整合・運用停止が必要な事象
- **Stop-the-line**: 作業停止と原因究明の優先宣言
- **監査**: 証跡の確認と遵守状況の検証
- **改善サイクル**: 再発防止の手順（記録→修正→検証→監査）

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1901: Stop-the-lineの発動【MUST】
重大な不整合や汚染疑いが出た場合は作業を停止し、原因究明を優先する。

### R-1902: Incident記録の保存【MUST】
Incidentの内容・影響範囲・対応履歴をEvidenceに保存する。

### R-1903: ルール改訂はADR先行【MUST】
再発防止のためのルール改訂はADRを先行し、Part14に従う。

### R-1904: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-1905: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-1906: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：Incidentの兆候・影響範囲・参照根拠を確認する。
2. 記録：Incident内容、根拠、対象ファイル、保存先を記録する。
3. 修正：最小差分で対策を反映し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）を保存する。
5. 監査：対応概要・参照パス・証跡一覧・DoDを点検し、再発防止策を確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: Incidentの影響が広範
- 変更を分割し、対象範囲を切り分けて再検証する。

### 例外4: 再発が継続
- ADRでルール改訂を提案し、承認後に再対応する。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1901: Incident対応の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-1902: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1901: Incident記録
**内容**: 影響範囲、対応内容、参照根拠、再発防止策  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-1902: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-1903: 証跡4点（最小セット）
**内容**: link_check / parts_integrity / forbidden_patterns / sources_integrity
**保存先**: evidence/verify_reports/
## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] Incident対応と再発防止策が記録されている

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
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
