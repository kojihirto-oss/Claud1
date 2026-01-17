# Part 00：ドキュメント憲法・読み方・運用の前提固定（SSOT/禁止事項/改版規約/優先順位）

## 0. このPartの位置づけ
- **目的**: 本リポジトリにおける「真実の定義」「変更手順」「禁止事項」を明文化し、SSOT破壊を防ぐ。
- **依存**: なし（全Partの基盤）
- **影響**: 全Part（00〜20）、decisions/、glossary/、sources/、checks/、evidence/

---

## 1. 目的（Purpose）

本 Part00 は **SSOT（Single Source of Truth）運用の憲法** として、以下を保証する：

1. **真実の優先順位（Truth Order）を固定**し、矛盾時の裁定ルールを明確化する
2. **変更手順（ADR→docs）を強制**し、根拠のない改変を防ぐ
3. **禁止事項リスト**を明文化し、事故を未然防止する
4. **推測禁止・未決事項ルール**により、曖昧さを排除する
5. **検証・証跡・復元**の義務を明確にし、再現性を担保する

**根拠**: [FACTS_LEDGER F-0001](FACTS_LEDGER.md)（真実の優先順位）、[F-0002](FACTS_LEDGER.md)（禁止事項）、[F-0020](FACTS_LEDGER.md)（プロジェクト目的）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 本リポジトリ内の全ファイル（docs/, decisions/, glossary/, sources/, checks/, evidence/）
- AI（Claude Code, ChatGPT, Gemini, Z.ai）によるファイル操作
- 人間による手動変更（HumanGate含む）

### Out of Scope（適用外）
- 外部ドキュメント（Google Docs, Notion, Slack等）は SSOT ではない（参照元として sources/ に保存する）
- 個人の作業メモ・下書き（公式化する前に docs/ へ移す）

---

## 3. 前提（Assumptions）

1. **docs/ が唯一のSSOT**である。sources/ は材料であり、本文ではない。
2. **Git管理下**にあり、変更履歴が追跡可能である。
3. **ADR（Architecture Decision Record）が変更の正当性**を保証する。
4. **Verify/Evidence** なき変更は「存在しない」と見なす。
5. 本Part00 は **最優先で読まれるべき** であり、他のPartと矛盾した場合は Part00 が優先される。

**根拠**: [ADR-0001](../decisions/0001-ssot-governance.md)（SSOT運用ガバナンス）、[FACTS_LEDGER F-0004](FACTS_LEDGER.md)（フォルダ構造）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語は以下を参照：

- **SSOT**: [glossary/GLOSSARY.md#SSOT](../glossary/GLOSSARY.md)（唯一の正本）
- **ADR**: [glossary/GLOSSARY.md#ADR](../glossary/GLOSSARY.md)（Architecture Decision Record）
- **Verify**: [glossary/GLOSSARY.md#Verify](../glossary/GLOSSARY.md)（機械判定可能な検証）
- **Evidence**: [glossary/GLOSSARY.md#Evidence](../glossary/GLOSSARY.md)（証跡・監査ログ）
- **Release**: [glossary/GLOSSARY.md#Release](../glossary/GLOSSARY.md)（不変の成果物）
- **DoD**: [glossary/GLOSSARY.md#DoD](../glossary/GLOSSARY.md)（Definition of Done）
- **Permission Tier**: [glossary/GLOSSARY.md#Permission-Tier](../glossary/GLOSSARY.md)（AI権限階層）
- **HumanGate**: [glossary/GLOSSARY.md#Permission-Tier](../glossary/GLOSSARY.md)（人間承認が必須の操作）

用語の詳細定義・境界・禁止表記は **glossary/GLOSSARY.md** を参照。
用語管理の運用ルールは **[Part02](Part02.md)** を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-0001: 真実の優先順位（Truth Order）【MUST】
矛盾が発生した場合、以下の順序で裁定する：

1. **SSOT（docs/）** — 本書/運用法規が最上位
2. **Verify（checks/）** — 機械判定：テスト・静的解析・整合性検査
3. **Evidence（evidence/）** — 証跡：ログ・差分・manifest・sha256
4. **Release（RELEASE/）** — 固定成果物：凍結された成果物
5. **会話・感想・推測** — 最下位（必ずVerify/Evidenceに昇格させる）

**根拠**: [FACTS_LEDGER F-0001](FACTS_LEDGER.md)
**違反例**: 「Claude Codeが言ったから正しい」→ 必ずVerifyで検証し、Evidenceに記録する。

---

### R-0002: 変更手順の固定（ADR→docs）【MUST】
仕様・運用を変更する場合、**必ず以下の順序** で実施する：

1. **decisions/** に ADR を追加（変更理由・選択肢・影響範囲を明記）
2. ADR が承認されたら、**docs/** の該当 Part を更新
3. **checks/** の検証手順を実行し、矛盾がないことを確認
4. **FACTS_LEDGER.md** に変更履歴を記録（任意だが推奨）

**根拠**: [ADR-0001 第1条](../decisions/0001-ssot-governance.md)、[FACTS_LEDGER F-0003](FACTS_LEDGER.md)
**違反例（禁止）**:
- ADR を書かずに docs/ を直接変更
- 変更理由を口頭・チャットだけで済ます
- 検証を省略して commit/push

---

### R-0003: sources/ の改変・削除禁止【MUST NOT】
**sources/** 内のファイルは **改変・上書き・削除禁止**（追記のみ許可）。

**理由**: sources/ は「事実の記録」であり、後から手を加えると証拠能力が失われる。
**根拠**: [ADR-0001 第3条](../decisions/0001-ssot-governance.md)、[ADR-0003](../decisions/0003-sources-duplicate-handling.md)（重複ファイル扱い）

**例外**:
- 新規ファイルの追加（Append-only）は可
- ファイル名の修正は _MANIFEST_SOURCES.md に記録すれば可
- research_inbox 運用で `10_raw/` から `20_curated/` へコピーすることは可（10_raw は保持する）

**違反例（禁止）**:
- sources/ 内のファイルを直接編集
- 重複ファイルを削除（ADR-0003で明示的に禁止）

---

### R-0004: 推測禁止・未決事項ルール【MUST】
不明点・曖昧点は **推測で埋めない**。必ず以下のいずれかに落とす：

1. **未決事項**（各Partの「11. 未決事項」に記載）
2. **FACTS_LEDGER の未決セクション**（U-XXXX）に登録
3. **ADR で決定を明文化**してから本文へ反映

**根拠**: [FACTS_LEDGER F-0002](FACTS_LEDGER.md)、[CLAUDE.md](../CLAUDE.md)
**違反例**: 「たぶんこうだろう」→ 必ず「未決事項」に記載し、後から確定情報で置き換える。

---

### R-0005: evidence/ 保存義務【MUST】
以下は **必ず evidence/ に保存**する（削除禁止）：

- Verify の実行結果（成功・失敗問わず）
- 変更前後の diff
- コマンド実行ログ
- manifest/sha256
- ロールバック手順

**理由**: 過去の検証結果を削除すると、「なぜこの変更が承認されたか」が追跡不能になる。
**根拠**: [FACTS_LEDGER F-0006](FACTS_LEDGER.md)（不変リリース）、[ADR-0001 第3条](../decisions/0001-ssot-governance.md)

**命名規則**: `evidence/verify_reports/YYYYMMDD_HHMMSS_<check_name>.md`

---

### R-0006: 禁止事項リスト【MUST NOT】
以下の行為は **原則禁止**。例外は HumanGate（人間承認）必須：

1. **仕様凍結前に実装を開始しない**（例外: SPIKEは隔離）
2. **Verifyを通していない変更をReleaseに入れない**
3. **証跡のない成功を成功と見なさない**（再現性必須）
4. **無言でファイル/フォルダ/名前を変えない**（変更理由・影響・ロールバック手順をEvidenceに残す）
5. **AIに削除・整理・大掃除を丸投げしない**（Dry-run→レビュー→実行→Verify）
6. **巨大な置換・削除を一発実行しない**（最小差分・段階実行・Verify必須）
7. **docs/00_INDEX.md のリンク導線を壊さない**（追加はOK、削除・変更は要ADR）

**根拠**: [FACTS_LEDGER F-0002](FACTS_LEDGER.md)、[F-0031](FACTS_LEDGER.md)（破壊操作の扱い）、[F-0032](FACTS_LEDGER.md)（仕様凍結前の実装禁止）

**違反例**:
- `rm -r -f sources/` を実行
- Part番号・ファイル名を無断で変更（参照が全壊する）
- テストを書かずに「動いた」と報告

---

### R-0007: Part番号・ファイル名の変更禁止【MUST NOT】
**Part00〜Part20 のファイル名は変更禁止**。

**理由**: Part番号は `docs/00_INDEX.md`, `FACTS_LEDGER.md`, `decisions/*.md` 等、リポジトリの広範囲から参照される不変の識別子であるため。ファイル名を変更すると、これらの参照がすべてリンク切れとなり、仕様の追跡可能性が失われる。
**根拠**: [CLAUDE.md](../CLAUDE.md)

**例外**: 新規Part追加（Part21以降）は可。ただし 00_INDEX.md への追記が必須。

---

### R-0008: 用語の統一【MUST】
新しい概念・略語・専門用語が登場したら：

1. **glossary/GLOSSARY.md** に用語を追加（定義・類義語・参照Partを明記）
2. **docs/ では必ず glossary/ の表記に統一**
3. 揺れを発見したら即座に glossary/ を確認し修正

**根拠**: [ADR-0001 第2条](../decisions/0001-ssot-governance.md)、[ADR-0002](../decisions/0002-glossary-part02-separation.md)（用語管理）
**詳細**: [Part02](Part02.md)（用語運用ルール）

---

### R-0009: 失敗定義（Failure）【MUST NOT】
以下の状態は **失敗** と見なす：

- Verifyに失敗したまま「次へ進む」
- Evidenceが残っていない
- 変更理由が説明できない（誰がなぜ何をしたか不明）
- 「後で直す」タスクが増殖して収束しない（VRループが回っていない）
- 依存や環境差で再現できない

**根拠**: [FACTS_LEDGER F-0030](FACTS_LEDGER.md)
**対処**: Part10（Verify Gate）、Part14（変更管理）を参照。

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: 本リポジトリを初めて読む場合
1. [docs/README.md](README.md) を読み、リポジトリの全体像を把握する
2. [docs/00_INDEX.md](00_INDEX.md) を読み、Part00〜20 の導線を確認する
3. **本Part00** を読み、運用ルール・禁止事項を理解する
4. [FACTS_LEDGER.md](FACTS_LEDGER.md) を読み、確定情報（F-XXXX）と未決事項（U-XXXX）を把握する
5. [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を読み、用語の定義を確認する
6. Part01 から順に読む（Part01: 目標、Part02: 用語、Part04: 作業管理、...）

### 手順B: 仕様・運用を変更する場合
1. **decisions/** に ADR を追加（テンプレートは `decisions/0001-ssot-governance.md` を参照）
2. ADR に以下を必ず記載：
   - 背景（なぜ変更が必要か）
   - 決定内容
   - 選択肢（案A/案B/案C）と採用理由
   - 影響範囲（互換性・セキュリティ・Verify/Evidence/Release）
   - 実行計画（手順・ロールバック・検証方法）
3. ADR を commit（メッセージ: `Add ADR-XXXX: <タイトル>`）
4. **docs/** の該当 Part を更新（ADR への参照を必ず含める）
5. **checks/** の検証手順を実行（リンク切れ・用語揺れ・未決事項検出）
6. 検証結果を **evidence/verify_reports/** に保存
7. 全て Green なら commit/push（メッセージ: `Update PartXX based on ADR-XXXX`）

### 手順C: 新しい用語を追加する場合
1. **glossary/GLOSSARY.md** に用語を追加（定義・境界・参照・類義語・禁止表記を必ず記載）
2. 変更は軽微なので ADR 不要（ただし、重要な用語の場合は ADR 推奨）
3. docs/ から glossary/ へのリンクを追加
4. commit（メッセージ: `Add term: <用語名> to glossary`）

詳細は [Part02](Part02.md)（用語運用ルール）を参照。

### 手順D: 禁止操作を実行する必要がある場合（HumanGate）
1. **実行前に必ず ADR を作成**し、理由・影響範囲・ロールバック手順を明記
2. Dry-run モードで影響範囲を確認（例: `git rm --dry-run`, `mv --dry-run` 相当）
3. 人間（HumanGate）が承認
4. 実行前に **バックアップ**（`_TRASH/YYYYMMDD_HHMMSS/` へ退避）
5. 実行
6. Verify を実行し、破壊がないことを確認
7. Evidence に「実行前後の状態」を保存

詳細は [Part09](Part09.md)（Permission Tier）を参照。

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: ADR を書かずに緊急変更が必要な場合
**対処**:
1. 緊急パッチを別ブランチで実施
2. Verify を通す
3. **変更後すぐに ADR を追記**（事後ADR）
4. 次回同様の緊急事態が発生した場合のルールを ADR に明記

**エスカレーション**: 緊急変更が頻発する場合、Part14（変更管理）の見直しを検討。

---

### 例外2: sources/ の削除が必要な場合（機密情報混入等）
**対処**:
1. **ADR を作成**（削除理由・影響範囲・復元不能性を明記）
2. 削除前に **バックアップ**（別途暗号化保管）
3. Git履歴からも削除（`git filter-repo` 等）
4. Evidence に「削除の経緯・承認者・タイムスタンプ」を記録

**エスカレーション**: Part09（Permission Tier）で HumanGate 必須。

---

### 例外3: Verify が通らない場合
**対処**:
1. **VRループ（Verify-Repair Loop）**を回す：
   - Verify 実行 → 失敗箇所を特定 → 修正 → Verify 再実行
2. 3回ループしても通らない場合、ADR で「一時的に Verify を緩和」を決定
3. 緩和条件（期限・後続タスク）を明記

**エスカレーション**: Part10（Verify Gate）を参照。

---

### 例外4: 推測が不可避な場合
**対処**:
1. 「11. 未決事項」に記載し、**明示的に推測であることを明記**
2. 例: `U-XXXX: XXXは不明（推測: YYYと思われるが、要確認）`
3. 後日、確定情報で置き換える

**禁止**: 推測を断定として記述する（「〜である」ではなく「〜と思われる（要確認）」）。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-0001: リンク切れ検出
**判定条件**: docs/ 内の全 `[00_INDEX](00_INDEX.md)` リンクが実在するファイルを参照しているか
**合否**: 1つでも切れていたら Fail
**実行方法**: `checks/verify_repo.ps1` の `Test-Links` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_link_check.md`

---

### V-0002: Part00〜20 の存在確認
**判定条件**: `docs/Part00.md` 〜 `docs/Part20.md` が全て存在するか
**合否**: 1つでも欠けていたら Fail
**実行方法**: `checks/verify_repo.ps1` の `Test-PartsExist` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_parts_integrity.md`

---

### V-0003: 禁止コマンド検出
**判定条件**: docs/ に `rm -r -f`, `git push --for ce`, `curl ｜ sh` 等の禁止コマンドが記載されていないか
**合否**: 1つでも検出されたら Fail
**実行方法**: `checks/verify_repo.ps1` の `Test-ForbiddenCommands` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_forbidden_check.md`

---

### V-0004: sources/ の改変検出
**判定条件**: sources/ 内のファイルが commit 間で変更されていないか（追加のみOK）
**合否**: 既存ファイルが変更されていたら Fail
**実行方法**: `git diff HEAD~1 HEAD -- sources/` でファイル変更を検出
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_sources_integrity.md`

---

### V-0005: 未決事項の可視化
**判定条件**: 各Part の「11. 未決事項」に項目があるか、空か
**合否**: 未決事項が存在しても Fail ではない（警告のみ）
**実行方法**: `checks/verify_repo.ps1` の `Test-UndecidedItems` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_undecided.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-0001: 変更履歴（Git commit log）
**保存内容**: commit メッセージ、変更ファイル一覧、diff
**参照パス**: `git log --oneline --all`、`git diff <commit>`
**保存場所**: Git履歴（リモートリポジトリに push されていることを確認）

---

### E-0002: ADR（意思決定ログ）
**保存内容**: 変更理由、選択肢、影響範囲、実行計画
**参照パス**: `decisions/XXXX-*.md`
**保存場所**: `decisions/` フォルダ（Git管理下）

---

### E-0003: Verify実行結果
**保存内容**: Verify の成功・失敗ログ、実行日時、実行者
**参照パス**: `evidence/verify_reports/YYYYMMDD_HHMMSS_*.md`
**保存場所**: `evidence/verify_reports/`（削除禁止）

---

### E-0004: sources/ 原文
**保存内容**: 原文・ログ・スクショ・会話履歴
**参照パス**: `sources/生データ/*.md`、`sources/_MANIFEST_SOURCES.md`
**保存場所**: `sources/`（改変・削除禁止）

---

### E-0005: 用語定義の変更履歴
**保存内容**: glossary/GLOSSARY.md の変更履歴
**参照パス**: `git log -- glossary/GLOSSARY.md`、`git diff <commit> -- glossary/GLOSSARY.md`
**保存場所**: Git履歴

---

## 10. チェックリスト

- [x] 本Part00 が全12セクション（0〜12）を満たしているか
- [x] Truth Order（R-0001）が明記されているか
- [x] ADR→docs 方向固定（R-0002）が明記されているか
- [x] sources/ の改変・削除禁止（R-0003）が明記されているか
- [x] 推測禁止・未決事項ルール（R-0004）が明記されているか
- [x] evidence/ 保存義務（R-0005）が明記されているか
- [x] 禁止事項リスト（R-0006）が明記されているか
- [x] Part番号・ファイル名変更禁止（R-0007）が明記されているか
- [x] 用語統一ルール（R-0008）が明記されているか
- [x] 失敗定義（R-0009）が明記されているか
- [x] 各ルールに FACTS_LEDGER または ADR への参照が付いているか
- [x] Verify観点（V-0001〜V-0005）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-0001〜E-0005）が参照パス付きで記述されているか
- [ ] checks/verify_repo.ps1 が実装されているか（次タスク）
- [ ] 本Part00 を読んだ人が「何をしてはいけないか」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-0001: ADR承認フロー
**問題**: ADR を「誰が」「どのタイミングで」承認するか不明。
**影響Part**: Part09（Permission Tier）、Part14（変更管理）
**暫定対応**: 初期は commit した時点で承認とみなす。

---

### U-0002: sources/ の保存期限
**問題**: sources/ をいつまで保存するか不明（ディスク容量上限）。
**影響Part**: Part14（変更管理）
**暫定対応**: 無期限保存（削除禁止）。容量不足時にADRで決定。

---

### U-0003: 機密情報の扱い
**問題**: sources/ に機密情報（API鍵、パスワード等）を含めてよいか不明。
**影響Part**: Part09（Permission Tier）
**暫定対応**: 機密情報は sources/ に含めない。別途暗号化保管。

---

### U-0004: Verify の自動実行タイミング
**問題**: Verify を「commit前」「push前」「CI/CD」のいつ実行するか不明。
**影響Part**: Part10（Verify Gate）
**暫定対応**: 手動実行（`checks/verify_repo.ps1` を明示的に実行）。

---

## 12. 参照（パス）

### docs/
- [docs/README.md](README.md) : リポジトリ全体の導線
- [docs/00_INDEX.md](00_INDEX.md) : Part00〜20 へのリンク
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-XXXX）と未決事項（U-XXXX）
- [docs/Part02.md](Part02.md) : 用語運用ルール
- [docs/Part09.md](Part09.md) : Permission Tier（AI権限管理）
- [docs/Part10.md](Part10.md) : Verify Gate（検証手順）
- [docs/Part14.md](Part14.md) : 変更管理（ADR/RFC/PATCHSET）

### SSOT・設計管理一次情報
- [Single Source of Truth (SSOT) Pattern](https://martinfowler.com/bliki/SingleSourceOfTruth.html) : SSOTパターン（Martin Fowler）
- [Documentation as Code](https://www.writethedocs.org/blog/docs-as-code/) : ドキュメント_as_Code
- [Architectural Decision Records](https://adr.github.io/) : ADR公式ガイドライン

### sources/
- [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md) : 原文（43,822行）
- [sources/_MANIFEST_SOURCES.md](../sources/_MANIFEST_SOURCES.md) : 正本（Canonical）明記

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス
- [decisions/0002-glossary-part02-separation.md](../decisions/0002-glossary-part02-separation.md) : 用語管理の役割分離
- [decisions/0003-sources-duplicate-handling.md](../decisions/0003-sources-duplicate-handling.md) : sources/ 重複ファイル扱い

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義
- [glossary/README.md](../glossary/README.md) : 用語管理の運用ルール

### checks/
- `checks/verify_repo.ps1` : リポジトリ検証スクリプト（次タスクで作成予定）

### evidence/
- [evidence/verify_reports/README.md](../evidence/verify_reports/README.md) : 検証レポートの命名規則

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール（最上位）
