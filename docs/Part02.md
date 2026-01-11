# Part 02：共通語彙の運用（用語固定で迷いを消す：SSOT/VAULT/RELEASE/DoD/ADR/Permission Tier等）

## 0. このPartの位置づけ
- **目的**: 用語の揺れを防止し、同じ概念を複数の表記で呼ばないための運用ルールを定義する
- **依存**: glossary/GLOSSARY.md（用語の唯一定義）
- **影響**: 全Part（全てのPartで用語を使用するため）

## 1. 目的（Purpose）

50+フォルダ級の大規模開発では、**用語の揺れ**が事故の原因となる。

**問題例**:
- 「チェック」「検証」「確認」が混在 → どれが Verify を指すか不明
- 「正本」「マスタ」「SSOT」が混在 → 何が唯一の真実か不明
- 「証跡」「エビデンス」「Evidence」が混在 → 保存先・形式が曖昧

したがって、**用語を固定し、全員が同じ表記・意味で使う**ことで、迷いと誤解を根絶する。

**根拠**: FACTS_LEDGER F-0001（真実の優先順位）、ADR-0002（glossary vs Part02 の役割分離）

---

## 2. 適用範囲（Scope / Out of Scope）

### In Scope（この Part が管理する）
- 用語の追加・変更・廃止の手順
- 表記規約（英大文字/スペース/ハイフン等）
- docs/ 本文で用語を使うときの参照ルール
- 用語変更時の事故防止（ADR必須、既存用語の互換維持）

### Out of Scope（この Part では扱わない）
- 用語の定義本体 → **glossary/GLOSSARY.md** に委譲
- 用語の詳細な意味・境界・例 → glossary/GLOSSARY.md を参照
- 用語以外の運用ルール → 各 Part で定義

---

## 3. 前提（Assumptions）

- **glossary/GLOSSARY.md が唯一の定義**: docs/Part02 は運用ルールのみを扱う（ADR-0002で決定）
- **用語は頻繁に追加される**: 新しい概念・ツール・手法が登場するたびに追加が必要
- **用語の揺れは事故につながる**: 検索失敗、参照ミス、誤解が発生する

---

## 4. 用語（Glossary参照：Part02）

この Part で使用する主要用語：
- [SSOT](../glossary/GLOSSARY.md#ssot-single-source-of-truth)
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md)
- [ADR](../glossary/GLOSSARY.md#adr-architecture-decision-record)
- [Verify](../glossary/GLOSSARY.md#verify--verify-gate)

**重要**: 用語の定義は glossary/GLOSSARY.md を参照。この Part では運用ルールのみを記載。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### MUST（絶対）

#### R-0201: 用語は glossary/GLOSSARY.md で一元管理
- **ルール**: 全ての用語は glossary/GLOSSARY.md に定義を書く。docs/Part02 には定義を書かない。
- **理由**: 二重管理を防ぎ、参照先を明確にする。
- **根拠**: ADR-0002（方針A採用）

#### R-0202: 用語追加は ADR 必須
- **ルール**: 新しい用語を追加する場合、以下の手順を守る：
  1. decisions/ に ADR を追加（なぜこの用語が必要か、他の表記を排除する理由）
  2. ADR が承認されたら、glossary/GLOSSARY.md に定義を追加
  3. docs/ の該当 Part に用語を使用
- **理由**: 用語の増殖を防ぎ、必要性を記録する。
- **根拠**: FACTS_LEDGER F-0003（変更規約）

#### R-0203: docs/ では glossary/ の表記に完全一致させる
- **ルール**: docs/ で用語を使う際は、必ず glossary/GLOSSARY.md の表記に一致させる。
- **禁止**:
  - glossary/ にない表記を勝手に使う
  - 同じ概念を複数の表記で呼ぶ（例: 「チェック」「検証」「確認」を混在）
- **例外**: 引用・コマンド名など、変更できない場合のみ許容（その旨を明記）

#### R-0204: 重要な用語には glossary/ へのリンクを付ける
- **ルール**: 各 Part で重要な用語を初出時に使う際は、glossary/ へのリンクを付ける。
- **形式**: `[用語](../glossary/GLOSSARY.md#用語アンカー)`
- **例**: `[SSOT](../glossary/GLOSSARY.md#ssot-single-source-of-truth)`

### MUST NOT（禁止）

#### R-0210: 用語を勝手に変更しない
- **禁止**: glossary/ に定義された用語を、ADR なしで変更する。
- **理由**: 既存の docs/ や checks/ が参照している用語を変更すると、リンク切れ・検索失敗が発生する。
- **手順**: 用語を変更する場合は、ADR で互換性・移行手順を明記してから実施。

#### R-0211: 口語・略称を docs/ で使わない
- **禁止**:
  - 「OK」「NG」（→「合格」「不合格」または「PASS」「FAIL」）
  - 「マスタ」（→「SSOT」）
  - 「チェック」（→「Verify」）
- **理由**: 曖昧さを排除し、検索可能性を高める。
- **例外**: コマンド名・ツール名など、変更できない場合のみ許容。

### SHOULD（推奨）

#### R-0220: 用語の類義語・禁止表記を明記
- **推奨**: glossary/GLOSSARY.md に用語を追加する際、類義語・禁止表記を明記する。
- **理由**: 揺れを事前に防ぐ。
- **例**:
  - SSOT: 禁止表記「マスターデータ」「正本」「マスタ」「原本」
  - Evidence: 禁止表記「エビデンス」（カタカナ）

#### R-0221: 用語揺れ検出を checks/ に追加
- **推奨**: checks/ に「用語揺れ検出」スクリプトを追加し、glossary/ にない表記を docs/ で使っていないか検証する。
- **例**:
  ```bash
  # 禁止表記の検出
  grep -r "マスタ" docs/  # 「SSOT」に統一すべき
  grep -r "チェック" docs/  # 「Verify」に統一すべき
  ```

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: 新しい用語を追加する

1. **用語の必要性を確認**
   - 既存の用語で表現できないか確認（glossary/GLOSSARY.md を検索）
   - 類義語が既に定義されていないか確認

2. **ADR を作成**（R-0202 必須）
   - decisions/ に `NNNN-add-term-<term-name>.md` を作成
   - 以下を記載：
     - なぜこの用語が必要か
     - 他の表記を排除する理由
     - 影響範囲（どの Part で使うか）

3. **ADR を承認**
   - 関係者にレビュー依頼（承認フローは Part09 で定義予定）
   - 異論がなければ「状態: 承認」に変更

4. **glossary/GLOSSARY.md に定義を追加**
   - 以下を必須記載：
     - 一文定義
     - 境界（含む/含まない）
     - 参照（FACTS_LEDGER の F-XXXX または sources/ パス）
     - 関連用語
     - 表記規約
     - 禁止表記（該当する場合）

5. **docs/ の該当 Part に用語を使用**
   - 初出時に glossary/ へのリンクを付ける
   - R-0203（表記の完全一致）を守る

6. **（任意）checks/ に用語揺れ検出を追加**
   - 禁止表記を検出するスクリプトを追加

---

### 手順B: 既存の用語を変更する

1. **変更の必要性を確認**
   - なぜ変更が必要か（誤解を招く？別の概念と混同される？）
   - 影響範囲を調査（どの Part で使われているか）

2. **ADR を作成**（R-0210 必須）
   - decisions/ に `NNNN-change-term-<old>-to-<new>.md` を作成
   - 以下を記載：
     - 変更理由
     - 旧用語と新用語の対応
     - 互換性（旧用語を残すか？エイリアスとするか？）
     - 移行手順（docs/ のどこを修正するか）
     - ロールバック手順

3. **ADR を承認**

4. **glossary/GLOSSARY.md を更新**
   - 新用語を追加 or 既存用語を修正
   - 旧用語を「廃止」として明記（削除しない、検索可能性を維持）

5. **docs/ を一括更新**
   - 旧用語→新用語に置換（grep -r で全検索）
   - リンク切れがないか確認（checks/ で検証）

6. **checks/ を更新**
   - 旧用語を検出した場合に警告するスクリプトを追加

---

### 手順C: 用語揺れを発見した場合

1. **glossary/ を確認**
   - 正式な表記を特定

2. **docs/ の該当箇所を修正**
   - 正式な表記に統一

3. **checks/ に検出ルールを追加**
   - 同じ揺れが再発しないように、禁止表記として登録

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: 用語の定義が曖昧
**症状**: 「この用語は何を指すか」が不明確。
**対応**:
1. glossary/GLOSSARY.md の定義を確認
2. 定義が不足している場合、ADR を作成して定義を明確化
3. FACTS_LEDGER の未決事項（U-XXXX）に追加

**エスカレーション**: 定義が矛盾している場合、Part00（憲法）に立ち返り、真実の優先順位（F-0001）で裁定。

---

### 例外2: 用語が多すぎて管理不能
**症状**: glossary/ が肥大化し、検索が困難。
**対応**:
1. 用語をカテゴリ別に分割（例: `GLOSSARY_SECURITY.md`, `GLOSSARY_INFRA.md`）
2. ADR で分割方針を決定してから実施
3. docs/00_INDEX.md に索引を追加

**エスカレーション**: 100用語を超えた時点で、分割を検討（ADR 必須）。

---

### 例外3: 用語揺れが大量に検出された
**症状**: checks/ で用語揺れが大量に検出され、修正が困難。
**対応**:
1. 揺れの原因を分類（初期導入ミス？新しい概念の導入？）
2. 優先度を決定（高頻度の用語から修正）
3. 一括置換スクリプトを作成（Dry-run → レビュー → 実行）

**エスカレーション**: 一括置換がリスク大の場合、Part09（Permission Tier）で HumanGate 承認を取る。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### Verify項目

#### V-0201: glossary/ にない用語が docs/ で使われていないか
**判定条件**:
- glossary/GLOSSARY.md に定義された用語のみが docs/ で使用されている
- 禁止表記（「マスタ」「チェック」等）が docs/ に含まれていない

**合格**:
- 禁止表記が0件
- 未定義用語が0件（または、許容リスト内のみ）

**不合格**:
- 禁止表記が1件以上検出
- 未定義用語が1件以上検出

**ログ**:
```
[FAIL] 禁止表記が検出されました:
  - docs/Part05.md:42: "マスタ" → "SSOT" に修正
  - docs/Part07.md:78: "チェック" → "Verify" に修正
```

---

#### V-0202: glossary/ へのリンク切れがないか
**判定条件**:
- docs/ から glossary/ へのリンクが全て有効
- アンカーが正しい（用語名と一致）

**合格**: リンク切れ0件

**不合格**: リンク切れ1件以上

**ログ**:
```
[FAIL] リンク切れが検出されました:
  - docs/Part02.md:15: [SSOT](../glossary/GLOSSARY.md#ssot) → アンカーが存在しません
```

---

#### V-0203: 用語の表記が一致しているか
**判定条件**:
- docs/ で使用されている用語の表記が、glossary/ の表記と完全一致（大文字小文字、スペース、ハイフン等）

**合格**: 不一致0件

**不合格**: 不一致1件以上

**ログ**:
```
[FAIL] 表記の不一致が検出されました:
  - docs/Part04.md:23: "verify" → "Verify" に修正（glossary では頭文字大文字）
```

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### Evidence-0201: 用語追加の記録
**残すもの**:
- ADR（decisions/NNNN-add-term-<term-name>.md）
- glossary/GLOSSARY.md の差分（git diff）
- 用語追加日・承認者・理由

**保存先**: `VAULT/EVIDENCE/term_changes/`

---

### Evidence-0202: 用語変更の記録
**残すもの**:
- ADR（decisions/NNNN-change-term-<old>-to-<new>.md）
- glossary/GLOSSARY.md の差分
- docs/ の一括置換ログ（何を・どこで・いつ変更したか）
- 旧用語→新用語の対応表

**保存先**: `VAULT/EVIDENCE/term_changes/`

---

### Evidence-0203: 用語揺れ検出の結果
**残すもの**:
- checks/ の実行結果（禁止表記の検出件数・箇所）
- 修正前後の diff
- 修正日・修正者

**保存先**: `evidence/verify_reports/YYYYMMDD_HHMMSS_term_drift.md`

---

## 10. チェックリスト

### 用語追加時
- [ ] ADR を作成し、必要性を記録
- [ ] glossary/GLOSSARY.md に定義を追加（一文定義・境界・参照・関連用語・表記規約）
- [ ] 禁止表記がある場合、明記
- [ ] docs/ の該当 Part に用語を使用（初出時にリンク）
- [ ] checks/ に用語揺れ検出を追加（任意）

### 用語変更時
- [ ] ADR を作成し、変更理由・互換性・移行手順を記録
- [ ] glossary/GLOSSARY.md を更新（旧用語は廃止として残す）
- [ ] docs/ を一括更新（grep -r で全検索→置換）
- [ ] リンク切れがないか確認（checks/ で検証）
- [ ] checks/ に旧用語の検出ルールを追加

### 用語揺れ発見時
- [ ] glossary/ で正式な表記を確認
- [ ] docs/ の該当箇所を修正
- [ ] checks/ に検出ルールを追加

---

## 11. 未決事項（推測禁止）

### U-0201: 用語の承認フロー
**問題**: glossary/ への追加・変更は誰が承認するか？自動マージか？
**対応**: Part09（Permission Tier）で定義予定

### U-0202: 用語の多言語対応
**問題**: 日英併記か？別ファイルか？
**対応**: 初回多言語化時に ADR で決定

### U-0203: 用語の保存期限
**問題**: 廃止された用語はいつまで glossary/ に残すか？
**対応**: Part14（変更管理）で定義予定

### U-0204: 用語のバージョニング
**問題**: 用語の意味が変わった場合、バージョンを付けるか？
**対応**: 初回の用語意味変更時に ADR で決定

---

## 12. 参照（パス）

- **glossary/**: [../glossary/GLOSSARY.md](../glossary/GLOSSARY.md)
- **glossary/README**: [../glossary/README.md](../glossary/README.md)
- **ADR-0002**: [../decisions/0002-glossary-part02-separation.md](../decisions/0002-glossary-part02-separation.md)
- **FACTS_LEDGER**: [FACTS_LEDGER.md](FACTS_LEDGER.md) (F-0001, F-0003, F-0008)
- **CLAUDE.md**: [../CLAUDE.md](../CLAUDE.md) (用語の揺れ防止に関する絶対ルール)
