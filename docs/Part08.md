# Part 08：Context Engineering（Context Pack生成・入力最小化・信頼境界）

## 0. このPartの位置づけ
- 目的：Context Packの生成と信頼境界を実務手順として固定し、過剰入力と汚染を防ぐ
- 依存：Part00（SSOT憲法）、Part03（AI Pack）、Part09（Permission Tier）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：docs/ 更新の入力設計、参照根拠、証跡と監査の整合

## 1. 目的（Purpose）
Context Packの入力最小化・信頼境界・参照根拠の明示を統一し、  
AI運用がSSOTを逸脱しないようにする。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- Context Packの生成と更新手順
- 入力最小化の判断基準
- 参照根拠と信頼境界の記録
- Verify/Evidenceの保存と監査対応

### Out of Scope（対象外）
- sources/ への更新
- 個別AIのプロンプト設計の詳細（別Part）
- 外部情報の収集手順（別Part）

## 3. 前提（Assumptions）
1. SSOTは docs/ に固定される
2. Permission Tierは Part09 に従う
3. Verify/Evidenceは Part00/Part10/Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **Context Pack**: 作業に必要な最小限の参照束
- **信頼境界**: 参照可能な根拠範囲（SSOT/Verify/Evidenceの優先順）
- **入力最小化**: 必要最小限の情報に絞る運用

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-0801: Context Pack最小化【MUST】
作業に必要な最小限の参照のみを含め、過剰な入力を避ける。

### R-0802: 信頼境界の明示【MUST】
参照根拠の優先順位（SSOT/Verify/Evidence）を明記する。

### R-0803: 運用ループの順守【MUST】
Context Packの更新は「発見 → 記録 → 修正 → 検証 → 監査」で実施する。

### R-0804: sources/ 無改変【MUST NOT】
sources/ の改変は禁止（追加のみ許可）。検出時は作業を停止する。

### R-0805: Fast PASS 必須【MUST】
Fast検証でPASSした証跡のみを採用する。

### R-0806: 最小差分【SHOULD】
無関係な整理は含めず、最小差分で更新する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：Context Packの不足・過剰・根拠不整合を特定する。
2. 記録：発見内容、参照根拠、対象ファイル、保存先を記録する。
3. 修正：最小差分でContext Packを更新し、sources/ 無改変を維持する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、信頼境界を確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 修正に戻して再検証し、最大3ループで解決できない場合はHumanGateへエスカレーションする。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 参照根拠が不明
- 未決事項として記録し、確定情報が得られるまで反映しない。

### 例外4: 差分が過大
- 変更を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-0801: Context Pack更新の記録
**判定条件**:
1. 発見・記録・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-0802: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-0801: Context Pack記録
**内容**: 参照根拠、最小化判断、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-0802: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-0803: 証跡4点（最小セット）
**内容**: link_check / parts_integrity / forbidden_patterns / sources_integrity
**保存先**: evidence/verify_reports/
## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] 証跡4点（link_check/parts_integrity/forbidden_patterns/sources_integrity）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている
- [ ] 信頼境界と参照根拠が記録されている

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
- [Part03](./Part03.md) : AI Pack / Context共有
- [Part09](./Part09.md) : Permission Tier / HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳

### Gitコミットメッセージ一次情報
- [Git - git-commit Documentation](https://git-scm.com/docs/git-commit) : Git公式コミットドキュメント
- [8 Git Commit Message Best Practices for 2025](https://blog.pullnotifier.com/blog/8-git-commit-message-best-practices-for-2025) : 2025年版コミットメッセージベストプラクティス
- [How to Write a Good Git Commit Message](https://www.gitkraken.com/learn/git/best-practices/git-commit-message) : 良いコミットメッセージの書き方
- [Conventional Commits](https://www.conventionalcommits.org/) : Conventional Commits仕様
