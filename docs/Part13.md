# Part 13：Release（不変成果物）運用（manifest/sha256/SBOM・再現性・配布単位）

## 0. このPartの位置づけ
- 目的：Releaseの不変成果物運用を固定し、再現性と監査可能性を担保する
- 依存：Part00（SSOT憲法）、Part01（DoD）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：RELEASE/ の生成・保存、manifest/sha256/SBOM の整合性

## 1. 目的（Purpose）
Releaseを不変成果物として扱い、manifest/sha256/SBOMと証跡の整合を維持する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- RELEASE/ の作成・保存・参照
- manifest/sha256/SBOM の生成と保存
- Releaseに関するVerify/Evidenceの保存

### Out of Scope（対象外）
- sources/ への更新
- 実装コードの詳細手順（別Part）
- 配布先の運用（外部手続き）

## 3. 前提（Assumptions）
1. Releaseは不変成果物である
2. Verify/Evidenceは Part00/Part10/Part12 に従う
3. 変更管理は Part14 に従う
4. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Release**: 不変の成果物単位
- **manifest**: Release構成の一覧
- **sha256**: 整合性検証のハッシュ
- **SBOM**: 依存関係の構成情報

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1301: Release不変【MUST】
Releaseは作成後に改変しない（更新は新規Releaseで行う）。

### R-1302: 証跡と整合【MUST】
Releaseには manifest/sha256/SBOM を必ず付与し、Evidenceに保存する。

### R-1303: HumanGate必須【MUST】
Release生成・確定はHumanGate承認の対象とする。

### R-1304: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-1305: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-1306: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：Release対象と必須成果物（manifest/sha256/SBOM）を確認する。
2. 記録：対象ファイル、参照根拠、保存先を記録する。
3. 修正：最小差分でRelease情報を整備し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）を保存する。
5. 監査：Releaseの不変性・参照パス・証跡一覧・DoDを点検する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: Releaseの汚染が疑われる
- Releaseを破棄し、新規Releaseとして作り直す。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1301: Release証跡の確認
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-1302: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1301: Release記録
**内容**: Release対象、manifest/sha256/SBOM、参照根拠  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-1302: Verify証跡（PASSのみ）
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
- [ ] Releaseの不変性と参照パスが記録されている

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
