# Part 17：運用OS接続（Verify→Evidence→Releaseを運用ボタン体系に接続・自動化）

## 0. このPartの位置づけ
- 目的：Verify→Evidence→Releaseの運用をボタン体系に接続し、手順漏れを防ぐ
- 依存：Part00（真実順序）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：運用ボタンの実行基準、監査証跡の整合性

## 1. 目的（Purpose）
運用OSのボタン体系に、VerifyとEvidenceの流れを統合し、  
誰が実行しても同じ順序と証跡でReleaseへ到達できる状態を作る。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- VerifyとEvidenceの実行・記録フロー
- Release前の運用ボタンの実行順序

### Out of Scope（対象外）
- sources/ の更新
- 組織固有の承認フロー詳細

## 3. 前提（Assumptions）
1. 真実順序は Part00 に従う
2. Verifyの定義は Part10 に従う
3. Evidenceの形式と保存先は Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **運用OS**: 運用ボタンで手順を実行する仕組み
- **運用ボタン**: Verify/Evidence/Releaseの実行単位
- **Release Gate**: Evidenceが揃って初めて通過できる条件

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1701: 運用ループの順守【MUST】
発見 → 記録 → 修正 → 検証 → 監査の順序を省略しない。

### R-1702: Evidence先行【MUST】
Release前にPASS証跡を確定し、Evidenceに保存する。

### R-1703: ボタンの順序固定【MUST】
Verify → Evidence → Release の順序を変更しない。

### R-1704: 最小差分【SHOULD】
運用手順の変更は最小差分で実施する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：対象の不整合や運用課題を特定する。
2. 記録：発見内容、根拠、対象ボタンを記録する。
3. 修正：最小差分で手順を更新する。
4. 検証：Fast検証でPASSを確認し、Evidenceを整理する。
5. 監査：実行ログと証跡一覧を残す。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 最大3ループで解決できない場合、HumanGateへエスカレーションする。

### 例外2: ボタンが利用不可
- 手動実行に切り替え、理由と結果を記録する。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1701: Release Gateの成立
**判定条件**:
1. PASS証跡が evidence/verify_reports/ に存在する
2. Verify→Evidence→Releaseの実行ログがある

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: 証跡不足、または順序違反

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1701: 実行ログ
**内容**: 実行ボタン名、実行時刻、担当者  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-1702: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見→記録→修正→検証→監査の順序で実施した
- [ ] PASS証跡が evidence/verify_reports/ に揃っている
- [ ] Verify→Evidence→Releaseの順序が守られている

## 11. 未決事項（推測禁止）
- 運用ボタンの命名規則と粒度

## 12. 参照（パス）
- docs/
- sources/
- evidence/
- decisions/
### docs/
- [Part00](./Part00.md) : SSOT憲法（真実順序）
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence管理
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [Part16](./Part16.md) : KB/RAG運用
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
