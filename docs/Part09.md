# Part 09：Permission Tier（ReadOnly/PatchOnly/ExecLimited/HumanGateの権限設計）

## 0. このPartの位置づけ
- **目的**: AI に渡す権限レベルを固定し、破壊操作・事故を未然防止する。
- **依存**: [Part00](Part00.md)（禁止事項）、[Part01](Part01.md)（失敗定義）
- **影響**: 全Part（AI が実行するすべての操作）

---

## 1. 目的（Purpose）

本 Part09 は **AI権限管理（Permission Tier）** を通じて、以下を保証する：

1. **破壊操作の禁止**: `rm -r -f`, `git push --for ce`, `curl ｜ sh` 等を AI に直接生成・実行させない
2. **権限レベルの明示**: ReadOnly/PatchOnly/ExecLimited/HumanGate の4階層で固定
3. **sources/ の読取専用化**: sources/ は AI が改変・削除できない
4. **HumanGate の強制**: 破壊操作・全域変更・リリース確定は人間承認必須

**根拠**: [FACTS_LEDGER F-0055](FACTS_LEDGER.md)（Permission Tier）、[F-0031](FACTS_LEDGER.md)（破壊操作の扱い）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 本リポジトリ内での AI による全操作
- Claude Code, ChatGPT, Gemini, Z.ai 等の全 AI
- コマンド実行・ファイル操作・Git操作
- MCP (Model Context Protocol) 経由のツール実行

### Out of Scope（適用外）
- 人間の手動操作（Permission Tier は適用されない）
- 外部サービス（GitHub Actions, CI/CD）の権限管理
- 読取専用操作（解析・提案・レビュー）

---

## 3. 前提（Assumptions）

1. **AI は制約なしでは破壊的**である（意図しない削除・上書きが発生する）。
2. **Allowlist 方式**（許可リストに載ったコマンドのみ実行可能）が基本。
3. **sources/ は読取専用**である（ADR-0001 第3条）。
4. **HumanGate は最終防衛線**である（人間承認なしで破壊操作は不可）。
5. **Permission Tier は機械判定可能**である（checks/ で検証）。

**根拠**: [ADR-0001 第3条](../decisions/0001-ssot-governance.md)（sources/ 改変禁止）、[Part00 R-0006](Part00.md)（禁止事項リスト）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Permission Tier**: [glossary/GLOSSARY.md#Permission-Tier](../glossary/GLOSSARY.md)（AI権限階層）
- **HumanGate**: 人間承認が必須の操作（破壊的・不可逆・高リスク）
- **Allowlist**: 許可リスト（実行可能なコマンドの一覧）
- **MCP**: [glossary/GLOSSARY.md#MCP](../glossary/GLOSSARY.md)（Model Context Protocol）
- **Dry-run**: 実行前に影響範囲を確認するモード

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-0901: Permission Tier の4階層【MUST】
AI の権限レベルは以下の **4階層のみ** とする：

#### 1. ReadOnly（読取専用）
- **許可**: ファイル読取・解析・提案・レビュー・検索
- **禁止**: ファイル書込・コマンド実行
- **用途**: コードレビュー、設計相談、バグ調査
- **AI例**: ChatGPT（司令塔）、Gemini（調査ハブ）

#### 2. PatchOnly（差分作成のみ）
- **許可**: diff/patch 生成、PR作成
- **禁止**: ファイルへの直接書込、コマンド実行
- **用途**: PR生成、設計書の差分提案
- **AI例**: Z.ai Lite（補助LLM）

#### 3. ExecLimited（許可コマンドのみ実行）
- **許可**: Allowlist に載ったコマンドのみ（後述）
- **禁止**: Allowlist にないコマンド、破壊的操作
- **用途**: テスト実行、lint実行、ビルド実行
- **AI例**: Claude Code（実装エンジン）

#### 4. HumanGate（人間承認必須）
- **許可**: すべての操作（ただし人間承認後）
- **禁止**: 承認なしでの破壊的操作
- **用途**: 破壊操作・全域変更・リリース確定・機密情報扱い
- **AI例**: なし（人間のみ）

**根拠**: [FACTS_LEDGER F-0055](FACTS_LEDGER.md)
**違反例**: AI が `rm -r -f sources/` を直接実行 → HumanGate 必須。

---

### R-0902: Allowlist（許可コマンド）【MUST】
ExecLimited で実行可能なコマンドは以下のみ：

**許可コマンド（例）**:
- テスト: `pytest`, `npm test`, `pnpm test`, `jest`, `vitest`
- Lint: `ruff`, `mypy`, `eslint`, `prettier`, `black`, `flake8`
- ビルド: `npm run build`, `pnpm build`, `cargo build`, `go build`
- 静的解析: `bandit`, `semgrep`, `trivy`, `snyk`
- Git（読取のみ）: `git status`, `git diff`, `git log`, `git show`
- Docker（読取のみ）: `docker ps`, `docker images`, `docker compose ps`

**禁止コマンド（HumanGate 必須）**:
- 削除: `rm -r -f`, `rmdir / s / q`, `del / s / q`, `git clean -f d x`
- 強制操作: `git push --for ce`, `git push --for ce-with-lease`, `git reset --h ard`
- ネットワーク実行: `curl ｜ sh`, `eval $ (curl ...)`, `bash < (curl ...)`
- 全域変更: `find . -name "*.md" -exec rm {} \;`, 巨大な置換
- 権限変更: `chmod 7 7 7`, `chown`, `sudo`
- パッケージ操作: `pip install`, `npm install (global)`, `apt (install)`

**根拠**: [FACTS_LEDGER F-0055](FACTS_LEDGER.md)、[F-0031](FACTS_LEDGER.md)
**追加**: 新しいコマンドを許可する場合は ADR で承認。

---

### R-0903: sources/ の読取専用化【MUST】
**sources/** 内のファイルは AI が **改変・削除・上書き禁止**（読取のみ許可）。

**理由**: sources/ は「事実の記録」であり、後から手を加えると証拠能力が失われる。
**根拠**: [ADR-0001 第3条](../decisions/0001-ssot-governance.md)、[Part00 R-0003](Part00.md)

**例外**:
- 新規ファイルの追加（HumanGate 承認後）は可
- _MANIFEST_SOURCES.md の更新（HumanGate 承認後）は可

---

### R-0904: HumanGate 必須操作【MUST】
以下の操作は **必ず人間承認** を経る（AI 単独では不可）：

1. **破壊操作**: ファイル削除・フォルダ削除・Git履歴改変
2. **全域変更**: 複数ファイルへの一括置換・リファクタリング
3. **リリース確定**: Release フォルダの生成・SBOM 生成・セキュリティスキャン結果の承認
4. **機密情報扱い**: API鍵・パスワード・証明書の生成・保存・削除
5. **sources/ への操作**: 新規追加・_MANIFEST 更新

**手順**:
1. AI が操作を提案（Dry-run 結果を含む）
2. 人間が影響範囲をレビュー
3. 人間が承認（Evidence に「承認者・承認日時・理由」を記録）
4. AI が実行
5. Verify を実行し、破壊がないことを確認

**根拠**: [FACTS_LEDGER F-0031](FACTS_LEDGER.md)、[F-0055](FACTS_LEDGER.md)

---

### R-0905: Dry-run の強制【SHOULD】
破壊的操作・全域変更は **Dry-run モードで影響範囲を確認**してから実行する。

**例**:
- `git rm --dry-run sources/old_file.md`
- `find . -name "*.md" -print`（`-exec rm` の前に確認）
- `sed -n 's/old/new/gp' file.md`（`-i` の前に確認）

**理由**: Dry-run なしで実行すると、誤削除・誤上書きが発生する。

---

### R-0906: 禁止コマンドの検出【MUST】
docs/ および checks/ に禁止コマンドが記載されていないことを検証する。

**判定**: V-0901（後述）で機械判定。
**理由**: ドキュメントに禁止コマンドが記載されていると、AI がコピペして実行するリスクがある。

---

### R-0907: MCP の権限管理【SHOULD】
MCP (Model Context Protocol) 経由のツール実行は以下のルールに従う：

1. **読取系 MCP**（ファイル読取・検索・解析）は ReadOnly 扱い
2. **書込系 MCP**（ファイル書込・コマンド実行）は PatchOnly or ExecLimited 扱い
3. **破壊系 MCP**（削除・強制操作）は HumanGate 扱い
4. **監査ログ必須**: MCP 実行時は Evidence に「ツール名・入力・出力・実行日時」を記録

**根拠**: [FACTS_LEDGER F-0011](FACTS_LEDGER.md)（MCP導入方針）

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: AI に権限レベルを指定する
1. タスク（TICKET）の Risks セクションで必要な権限レベルを明記
2. 例: 「Permission: ExecLimited（テスト実行のみ）」
3. AI は指定された権限レベルの範囲内でのみ操作
4. 権限を超える操作が必要な場合、HumanGate に エスカレーション

### 手順B: HumanGate 操作の実行
1. AI が操作を提案（`## HumanGate 承認が必要です` と明記）
2. Dry-run 結果を提示（影響範囲・リスク・ロールバック手順）
3. 人間が以下を確認：
   - 操作の必要性
   - 影響範囲（どのファイル・フォルダが変更されるか）
   - ロールバック可能か
   - 代替手段はないか
4. 人間が承認（Evidence に記録）
5. AI が実行
6. Verify を実行
7. Evidence に「実行前後の状態」を保存

### 手順C: 禁止コマンドの検出
1. `checks/verify_permission.ps1` を実行
2. docs/ および checks/ 内の全ファイルをスキャン
3. 禁止コマンド（R-0902 のリスト）が記載されていないか確認
4. 検出された場合、Fail（Verify レポートに記録）

### 手順D: Allowlist の更新
1. 新しいコマンドを許可する必要がある場合、ADR を作成
2. ADR に以下を記載：
   - コマンド名・用途・リスク・代替手段の有無
   - 許可理由（なぜ HumanGate では不十分か）
   - 取り消し条件（どのタイミングで禁止に戻すか）
3. ADR 承認後、R-0902 の Allowlist に追加
4. checks/verify_permission.ps1 を更新（新コマンドを許可リストに追加）

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: AI が禁止コマンドを生成した
**対処**:
1. 即座に実行を停止
2. Evidence に「生成されたコマンド・理由」を記録
3. AI に「この操作は HumanGate 必須です」と通知
4. 人間が承認するか、代替手段を検討

**エスカレーション**: 頻発する場合、AI のプロンプト設計を見直す。

---

### 例外2: Allowlist にないコマンドが必要
**対処**:
1. ADR で「一時的に許可」を提案
2. 期限・取り消し条件を明記
3. HumanGate で承認
4. 期限到達後、Allowlist から削除

**エスカレーション**: 常に必要なコマンドなら、R-0902 の Allowlist に恒久追加。

---

### 例外3: sources/ への操作が必要（機密情報削除等）
**対処**:
1. ADR で削除理由・影響範囲・復元不能性を明記
2. 削除前にバックアップ（別途暗号化保管）
3. HumanGate で承認
4. Git履歴からも削除（`git filter-repo` 等）
5. Evidence に「削除の経緯・承認者・タイムスタンプ」を記録

**エスカレーション**: Part00 例外2 を参照。

---

### 例外4: MCP が破壊的操作を実行しようとした
**対処**:
1. MCP 実行を停止
2. Evidence に「MCP名・入力・意図した操作」を記録
3. HumanGate で承認
4. 承認後に MCP 実行

**エスカレーション**: MCP の権限設定を見直す（R-0907）。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-0901: 禁止コマンド検出
**判定条件**: docs/ および checks/ に R-0902 の禁止コマンドが記載されていないか
**合否**: 1つでも検出されたら Fail
**実行方法**: `checks/verify_permission.ps1` の `Test-ForbiddenCommands` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_forbidden_check.md`

---

### V-0902: sources/ 改変検出
**判定条件**: sources/ 内のファイルが commit 間で変更されていないか（追加のみOK）
**合否**: 既存ファイルが変更されていたら Fail
**実行方法**: `git diff HEAD~1 HEAD -- sources/` でファイル変更を検出
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_sources_integrity.md`

---

### V-0903: HumanGate 承認記録の存在確認
**判定条件**: HumanGate 操作に対応する Evidence が存在するか
**合否**: 記録なしなら Fail
**実行方法**: `checks/verify_permission.ps1` の `Test-HumanGateEvidence` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_humangate_check.md`

---

### V-0904: Allowlist 準拠確認
**判定条件**: 実行されたコマンドが Allowlist に載っているか
**合否**: Allowlist にないコマンドが実行されていたら Fail
**実行方法**: `evidence/` のコマンド履歴をスキャン
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_allowlist_check.md`

---

### V-0905: MCP 監査ログの存在確認
**判定条件**: MCP 実行時の Evidence が存在するか
**合否**: 記録なしなら警告（Fail ではない）
**実行方法**: `checks/verify_permission.ps1` の `Test-MCPAuditLog` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_mcp_audit.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-0901: HumanGate 承認記録
**保存内容**:
- 操作内容（コマンド・対象ファイル）
- Dry-run 結果
- 承認者・承認日時・承認理由
- 実行前後の状態（diff）

**参照パス**: `evidence/humangate/YYYYMMDD_HHMMSS_<operation>.md`
**保存場所**: `evidence/humangate/`（削除禁止）

---

### E-0902: 禁止コマンド検出ログ
**保存内容**:
- 検出されたコマンド
- 検出場所（ファイル名・行番号）
- 検出日時

**参照パス**: `evidence/verify_reports/YYYYMMDD_HHMMSS_forbidden_check.md`
**保存場所**: `evidence/verify_reports/`

---

### E-0903: sources/ 改変検出ログ
**保存内容**:
- 変更されたファイル
- 変更内容（diff）
- 変更日時・変更者

**参照パス**: `evidence/verify_reports/YYYYMMDD_HHMMSS_sources_integrity.md`
**保存場所**: `evidence/verify_reports/`

---

### E-0904: コマンド実行履歴
**保存内容**:
- 実行コマンド
- 実行日時・実行者（AI or Human）
- 実行結果（成功・失敗）
- 権限レベル（ReadOnly/PatchOnly/ExecLimited/HumanGate）

**参照パス**: `evidence/command_history/YYYYMMDD_HHMMSS_commands.md`
**保存場所**: `evidence/command_history/`

---

### E-0905: MCP 実行ログ
**保存内容**:
- MCP 名・ツール名
- 入力パラメータ
- 出力結果
- 実行日時

**参照パス**: `evidence/mcp_logs/YYYYMMDD_HHMMSS_mcp_<tool>.md`
**保存場所**: `evidence/mcp_logs/`

---

## 10. チェックリスト

- [x] 本Part09 が全12セクション（0〜12）を満たしているか
- [x] Permission Tier の4階層（R-0901）が明記されているか
- [x] Allowlist（R-0902）が明記されているか
- [x] sources/ の読取専用化（R-0903）が明記されているか
- [x] HumanGate 必須操作（R-0904）が明記されているか
- [x] Dry-run の強制（R-0905）が明記されているか
- [x] 禁止コマンドの検出（R-0906）が明記されているか
- [x] MCP の権限管理（R-0907）が明記されているか
- [x] 各ルールに FACTS_LEDGER または ADR への参照が付いているか
- [x] Verify観点（V-0901〜V-0905）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-0901〜E-0905）が参照パス付きで記述されているか
- [ ] checks/verify_permission.ps1 が実装されているか（次タスク）
- [ ] 本Part09 を読んだ人が「AI の権限制限」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-0901: Allowlist の動的更新
**問題**: Allowlist を「プロジェクトごと」「タスクごと」に動的に変更するか、固定するか不明。
**影響Part**: Part09（本Part）
**暫定対応**: 固定 Allowlist で開始。プロジェクト固有のコマンドが必要な場合は ADR で追加。

---

### U-0902: MCP の権限粒度
**問題**: MCP ツールごとに権限レベルを設定するか、MCP 全体で統一するか不明。
**影響Part**: Part09（本Part）
**暫定対応**: MCP 全体で統一（読取系は ReadOnly、書込系は PatchOnly）。

---

### U-0903: HumanGate の承認フロー
**問題**: 承認を「口頭」「チャット」「ADR」のどれで記録するか不明。
**影響Part**: Part09（本Part）
**暫定対応**: Evidence に markdown ファイルで記録（`evidence/humangate/`）。

---

### U-0904: 権限違反時のペナルティ
**問題**: AI が権限を超えた操作を実行した場合、「警告のみ」「実行停止」「アクセス制限」のどれを適用するか不明。
**影響Part**: Part09（本Part）
**暫定対応**: 実行停止 + Evidence 記録。頻発する場合、AI の利用制限を検討。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法（禁止事項リスト）
- [docs/Part01.md](Part01.md) : 目標・失敗定義
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-0031, F-0055, F-0011）
- [docs/Part02.md](Part02.md) : 用語運用ルール
- [docs/Part04.md](Part04.md) : 作業管理（TICKET）
- [docs/Part10.md](Part10.md) : Verify Gate

### sources/
- [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md) : 原文（L512, L655-693）

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス（第3条: sources/ 読取専用）
- [decisions/0003-sources-duplicate-handling.md](../decisions/0003-sources-duplicate-handling.md) : sources/ 重複ファイル扱い

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_permission.ps1` : Permission Tier 検証（次タスクで作成予定）

### evidence/
- `evidence/humangate/` : HumanGate 承認記録
- `evidence/command_history/` : コマンド実行履歴
- `evidence/mcp_logs/` : MCP 実行ログ
- `evidence/verify_reports/` : Verify 実行結果

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
