# Part 02：共通語彙（用語固定で迷いを消す：SSOT/VAULT/RELEASE/DoD/ADR/Permission Tier等）

## 0. このPartの位置づけ
- **目的**: 全設計書で使う用語の唯一定義を提供し、表記揺れ・解釈ブレを排除する
- **依存**: decisions/ADR-0001, ADR-0002（ガバナンス基盤）
- **影響**: Part00～Part20 全体（用語統一の基準）

## 1. 目的（Purpose）
このPartは **用語集（Glossary）** として機能し、以下を達成する：
1. **表記統一**: 同じ概念に対して複数の呼び方をしない（例: "チケット" = "TICKET", "証跡" = "Evidence"）
2. **意味固定**: 用語の定義を一箇所に集約し、誰が読んでも同じ判断ができる
3. **迷い排除**: 「これは何を指すのか？」という疑問を設計書執筆時・運用時に発生させない

## 2. 適用範囲（Scope / Out of Scope）

### Scope（対象）
- docs/ 配下の全Part（Part00～Part20）で使う用語
- decisions/ 配下のADRで使う用語
- checks/ のVerify手順、evidence/ のレポートで使う用語

### Out of Scope（対象外）
- プロジェクト固有の技術用語（例: 特定ライブラリのAPI名）は glossary/GLOSSARY.md で管理
- 業界一般用語（例: "git", "Docker"）は定義不要

## 3. 前提（Assumptions）
- 用語追加時は **glossary/GLOSSARY.md** にも同期する（二重管理を避けるため、Part02は概要、glossary/は詳細と使い分け）
- 定義変更時は必ず **decisions/ にADR追加** → Part02更新の順を守る（ADR-0001ルール）

## 4. 用語（Glossary）

### 4.1 フォルダ構造関連

#### SSOT (Single Source of Truth)
- **定義**: 唯一の正本。このリポジトリでは **docs/** が仕様・運用のSSOT。
- **ルール**: docs/ 以外（sources/, evidence/, checks/）は参照・根拠・検証用であり、本文ではない。
- **根拠**: decisions/ADR-0001

#### sources/
- **定義**: 原文・一次情報・ログの保管庫。改変・上書き・削除は **禁止**（追記のみ許可）。
- **目的**: 設計書の根拠を保全し、証跡の信頼性を守る。
- **例外**: HumanGate承認の下での意図的削除のみ（ADRに理由記録必須）。
- **根拠**: decisions/ADR-0002

#### evidence/
- **定義**: 検証結果・証跡の保管庫。
- **サブフォルダ**:
  - `evidence/verify_reports/`: Verify結果（TICKET.md, CONTEXT_PACK.md, VERIFY_REPORT.md, EVIDENCE.md の4点セット）
  - `evidence/research/`: 外部調査結果（URL、確認日、スクリーンショット等）
- **根拠**: decisions/ADR-0002

#### decisions/
- **定義**: ADR（Architecture Decision Record）の保管庫。仕様・運用の変更は必ず先にADRを追加してから docs/ を変更する。
- **ルール**: ADR → docs の順序を守る（逆は禁止）。
- **根拠**: decisions/ADR-0001

### 4.2 タスクサイズ（S/M/L）

#### タスクサイズ S
- **定義**: 30分〜2時間で完了する小規模作業。
- **Verify**: Fast のみ（重要箇所なら Full へ昇格可）
- **文章**: TICKET.md に全て内包（4点セット不要、簡易記録でOK）
- **推奨ツール**: Lite運用、手順簡略化
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

#### タスクサイズ M
- **定義**: 半日〜2日で完了する標準作業。
- **Verify**: Fast → Full（原則）
- **Evidence**: 必須4点セット（TICKET.md, CONTEXT_PACK.md, VERIFY_REPORT.md, EVIDENCE.md）
- **推奨ツール**: 標準フロー
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

#### タスクサイズ L
- **定義**: 移行・広域変更・高リスク作業。
- **Verify**: Lite を捨てて Full 必須
- **条件**: 例外ルート条件を満たす（ロールバック計画明記 + サンドボックス + HumanGate承認）
- **Evidence**: Release前提（スナップショットRAG更新もここだけ）
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

### 4.3 Permission Tier（権限レベル）

#### Permission Tier
- **定義**: AIに渡す権限レベル。4段階で固定。
- **レベル**:
  1. **ReadOnly**: 読み取りのみ（調査・分析）
  2. **PatchOnly**: ファイル編集のみ（コード変更、ドキュメント追記）
  3. **ExecLimited**: 限定的な実行（lint, test, build など非破壊コマンド）
  4. **HumanGate**: 破壊的操作・全域変更・リリース確定（人間の承認必須）
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

#### HumanGate
- **定義**: Permission Tierの最上位。**破壊的操作・全域変更・リリース確定など、人間の明示的承認が必須**の操作レベル。
- **対象操作**:
  - 破壊コマンド: `rm -rf`, `git push --force`, `git reset --hard`, `curl | sh`
  - 全域変更: sources/の削除・上書き、VAULT/RELEASE直接編集、API破壊的変更
  - リリース確定: Production deploy, スナップショットRAG更新
- **承認フロー**: 2段階承認（提案→レビュー→承認）、緊急時は事後承認可（24時間以内に記録）
- **例外**: なし（HumanGateを超える権限は存在しない）
- **根拠**: decisions/ADR-0002

### 4.4 Verify（検証）関連

#### Verify Gate
- **定義**: 機械判定による品質ゲート。Fast/Full の2段階で固定。
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

#### Fast Verify
- **定義**: 最短で壊れを検出する軽量検証（lint + unit + 型/静的解析の一部）。
- **目的**: 高速フィードバック（数秒〜数分）。
- **使用場面**: Sサイズタスク、M/Lタスクの初期確認。
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

#### Full Verify
- **定義**: CI相当の全検査（integration/e2e + security + SBOM + 再現実行）。
- **目的**: 本番相当の品質保証。
- **使用場面**: Mサイズ以上、高リスク変更、Release前。
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

#### VERIFY_REPORT
- **定義**: Verify実行結果のレポート（VERIFY_REPORT.md）。
- **必須項目**: 実行コマンド、成否、失敗ログ抜粋、参照ログパス、主要メトリクス。
- **保存先**: evidence/verify_reports/
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

### 4.5 Evidence（証跡）関連

#### Evidence Pack
- **定義**: 検証・監査に必要な証跡一式。
- **必須4点セット**（Mサイズ以上）:
  1. **TICKET.md**: 起票＋仕様凍結＋リスク＋ロールバックまで1枚に統合
  2. **CONTEXT_PACK.md**: AI用コンテキスト（Z.ai生成推奨、固定フォーマット）
  3. **VERIFY_REPORT.md**: CIログ＋合否判定＋再発防止
  4. **EVIDENCE.md**: 何を/なぜ/どう検証/学び（後日参照用）
- **保存先**: evidence/verify_reports/
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt, decisions/ADR-0002

### 4.6 その他重要用語

#### DoD (Definition of Done)
- **定義**: タスク完了の定義。以下を全て満たす：
  1. Verify PASS（Fast or Full、サイズに応じて）
  2. Evidence収集完了（4点セット、Mサイズ以上）
  3. docs/ 更新（該当する場合）
  4. ADR追加（仕様変更の場合）

#### ADR (Architecture Decision Record)
- **定義**: 設計・運用の意思決定記録。
- **ルール**: 仕様変更は必ず ADR → docs の順で実施（逆は禁止）。
- **フォーマット**: decisions/ADR_TEMPLATE.md 参照
- **根拠**: decisions/ADR-0001

#### RAG (Retrieval-Augmented Generation)
- **定義**: AI用のコンテキスト検索インデックス。
- **保存先**: `.rag/` （.gitignore対象、git管理外）
- **スナップショット**: Release時のみ `.rag-snapshot-YYYYMMDD/` として手動保存（HumanGate）
- **再生成**: 必要時に sources/ と docs/ から再生成可能（RAGは使い捨て設計）
- **根拠**: decisions/ADR-0002

#### Context Pack
- **定義**: AIに渡す入力コンテキストの最小化セット（誤解・幻覚・暴走を防ぐ）。
- **内容**: SPEC.md（凍結版）、対象ディレクトリツリー、変更対象ファイル抜粋、直近VERIFY_REPORT.md、関連ADR、依存関係情報。
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt

## 5. ルール（MUST / MUST NOT / SHOULD）

### 用語使用ルール
1. **MUST**: 設計書（docs/）では **Part02定義の用語のみ** 使用する。独自用語・表記揺れは禁止。
2. **MUST**: 用語追加時は **glossary/GLOSSARY.md** にも同期する。
3. **MUST**: 定義変更時は **先にADR追加** → Part02更新の順を守る。
4. **SHOULD**: 不明な用語に遭遇した場合、推測せず「未決事項」に記録し、ADRで定義する。

### 推測禁止ルール
1. **MUST NOT**: 定義が不明瞭な用語を推測で使わない。
2. **MUST**: 不明点は「未決事項」に送り、ADRで裁定してから本文へ反映する。
3. **手順**: Part11（未決事項）参照

## 6. 手順（実行可能な粒度、番号付き）

### 新規用語追加の手順
1. **未決事項に記録**: 該当Partの「11. 未決事項」セクションに追記
2. **ADR起票**: decisions/ に新規ADR作成（ADR_TEMPLATE.md使用）
3. **定義確定**: ADRで用語の定義・使用範囲・根拠を明記
4. **Part02更新**: ADR承認後、このPart02に用語追加
5. **glossary/同期**: glossary/GLOSSARY.md にも同じ定義を追加
6. **Verify実行**: Fast Verify でリンク切れ・矛盾チェック

### 既存用語の定義変更手順
1. **ADR起票**: 変更理由・影響範囲を明記
2. **影響調査**: 該当用語が使われている全Partをgrep検索
3. **Part02更新**: ADR承認後、定義を更新
4. **影響Part更新**: 該当する他のPartも一括更新
5. **Verify実行**: Full Verify で整合性確認

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 用語の表記揺れ発見時
1. **発見**: Verify時、または設計書レビュー時に表記揺れを検出
2. **修正**: 該当Partを Part02定義に統一（単純な表記ミスなら即修正可）
3. **ADR要否判断**: 意味的な定義変更なら ADR起票

### 定義矛盾の発見時
1. **停止**: 該当Partの編集を一時停止
2. **ADR起票**: 矛盾解消の方針を決定
3. **Part02更新**: 定義を統一
4. **再開**: Verify PASS後、編集再開

### エスカレーション
- Part02の定義では解決できない矛盾 → **HumanGate** で裁定

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### Fast Verify（checks/verify_repo.ps1 -Mode Fast）
- **判定条件**:
  - Part02内のリンク切れチェック（decisions/, sources/, evidence/, glossary/ への参照）
  - 用語定義の重複チェック（同じ用語が2回定義されていないか）
- **合否**: 全項目Green → PASS
- **ログ**: evidence/verify_reports/verify_YYYYMMDD_HHMMSS.log

### Full Verify（checks/verify_repo.ps1 -Mode Full）
- **追加項目**:
  - 全Part（Part00～Part20）との用語整合性チェック
  - glossary/GLOSSARY.md との同期チェック
- **合否**: Fast + 追加項目すべてGreen → PASS

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 用語追加時のEvidence
- **ADRパス**: decisions/ADR-XXXX.md
- **根拠パス**: sources/生データ/... または evidence/research/...
- **変更diff**: git log でPart02の変更履歴

### 定義変更時のEvidence
- **ADRパス**: 変更理由を記録したADR
- **影響調査結果**: grep結果をevidence/research/に保存
- **Verify結果**: evidence/verify_reports/

## 10. チェックリスト
- [ ] Part02に記載の全用語が glossary/GLOSSARY.md と同期している
- [ ] 新規用語追加時にADRを先行作成した
- [ ] 定義変更時に影響Partをすべて更新した
- [ ] Fast Verify PASS を確認した
- [ ] リンク切れがない（decisions/, sources/, evidence/ への参照）
- [ ] 表記揺れがない（同じ概念に対して複数の表記がない）

## 11. 未決事項（推測禁止）
- （現時点でなし。今後、用語追加・変更の際にここへ記録し、ADRで裁定する）

## 12. 参照（パス）
- **ADR**: decisions/ADR-0001.md（SSOT運用ガバナンス）, decisions/ADR-0002.md（運用ガバナンス詳細）
- **用語詳細**: glossary/GLOSSARY.md
- **根拠**: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt
- **Verify手順**: checks/verify_repo.ps1
- **証跡保存先**: evidence/verify_reports/
