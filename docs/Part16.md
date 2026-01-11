# Part 16：KB/RAG運用・更新プロトコル（知識更新・反映手順・汚染防止・参照規約）

## 0. このPartの位置づけ
- 目的：KB/RAGの更新と参照を安全に運用し、汚染と不整合を防ぐ
- 依存：Part00（真実順序）、Part10（Verify Gate）、Part12（Evidence）、Part14（変更管理）、Part15（運用ループ）
- 影響：docs/ 内の知識更新・参照規約、監査証跡の整合性

## 1. 目的（Purpose）
KB/RAGの更新を「発見 → 記録 → 修正 → 検証 → 監査」の運用ループで標準化し、  
参照規約と証跡を揃えてSSOTの整合性を維持する。

## 2. 適用範囲（Scope / Out of Scope）
### Scope（対象）
- docs/ におけるKB/RAGの更新手順と参照規約
- Verify結果の確認とEvidenceの整理

### Out of Scope（対象外）
- sources/ への更新
- 実装コードの詳細手順（別Part）

## 3. 前提（Assumptions）
1. 真実順序は Part00 に従う
2. Verifyの定義は Part10 に従う
3. Evidenceの形式と保存先は Part12 に従う
4. 変更管理は Part14 に従う
5. 運用ループは Part15 に従う

## 4. 用語（Glossary参照：Part02）
- **KB**: docs/ を中心に管理する知識ベース
- **RAG**: KBを参照する取得・統合の運用形態
- **汚染**: 真実順序や根拠を欠いた更新による不整合

## 5. ルール（MUST / MUST NOT / SHOULD）
### R-1601: 運用ループの順守【MUST】
KB/RAG更新は「発見 → 記録 → 修正 → 検証 → 監査」で実施し、順序を省略しない。

### R-1602: 参照根拠の明示【MUST】
変更理由は Part00 の真実順序に基づき、根拠を記録する。

### R-1603: 証跡はPASSのみ採用【MUST】
VerifyはPASS証跡のみを採用し、Evidenceに保存する。

### R-1604: 最小差分の更新【SHOULD】
無関係な整理を混在させず、最小差分で更新する。

### R-1605: sources/ 無改変【MUST NOT】
sources/ は改変しない（追加のみ許可）。対象外のファイルに変更が出た場合は即時停止する。

### R-1606: Fast PASS 必須【MUST】
Fast検証でPASSするまでコミットしない。PASS証跡のみ採用する。

### R-1607: 証跡4点の最小セット【MUST】
link/parts/forbidden/sources の4点を最小セットとして保存する。

## 6. 手順（実行可能な粒度、番号付き）
1. 発見：不整合や不足点を特定し、影響範囲と参照根拠を確認する。
2. 記録：発見内容、根拠、対象ファイル、作業メモの保存先を記録する。
3. 修正：最小差分で更新し、sources/ 無改変を維持したまま変更理由を短く記録する。
4. 検証：Fast検証でPASSを確認し、証跡4点（link/parts/forbidden/sources）を保存する。
5. 監査：変更概要・参照パス・証跡一覧・DoDを点検し、汚染や差分過多がないか確認する。

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
### 例外1: 検証が通らない
- 最大3ループで解決できない場合、HumanGateへエスカレーションする（Part09）。

### 例外2: 証跡が欠落
- 検証を再実行して補完し、理由を記録する。

### 例外3: 誤更新が疑われる
- 直前の変更を取り消し、影響範囲を再確認して再検証する。

### 例外4: 汚染の疑いがある
- 参照根拠を照合し、根拠不明な更新を除外して再検証する。

### 例外5: 差分が過大
- 更新を分割し、最小差分になるまで手順をやり直す。

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
### V-1601: 運用ループの記録
**判定条件**:
1. 発見・修正・検証・監査の記録がある
2. PASS証跡のみ採用されている
3. 証跡4点（link/parts/forbidden/sources）が揃っている

**合否**:
- **PASS**: 1〜3を満たす
- **FAIL**: 記録欠落、FAIL証跡の混在、証跡4点の欠落

**ログ**: evidence/verify_reports/

### V-1602: Part00 Verify要件との整合
**判定条件**:
1. V-0001〜V-0004のログが存在する
2. sources/ の改変がない

**合否**:
- **PASS**: 1,2を満たす
- **FAIL**: ログ欠落、または sources/ 改変がある

**ログ**: evidence/verify_reports/

## 9. 監査観点（Evidenceに残すもの・参照パス）
### E-1601: 変更記録
**内容**: 発見内容、修正理由、参照根拠、変更概要  
**保存先**: evidence/ または decisions/（Part12/Part14に従う）

### E-1602: Verify証跡（PASSのみ）
**内容**: Fast検証のPASSログ  
**保存先**: evidence/verify_reports/

### E-1603: 証跡4点（最小セット）
**内容**: link_check / parts_check / forbidden_check / sources_integrity  
**保存先**: evidence/verify_reports/

## 10. チェックリスト
- [ ] 発見・記録・修正・検証・監査の順序が揃っている
- [ ] PASS証跡のみを採用している
- [ ] 参照パスが更新されている
- [ ] 証跡4点（link/parts/forbidden/sources）が揃っている
- [ ] 最小差分であり、sources/ 無改変である
- [ ] Fast検証がPASSしている

## 11. 未決事項（推測禁止）
- 参照根拠の記録粒度（最小単位の定義）

## 12. 参照（パス）
- docs/
- sources/
- evidence/
- decisions/
### docs/
- [Part00](./Part00.md) : SSOT憲法（真実順序）
- [Part02](./Part02.md) : 用語・表記
- [Part09](./Part09.md) : HumanGate
- [Part10](./Part10.md) : Verify Gate
- [Part12](./Part12.md) : Evidence運用
- [Part14](./Part14.md) : 変更管理
- [Part15](./Part15.md) : 運用ループ（発見→記録→修正→検証→監査）
- [00_INDEX](./00_INDEX.md) : 全体索引
- [FACTS_LEDGER](./FACTS_LEDGER.md) : 事実台帳
