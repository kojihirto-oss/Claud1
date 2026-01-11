# ADR-0002: glossary/ と Part02 の役割分離（方針A採用）

- 日付: 2026-01-09
- 状態: 承認
- 影響Part: Part02
- 参照: FACTS_LEDGER.md (F-0008, F-0040-0057), glossary/README.md

## 背景

現状、glossary/GLOSSARY.md の先頭に「# Part02 用語集（単一の正）」と記載されており、docs/Part02.md のタイトルも「共通語彙（用語固定で迷いを消す）」となっている。

この状況では以下の問題が生じる：
1. **二重管理のリスク**: Part02 に用語定義を書くと、glossary/ との同期が必要になる
2. **参照の曖昧さ**: 「用語の唯一定義」がどこにあるか不明確
3. **更新の煩雑さ**: 用語を追加/変更するたびに2箇所を編集する必要がある

したがって、glossary/ と Part02 の役割を明確に分離する必要がある。

## 決定

**方針A を採用する**: glossary/GLOSSARY.md を「用語の唯一定義（実体）」とし、docs/Part02.md は「用語運用ルール」に特化する。

### glossary/GLOSSARY.md の役割
- 用語の定義本体を保持する
- 各用語に以下を必須記載：
  - 一文定義
  - 境界（含む/含まない）
  - 参照（FACTS_LEDGER の F-XXXX または sources/ パス）
  - 類義語・禁止表記
- 形式: Markdown、セクション単位で用語を列挙

### docs/Part02.md の役割
- 用語管理の運用ルールを定義：
  - どのタイミングで用語を追加/変更するか
  - 表記規約（英大文字/スペース/ハイフン等）
  - docs 本文で用語を使うときの参照ルール（必ず glossary リンク、等）
  - 用語変更時の事故防止（ADR必須、既存用語の互換維持、など）
- 用語定義そのものは**書かない**（glossary/ へ委譲）
- Part02 から glossary/GLOSSARY.md へのリンクを明記

## 選択肢

### 案A（採用）: glossary/ が唯一定義、Part02 は運用ルール
- **メリット**:
  - 役割が明確。用語定義は glossary/ のみを更新すればよい
  - Part02 は「いつ・誰が・どう更新するか」に集中できる
  - 参照時に迷いがない（glossary/ を見ればよい）
- **デメリット**:
  - Part02 と glossary/ を行き来する必要がある（許容範囲）

### 案B: Part02 に定義を書き、glossary/ は索引
- **メリット**: Part02 だけ読めば済む
- **デメリット**:
  - glossary/ の存在意義が薄れる
  - Part02 が肥大化し、運用ルールが埋もれる
  - 用語追加のたびに Part02 を編集すると、変更履歴が煩雑

### 案C: glossary/ と Part02 を統合
- **メリット**: フォルダが減る
- **デメリット**:
  - 「定義」と「運用」が混在し、可読性が低下
  - ADR-0001 で確立した「役割分離」の原則に反する

**結論**: 案A を採用。役割分離により、用語の一貫性と運用の透明性を両立する。

## 影響範囲

### 互換/移行
- glossary/GLOSSARY.md の先頭から「# Part02 用語集」を削除し、独立した用語集として明記
- docs/Part02.md は「用語運用ルール」として再定義
- 既存の用語リスト（SSOT, VAULT, RELEASE等）は glossary/GLOSSARY.md に定義を追加

### セキュリティ/権限
- 影響なし（用語管理は読取専用操作が中心）

### Verify/Evidence/Release への影響
- checks/ に「用語揺れ検出」を追加することを推奨（glossary/ との一致を検証）

## 実行計画

### 手順
1. ✅ 本ADR（0002）を追加（本ファイル）
2. 🔲 glossary/GLOSSARY.md を実体化（定義を追加）
3. 🔲 docs/Part02.md を「用語運用ルール」として埋める
4. 🔲 checks/ に「用語揺れ検出」スクリプトを追加（任意）

### ロールバック
- 本ADRを廃止（状態: 廃止）し、decisions/0004-revert-glossary-separation.md を追加
- Part02 に用語定義を統合し、glossary/GLOSSARY.md は索引に変更

### 検証（Verify Gate）
- [ ] glossary/GLOSSARY.md に最低18個の用語が定義されている
- [ ] 各用語に「定義・境界・参照」が記載されている
- [ ] Part02.md が「運用ルール」として機能している
- [ ] Part02.md から glossary/GLOSSARY.md へのリンクが存在する

## 結果
（後日記入: 運用開始後、どう機能したか、改善点）

---

## チェックリスト
- [x] ADR を decisions/ に配置
- [ ] glossary/GLOSSARY.md を実体化
- [ ] docs/Part02.md を運用ルールとして埋める
- [ ] checks/ に用語揺れ検出を追加（任意）

## 未決事項
- 用語の承認フロー（glossary/ への追加は誰が承認？）→ Part09 で定義予定
- 多言語対応（日英併記 or 別ファイル？）→ 初回多言語化時に決定

## 参照
- [FACTS_LEDGER.md](../docs/FACTS_LEDGER.md) : F-0008（用語管理の重要性）
- [glossary/README.md](../glossary/README.md) : 用語管理の運用ルール
- [CLAUDE.md](../CLAUDE.md) : 用語の揺れ防止に関する絶対ルール
