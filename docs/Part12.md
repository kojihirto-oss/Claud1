# Part 12：Evidence（証跡パック）運用（RUNLOG/TRACE/ハッシュ/参照パス/監査可能性）

## 0. このPartの位置づけ
- 目的：Evidenceの作成・保存・参照パスを固定し、監査可能性を維持する
- 依存：Part00（SSOT憲法）、Part09（Permission Tier）、Part10（Verify Gate）、Part14（変更管理）、Part15（運用ループ）
- 影響：evidence/ の運用、Verify結果の扱い、監査の整合性

## 1. 目的（Purpose）
Evidenceの最小セットと保存ルールを統一し、  
Verify/Evidenceが揃っていない変更を排除する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- evidence/ に保存する証跡の作成・整理・参照
- Verify結果の保存と参照パスの維持
- 監査に必要な最小セットの確保

### Out of Scope（対象外）
- sources/ への更新
- 実装コードの詳細手順（別Part）
- 外部ツールの運用規約（組織ルール）

## 3. 前提（Assumptions）
1. docs/ が唯一のSSOTである
2. Verify/Evidenceは Part00/Part10 に従う
3. 変更管理は Part14 に従う
4. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Evidence**: 変更の根拠・検証・監査を支える証跡
- **RUNLOG**: 作業実行のログ
- **TRACE**: 参照元と変更の関連付け
- **参照パス**: Evidenceの保存先を示すパス

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1201: Evidence保存義務【MUST】
Verify結果と変更記録は evidence/ に保存し、削除しない。

### R-1202: PASS証跡のみ採用【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-1203: 証跡4点の最小セット【MUST】
link/parts/forbidden/sources の4点を最小セットとして保存する。

### R-1204: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-1205: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：必要な証跡の種類と保存先を特定する。
2. 記録：対象ファイル、参照根拠、保存先のパスを記録する。
3. 修正：最小差分でEvidenceを整理し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点を保存する。
5. 監査：Evidence一覧・参照パス・DoDを点検し、不足がないか確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 誤更新が疑われる
- 直前の変更を取り消し、影響範囲を再確認して再検証する。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1201: Evidence最小セットの確認
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-1202: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1201: 変更記録
**内容**: 発見内容、修正理由、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part14に従う）

### E-1202: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-1203: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] Evidenceの参照パスが記録されている

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
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
