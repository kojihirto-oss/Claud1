# GLOSSARY（用語の唯一定義）

> この用語集が「表記」と「意味」の唯一の正です。docs/ 本文は必ずこれに従う。

**更新日**: 2026-01-09
**管理**: この用語集の追加・変更は ADR 必須（decisions/ で方針決定してから反映）
**参照**: 用語の運用ルールは [docs/Part02.md](../docs/Part02.md) を参照

---

## SSOT (Single Source of Truth)

**定義**: 唯一の正本。複数のコピーを持たず、1箇所だけを更新・参照する運用。

**境界**:
- 含む: docs/ が SSOT（仕様・運用の正本）
- 含まない: sources/ は材料であり SSOT ではない。RAG も真実ではなく、SSOT を検索するための補助。

**参照**: FACTS_LEDGER F-0001, F-0004
**関連用語**: VAULT, Release, Verify
**禁止表記**: マスターデータ、正本（「マスタ」「原本」は使わない）

---

## Verify / Verify Gate

**定義**: 機械判定による品質ゲート。テスト・静的解析・セキュリティスキャン等で合否を出す。

**境界**:
- 含む: Fast Verify（最短検出）、Full Verify（全検査）
- 含まない: 人間の目視レビューは Verify ではない（補助として併用は可）

**Fast Verify**: lint + unit + 型/静的解析の一部（最短5分以内）
**Full Verify**: CI相当の全検査（integration/e2e + security + SBOM + 再現実行）

**参照**: FACTS_LEDGER F-0021, F-0050, F-0056
**関連用語**: Evidence, VRループ, DoD
**表記規約**: 常に頭文字大文字（Verify）、動詞として使う場合も同様

---

## Evidence / Evidence Pack

**定義**: 証跡。「何を変えたか」「なぜ変えたか」「どう検証したか」を後から再現できる形で残したもの。

**必須物**:
- 仕様（SPEC.md）
- diff（patch / PRリンク）
- Verifyログ（標準出力＋要点）
- 生成物のmanifest/sha256
- 失敗時のログ（Repairの根拠）
- ロールバック手順

**保存場所**:
- `TRACE/`: タスク単位（時系列）
- `VAULT/`: リリース単位（不変）
- `RUNS/`: 実行記録（コマンドと結果）

**参照**: FACTS_LEDGER F-0001, F-0053, F-0054
**関連用語**: VAULT, Verify, Release
**禁止表記**: エビデンス（カタカナ表記は避け、Evidence と表記）

---

## Release / Immutable Release

**定義**: 不変成果物。リリースは「成果物」ではなく「証拠付きの状態」であり、生成後は編集禁止。

**命名規則**: `generated_YYYYMMDD_HHMMSS/`

**付随必須ファイル**:
- `_manifest.csv`: ファイル一覧とサイズ
- `_sha256.csv`: 全ファイルのSHA-256
- `STATUS.md`: 目的・DoD・Verify結果
- `TRACE/`: ログ・diff・コマンド履歴

**ルール**: リリース生成後に編集禁止。修正は新しいリリースで行う（READ-ONLY）。

**参照**: FACTS_LEDGER F-0006, F-0060
**関連用語**: Evidence, DoD, VAULT
**表記規約**: Immutable Release（不変リリース）として表記

---

## DoD (Definition of Done)

**定義**: 完了条件。Verifyが Green でも「Done ではない」事故を防ぐ最終条件。

**タスクDoD**:
- Spec（仕様）が凍結され、Acceptance（受入条件）が機械判定可能
- Build（実装）がSpecに一致し、差分が最小
- Verify（テスト・静的解析・スキャン）が全てGreen
- Evidence（ログ・diff・manifest・sha256・実行結果）が保存される
- Release（必要な場合）は版管理され、復元できる

**リリースDoD**:
- リリースフォルダがREAD-ONLY（改変不能）である
- バイナリ/生成物の整合性（sha256）が取れている
- SBOMが生成され、依存が追跡できる
- 主要なセキュリティスキャンが実施され、重大な問題がゼロか、例外が承認済み

**参照**: FACTS_LEDGER F-0021, F-0022
**関連用語**: Verify, Evidence, Release
**表記規約**: DoD（略語）または Definition of Done（正式名）

---

## PATCHSET

**定義**: 差分集合。コミット/パッチ/PRとして表現される最小差分。

**原則**:
- 1 PATCHSET = 1目的 = 1 Verify
- 変更単位は「最小差分」で、目的が単一であること（混ぜない）
- 大改修は分割して PATCHSET に落とす

**参照**: FACTS_LEDGER F-0003
**関連用語**: Verify, Git, worktree
**表記規約**: 全て大文字（PATCHSET）

---

## ADR (Architecture Decision Record)

**定義**: 意思決定ログ。「なぜ・いつ・どのように」決定されたかを記録する。

**必須項目**:
- 日付、状態（提案/承認/廃止）
- 影響Part
- 背景・決定・選択肢・影響範囲・実行計画

**運用ルール**: 仕様・運用を変更する場合、**必ず先に ADR を追加** してから docs を変更（ADR→docs）。

**参照**: FACTS_LEDGER F-0003, decisions/README.md
**関連用語**: SSOT, CHANGELOG
**表記規約**: ADR（略語）、ファイル名は `NNNN-topic.md`

---

## Permission Tier

**定義**: AIに渡す権限レベルを固定する仕組み。

**権限レベル**:
- **ReadOnly**: 読むだけ（解析・提案・レビュー）
- **PatchOnly**: 差分作成OK、実行は不可（PR/patch生成）
- **ExecLimited**: 許可コマンドのみ実行（tests/lint/buildなど）
- **HumanGate**: 破壊操作・全域変更・リリース確定など（人の承認必須）

**Allowlist（許可コマンド）**:
- 許可: pytest, npm test, pnpm lint, ruff, mypy, docker compose up など
- 禁止: rm -rf, git push --force, curl | sh など（HumanGateのみ）

**参照**: FACTS_LEDGER F-0055
**関連用語**: HumanGate, Agent Pack, Dry-run
**表記規約**: Permission Tier（スペースあり）、各レベルは CamelCase

---

## VIBEKANBAN

**定義**: タスク駆動の運用台帳。状態機械として INBOX→TRIAGE→SPEC→BUILD→VERIFY→REPAIR→DONE→RELEASE を回す。

**状態**:
- `INBOX`: 着想・課題・バグ・改善点（未整形でOK）
- `TRIAGE`: 目的/範囲/リスク/完了条件を最小化
- `SPEC`: 仕様凍結（受入基準・不変条件・テスト方針まで）
- `BUILD`: 最小パッチを作る
- `VERIFY`: 機械判定（Fast/Full）
- `REPAIR`: 失敗原因を分類し、収束させる
- `DONE`: DoD満たしEvidence保存済み
- `BLOCKED`: 外部依存/不明点があり停止（解除条件を明記）
- `RELEASE`: 不変成果物化（manifest/sha256/SBOM）

**参照**: FACTS_LEDGER F-0010, F-0043, F-0061
**関連用語**: SBF, PAVR, worktree
**表記規約**: 全て大文字（VIBEKANBAN）

---

## Core4

**定義**: 4つの課金AIを役割で固定する運用設計。

**役割**:
- **ChatGPT（司令塔/編集長）**: SSOT維持、設計・統合判断、レビュー設計、品質ゲート設計
- **Claude Code（実装エンジン）**: 実装・修正・テスト駆動の反復（CLI/デスクトップ）
- **Gemini / Google One Pro（調査・統合ハブ）**: 外部情報、長文理解、Google連携
- **Z.ai Lite（補助LLM/API/MCP）**: 軽量タスク、補助分析、並列ワーク

**注意**: 軽量・安価なモデルを"本流の真実"にしない。必ずVerify/Evidenceで固定する。

**参照**: FACTS_LEDGER F-0008
**関連用語**: MCP, Verify, Evidence
**表記規約**: Core4（数字含む）

---

## SBF (Spec / Build / Fix)

**定義**: 1本の仕事を最後まで通す工程の型。

**内容**:
- **S = Spec**: 設計書（PRD/DESIGN/ACCEPTANCE）を作り凍結
- **B = Build**: 凍結仕様どおりに実装を完走
- **F = Fix**: 失敗ログから直してGreenに戻す

**参照**: FACTS_LEDGER F-0044
**関連用語**: PAVR, Spec Freeze, Verify
**表記規約**: SBF（略語、全て大文字）

---

## PAVR (Prepare / Author / Verify / Repair)

**定義**: Build を成功させるための運用ループ。

**内容**:
- **P = Prepare**: 硬い基盤（環境・ルール・ツール）
- **A = Author**: 仕様を完成させて凍結（Specの完成）
- **V = Verify**: 機械判定で合否を出す
- **R = Repair**: 修正→再検証で収束（VRループ）

**参照**: FACTS_LEDGER F-0045
**関連用語**: SBF, VRループ, Verify
**表記規約**: PAVR（略語、全て大文字）

---

## VRループ (Verify-Repair Loop)

**定義**: Verify → Repair → Verify → ... を繰り返し、Greenに収束させる反復。

**失敗分類**:
- Spec系: 前提が違う／受入基準が曖昧 → GPTへ戻す
- 依存/環境系: バージョン衝突／OS差 → Docker/lock/CIで固定
- 実装系: 局所バグ → Claudeで最小修正
- テスト系: テスト不足／壊れたテスト → テストを直し、意図をSpecへ

**ループ制限**: 同じ失敗が3ループを超えたら、失敗分類を挟むかHumanGate。

**参照**: FACTS_LEDGER F-0057
**関連用語**: Verify, Repair, HumanGate
**表記規約**: VRループ（V/R大文字、ループはひらがな）

---

## VAULT

**定義**: 証跡保管庫。Append-only（追記のみ）でログ・レポート・トレースを蓄積する。

**内容**:
- `RUNLOG.jsonl`: 全実行履歴
- `VERIFY/`: Verify結果
- `EVIDENCE/`: 証跡パック
- `TRACE/`: 推論・判断・変更の因果

**ルール**: VAULT は物理的 READ-ONLY（OS権限で守る）。追記のみ許可。

**参照**: FACTS_LEDGER F-0004, F-0054
**関連用語**: Evidence, Release, TRACE
**表記規約**: 全て大文字（VAULT）

---

## Focus Pack

**定義**: タスク局所コンテキスト。このタスクに必要な最小コンテキストを毎タスク必ず作る。

**内容**:
- `FOCUS.md`: ゴール、前提、禁止、受入条件
- `SCOPE.tree`: 関係フォルダ/ファイル一覧
- `DIFF_POLICY.md`: 変更最小ルール
- `VERIFY.md`: 実行コマンド

**参照**: FACTS_LEDGER F-0047
**関連用語**: Agent Pack, Context Pack, RAG
**表記規約**: Focus Pack（スペースあり）

---

## RAG (Retrieval-Augmented Generation)

**定義**: 検索拡張生成。LLM に外部知識（SSOT全文、フォルダ索引、コマンド索引等）を検索させて回答精度を上げる仕組み。

**最小RAG（Minimum Viable RAG）**:
- SSOT全文
- フォルダ索引（tree/manifest）
- コマンド索引（verify/build/release）
- 既知の障害と対処（Runbook）

**鉄則**:
- RAGは「真実」ではない。真実はSSOT＋Verify＋Evidence
- RAG更新は必ずEvidence（差分・件数・ハッシュ）を残す

**参照**: FACTS_LEDGER F-0049
**関連用語**: SSOT, Verify, Evidence
**表記規約**: RAG（略語、全て大文字）

---

## worktree

**定義**: Git の機能。同一リポジトリを複数の作業ディレクトリに物理分離し、並列作業時の衝突を防ぐ。

**用途**:
- 個人運用: feature branch ごとに worktree を切り、物理的に隔離
- エージェント並列: タスクごとに隔離された worktree で実行（VIBEKANBAN の前提）

**参照**: FACTS_LEDGER F-0007, F-0010
**関連用語**: Git, VIBEKANBAN, PATCHSET
**表記規約**: 小文字（worktree）

---

## manifest / sha256

**定義**: ファイル一覧とハッシュ。再現性・整合性を担保するための必須データ。

**manifest**: ファイル一覧とサイズを記録した CSV/JSON
**sha256**: 各ファイルの SHA-256 ハッシュを記録した CSV

**用途**:
- Release: `_manifest.csv` と `_sha256.csv` を生成
- Verify: ハッシュ一致を検証（改ざん検出）
- Evidence: 生成物の整合性を証明

**参照**: FACTS_LEDGER F-0006, F-0053
**関連用語**: Release, Evidence, SBOM
**表記規約**: 小文字（manifest, sha256）

---

## 追加予定の用語

以下の用語は今後追加予定（優先度中〜低）:
- SBOM / Provenance
- Gitleaks / Trivy / SAST / CodeQL
- MCP (Model Context Protocol)
- Dry-run / SPIKE / Spec Freeze
- CHANGELOG / Rollback / Revert
- Trust Tier / Context Trust Tagging
- RUNLOG.jsonl / Allowlist / HumanGate
- WIP制限 / Lane（ai_ready / pdf_ocr_ready 等）
- Antigravity（IDEハブ）
- Agent Pack / Context Pack
- WORK / INBOX / TRIAGE / BLOCKED
- TRACE / RUNS
- Fast Verify / Full Verify

---

**更新履歴**:
- 2026-01-09: 初版（18用語を定義）
