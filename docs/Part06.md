# Part 06：IDE/司令塔運用（Antigravity中心・安全プロファイル・作業境界・レビュー主導）

## 0. このPartの位置づけ
- 目的：IDE/司令塔の運用境界を固定し、安全プロファイルとレビュー主導でSSOTを保護する
- 依存：Part00（SSOT憲法）、Part03（AI Pack）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：docs/ 更新の運用手順、作業境界、証跡と監査の整合

## 1. 目的（Purpose）
IDE/司令塔（Antigravity）を「指揮と確認の場」として運用し、  
作業境界・安全プロファイル・レビュー主導を徹底してSSOTの汚染を防ぐ。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- IDE/司令塔（Antigravity）での運用手順
- docs/ 更新における作業境界とレビュー主導
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- 実装コード・テスト設計の詳細（別Part）
- 組織固有の承認者の人事規定

## 3. 前提（Assumptions）
1. IDE/司令塔は指揮・確認の場として運用する
2. Permission Tierは Part09 に従う
3. Verify/Evidenceは Part00/Part10/Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **IDE/司令塔**: Antigravityを中心とした作業指揮・確認の場
- **安全プロファイル**: ReadOnly/ExecLimited などの作業権限制御
- **作業境界**: docs/ を中心とした変更範囲の制約

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-0601: 司令塔の役割固定【MUST】
IDE/司令塔は「指揮・確認・レビュー」に限定し、無断の実装判断をしない。

### R-0602: 安全プロファイル適用【MUST】
最小権限で作業し、必要時のみ承認を得て権限を上げる。

### R-0603: レビュー主導【MUST】
変更はレビュー前提で進め、発見・記録・検証の順序を省略しない。

### R-0604: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-0605: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-0606: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：対象作業の範囲・依存・権限制約を確認する。
2. 記録：発見内容、参照根拠、対象ファイル、作業メモの保存先を記録する。
3. 修正：最小差分で更新し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link/parts/forbidden/sources）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、レビュー判断を記録する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 権限が不足・不一致
- Permission Tierを見直し、必要ならHumanGateで承認を得て再実行する。

### 例外4: 汚染の疑い
- 参照根拠を照合し、根拠不明な更新を除外して再検証する。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-0601: 司令塔運用の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-0602: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-0601: 運用記録
**内容**: 作業範囲、権限プロファイル、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-0602: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-0603: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] 作業境界と権限プロファイルが記録されている

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
- [Part03](./Part03.md) : AI Pack / Antigravity
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
