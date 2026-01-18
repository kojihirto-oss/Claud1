# Part 07：Spec（仕様凍結）運用（Spec必須要素・Freeze基準・承認手順）

## 0. このPartの位置づけ
- 目的：Specの凍結と承認を実務手順として固定し、後戻りと汚染を防ぐ
- 依存：Part00（SSOT憲法）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：docs/ の仕様記述、凍結判断、証跡と監査の整合

## 1. 目的（Purpose）
Spec凍結の判断基準・必須要素・承認手順を明確化し、  
凍結後の変更が運用ループと証跡に従うよう統一する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- docs/ のSpec凍結判断と更新手順
- 凍結に必要な必須要素の確認
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- 実装コードやテスト設計の詳細（別Part）
- 組織固有の承認者の人事規定

## 3. 前提（Assumptions）
1. docs/ が唯一のSSOTである
2. Verify/Evidenceの定義は Part00/Part10/Part12 に従う
3. 変更管理は Part14 に従う
4. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Spec**: 仕様記述（docs/ 内の要件・制約・合意事項）
- **Freeze**: 仕様の凍結（変更には明示の手続きが必要な状態）
- **Approval**: 承認（HumanGateを含む）

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-0701: 必須要素の充足【MUST】
凍結前に、目的・スコープ・非スコープ・制約・成功条件・検証方針が明記されていること。

### R-0702: 運用ループの順守【MUST】
凍結作業は「発見 → 記録 → 修正 → 検証 → 監査」の順で実施する。

### R-0703: 変更管理の適用【MUST】
凍結後の変更は Part14 の手続きに従い、必要ならADRを先行する。

### R-0704: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-0705: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-0706: 最小差分【SHOULD】
凍結に無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：凍結対象のSpecを特定し、必須要素の不足や矛盾を確認する。
2. 記録：不足点、参照根拠、対象ファイル、作業メモの保存先を記録する。
3. 修正：最小差分でSpecを補完し、sources/ 無改変を維持する。
4. 検証：Fast検証を実行し、証跡4点（link/parts/forbidden/sources）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、凍結可否を判断する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 凍結後の変更要請
- 変更管理（Part14）に従い、必要ならADRを先行し、再度凍結判断を行う。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-0701: 必須要素の充足
**判定条件**:
1. 目的・スコープ・非スコープ・制約・成功条件・検証方針が記載されている
2. 凍結対象が明記されている

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: 必須要素が欠落している

**ログ**: evidence/verify_reports/

### V-0702: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-0701: 凍結判断記録
**内容**: 必須要素の確認結果、凍結可否、参照根拠  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-0702: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-0703: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] 凍結判断と参照根拠が記録されている

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
