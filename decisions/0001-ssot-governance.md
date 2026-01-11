# ADR-0001: SSOT運用ガバナンス（変更手順・根拠・検証の統治）

- 日付: 2026-01-09
- 状態: 承認
- 影響Part: Part00, Part14（全Partに影響）
- 参照: CLAUDE.md, docs/00_INDEX.md

## 背景

VCG/VIBE 2026設計書SSOTを運用するには、**誰が・何を・どの順序で変更してよいか** を明確にしなければ、すぐに矛盾が蓄積し、SSOTが破壊される。とくに：

1. **変更の正当性**: 仕様変更の根拠がないまま docs/ を書き換えると、後から「なぜこうなったか」が追跡不能になる
2. **用語の揺れ**: 同じ概念を複数の表記で呼ぶと、検索・参照が破綻する
3. **根拠の散逸**: スクショ・ログ・原文が手元のメモだけに残り、検証できない
4. **検証の再現性**: 手順がなければ、次の人が同じテストを再現できない

したがって、**変更→根拠→検証** のフローを統一し、全員が従う governance を確立する。

## 決定

以下を本リポジトリの **SSOT運用ガバナンス** として定める：

### 1. 変更手順（MUST）
仕様・運用を変更する場合、**必ず以下の順序** で実施する：

1. **decisions/** に ADR を追加（変更理由・選択肢・影響範囲を明記）
2. ADR が承認されたら、**docs/** の該当 Part を更新
3. **checks/** の検証手順を実行し、矛盾がないことを確認
4. **FACTS_LEDGER.md** に変更履歴を記録（任意だが推奨）

**違反例（禁止）**:
- ADR を書かずに docs/ を直接変更
- 変更理由を口頭・チャットだけで済ます
- 検証を省略して push

### 2. 用語管理（MUST）
新しい概念・略語・専門用語が登場したら：

1. **glossary/** に用語を追加（定義・類義語・参照Partを明記）
2. docs/ では **必ず glossary/ の表記に統一**
3. 揺れを発見したら即座に glossary/ を確認し修正

**命名規則**:
- ファイル名: `GLOSSARY.md`（単一ファイル、増えたらトピック別に分割可）
- 形式: `## 用語名 \n 定義・参照Part・類義語`

### 3. 根拠の保存（SHOULD）
重要な断定（MUST/MUST NOT）には **必ず根拠** を付ける：

1. **sources/** に原文・ログ・スクショ・会話履歴を保存
2. docs/ からは `[根拠](../sources/xxx.md)` で参照
3. sources/ 内のファイルは **改変・削除禁止**（材料であり本文ではない）

**命名規則**:
- `sources/生データ/` : 生ログ・スクショ
- `sources/_MANIFEST_SOURCES.md` : 索引（任意）
- ファイル名: `YYYYMMDD_topic.md` 推奨

### 4. 検証手順（SHOULD）
再現可能な形で検証を記録する：

1. **checks/** に検証スクリプト or 手順を追加
2. 最低限、以下をカバー：
   - リンク切れ（docs内の参照パス）
   - 用語揺れ（glossary/ との一致）
   - 未決事項の残存一覧
   - Part間の衝突（Part00/09/10/14）
3. 実行結果は `evidence/verify_reports/` に保存（推奨）

**命名規則**:
- `checks/check_*.sh` or `checks/check_*.md`（手順書）
- 自動化は任意（最初は手動でOK）

## 選択肢

### 案A（採用）: 4フォルダ分離（decisions/glossary/sources/checks）
- **メリット**: 役割が明確、検索しやすい、権限分離（例: sources/ は読取専用）
- **デメリット**: フォルダが増える、初期セットアップが必要

### 案B: 全部 docs/ に統合
- **メリット**: シンプル
- **デメリット**: 材料（sources）と本文（docs）が混在し、誤って改変されるリスク大

### 案C: evidence/ に統合
- **メリット**: 検証結果と根拠を一箇所に
- **デメリット**: 変更履歴（decisions）が埋もれる、ガバナンスが不明瞭

**結論**: 案A を採用。役割分離により SSOT の破壊を防ぐ。

## 影響範囲

### 互換/移行
- 既存の docs/ には影響なし（追加のみ）
- 今後の変更は **必ず ADR 先行**

### セキュリティ/権限
- sources/ は **読取専用** として扱う（Part09 Permission Tier に記載）
- decisions/ の ADR は **承認フロー必須**（誰が承認するかは Part09 で定義）

### Verify/Evidence/Release への影響
- checks/ の検証が通らなければ release 禁止（Part14 で強制）
- evidence/ に検証結果を蓄積し、監査証跡とする

## 実行計画

### 手順
1. ✅ decisions/, glossary/, sources/, checks/ を作成（完了）
2. ✅ 本ADR（0001）を追加（本ファイル）
3. 🔲 各フォルダに README.md を追加（目的・運用ルール・命名規則）
4. 🔲 docs/00_INDEX.md に「Repo Navigation」セクションを実リンク化
5. 🔲 CLAUDE.md に本ADRへの参照を追加（任意）

### ロールバック
- 本ADRを廃止（状態: 廃止）し、decisions/0002-revert-governance.md を追加
- フォルダは削除せず、運用ルールのみ無効化

### 検証（Verify Gate）
- [ ] docs/00_INDEX.md のリンクが全て有効
- [ ] README.md が4フォルダに存在
- [ ] 本ADRが decisions/ にコミット済み
- [ ] git status が clean

## 結果
（後日記入: 運用開始後、どう機能したか、改善点）

---

## チェックリスト
- [x] ADR を decisions/ に配置
- [ ] 各フォルダに README.md を配置
- [ ] docs/00_INDEX.md にリンクを追加
- [ ] 検証手順を checks/ に追加（未来タスク）

## 未決事項
- decisions/ の承認フロー（誰が承認？自動マージ？）→ Part09 で定義
- checks/ の自動化（CI連携）→ 初期は手動、後日 ADR で決定

## 参照
- [CLAUDE.md](../CLAUDE.md) : 破壊防止の絶対ルール
- [docs/00_INDEX.md](../docs/00_INDEX.md) : SSOT エントリポイント
- [decisions/ADR_TEMPLATE.md](ADR_TEMPLATE.md) : ADR の書き方
