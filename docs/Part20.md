# Part 20：導入・教育・チェックリスト集（新規開始テンプレ・FAQ・最短運用手順）

## 0. このPartの位置づけ
- 目的：導入・教育・最短運用手順を固定し、新規参加者が迷わずSSOT運用できるようにする
- 依存：Part00（SSOT憲法）、Part01（DoD）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：オンボーディング、運用開始手順、監査と証跡の整合

## 1. 目的（Purpose）
新規参加者向けに最短運用手順とチェックリストを提供し、  
Verify/Evidenceの運用が一貫するようにする。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- 新規参加者のオンボーディング
- 最短運用手順（初回セットアップと検証）
- FAQとチェックリストの提示
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- 組織固有の研修プログラム
- 実装コードの詳細手順（別Part）

## 3. 前提（Assumptions）
1. SSOTは docs/ に固定される
2. Permission Tierは Part09 に従う
3. Verify/Evidenceは Part00/Part10/Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **オンボーディング**: 新規参加者の導入・教育プロセス
- **最短運用手順**: 最小ステップでSSOT運用を開始する手順
- **FAQ**: よくある質問と回答

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-2001: 最短運用手順の遵守【MUST】
新規参加者は最短運用手順に従い、手順を省略しない。

### R-2002: Evidence保存の徹底【MUST】
Fast検証のPASS証跡を保存し、証跡4点を揃える。

### R-2003: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-2004: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：必要な参照Partと運用ルールを確認する。
2. 記録：参照根拠、対象ファイル、保存先を記録する。
3. 修正：最小差分で初期手順を整備し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link/parts/forbidden/sources）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、導入手順の妥当性を確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 手順が過大
- 手順を分割し、最短運用手順として再構成する。

### 例外4: 再発が継続
- ADRで手順改訂を提案し、承認後に再対応する。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-2001: 導入手順の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-2002: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-2001: 導入手順の記録
**内容**: 最短運用手順、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-2002: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-2003: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] 導入手順と参照根拠が記録されている

## 11. 未決事項（推測禁止）
- 未決事項なし（現時点）

## 12. 参照（パス）
- docs/
- sources/
- evidence/
- decisions/
### docs/
- [Part00](./Part00.md) : SSOT憲法
- [Part01](./Part01.md) : 目標・DoD
- [Part02](./Part02.md) : 用語・表記
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
