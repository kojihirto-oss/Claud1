# Part 18：Operation Registry／司令塔UI（“押すボタン”体系・Busy/NextStep・状態遷移）

## 0. このPartの位置づけ
- 目的：Operation Registry（司令塔UI）の運用を固定し、状態遷移と次アクションを迷いなく実行できるようにする
- 依存：Part00（SSOT憲法）、Part04（作業管理）、Part06（IDE/司令塔運用）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：作業の状態遷移、次アクションの指示、監査用の記録整合

## 1. 目的（Purpose）
Operation Registry（司令塔UI）の表示と更新手順を標準化し、  
Busy/NextStep と状態遷移を運用ループに沿って固定する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- Operation Registry の更新と参照
- Busy/NextStep の記録と表示
- 状態遷移（READY/DOING/VERIFYING/REPAIRING/DONE/BLOCKED）
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- UI実装の詳細（別Part）
- 組織固有の画面デザイン方針

## 3. 前提（Assumptions）
1. 司令塔UIは作業の指示と確認の場である
2. VIBEKANBANの状態遷移は Part04 に従う
3. Permission Tierは Part09 に従う
4. Verify/Evidenceは Part00/Part10/Part12 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Operation Registry**: 司令塔UIの操作一覧・現在状態・次アクションの記録
- **Busy**: 実行中タスクの要約
- **NextStep**: 次に行うべき最短手順
- **状態遷移**: READY/DOING/VERIFYING/REPAIRING/DONE/BLOCKED の移行

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1801: 状態遷移の順守【MUST】
状態遷移は Part04 の定義に従い、飛ばしや戻しを行わない。

### R-1802: Busy/NextStepの明示【MUST】
現在の作業状況（Busy）と次アクション（NextStep）を必ず記録する。

### R-1803: 運用ループの順守【MUST】
Operation Registryの更新は「発見 → 記録 → 修正 → 検証 → 監査」で実施する。

### R-1804: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-1805: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-1806: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。


## 6. 手順（実行可能な粒度、番号付き）
1. 発見：Operation Registryの不足・不整合・状態遷移の誤りを特定する。
2. 記録：発見内容、参照根拠、対象ファイル、保存先を記録する。
3. 修正：最小差分で更新し、Busy/NextStep を明示する。sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link/parts/forbidden/sources）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、状態遷移の整合を確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 状態遷移が破綻
- 直前の変更を取り消し、状態遷移の根拠を再確認して再検証する。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1801: Operation Registry更新の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-1802: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1801: Operation Registry記録
**内容**: Busy/NextStep、状態遷移、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-1802: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-1803: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] Busy/NextStep と状態遷移が記録されている


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
- [Part04](./Part04.md) : 作業管理（状態遷移）
- [Part06](./Part06.md) : IDE/司令塔運用
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
