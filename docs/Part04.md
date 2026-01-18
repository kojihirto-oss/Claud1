# Part 04：作業管理（TICKET/VIBEKANBAN/WIP制限・タスクサイズ・進捗状態）

## 0. このPartの位置づけ
- **目的**: タスク（TICKET）の標準フォーマット・サイズ分類・WIP制限・進捗管理を明文化し、作業の迷いをゼロにする。
- **依存**: [Part00](Part00.md)（SSOT憲法）、[Part01](Part01.md)（DoD）
- **影響**: Part09（Permission Tier）、Part10（Verify Gate）、Part14（変更管理）

---

## 1. 目的（Purpose）

本 Part04 は **作業管理の標準化** を通じて、以下を保証する：

1. **迷いゼロ**: 次に何をすべきかが常に一意（VIBEKANBAN/SSOT を見れば即座に分かる）
2. **並列安全**: 複数タスクを worktree 隔離で並列実行し、衝突を防ぐ
3. **サイズ制限**: XL タスクを禁止し、L以下に分割することで収束性を担保
4. **進捗可視化**: TICKET の状態（READY/DOING/VERIFYING/DONE）を機械判定可能にする

**根拠**: [FACTS_LEDGER F-0040](FACTS_LEDGER.md)（TICKET フォーマット）、[F-0010](FACTS_LEDGER.md)（VIBEKANBAN）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 本リポジトリ内の全タスク（TICKET）
- VIBEKANBAN による進捗管理
- タスクサイズの分類（S/M/L）
- WIP（Work In Progress）制限
- AI エージェントによるタスク実行

### Out of Scope（適用外）
- 外部プロジェクトのタスク管理
- 個人の TODO リスト（プロジェクトに無関係なもの）
- 長期計画（ロードマップ）は Part01 で扱う

---

## 3. 前提（Assumptions）

1. **TICKET は Spec 凍結後に作成**される（Part01 R-0104）。
2. **VIBEKANBAN は worktree 隔離**が前提（衝突防止）。
3. **XL サイズのタスクは禁止**（必ず L以下に分割）。
4. **WIP 制限を超えない**（並列上限を守る）。
5. **進捗状態は機械判定可能**である（STATUS.md に明記）。

**根拠**: [FACTS_LEDGER F-0041](FACTS_LEDGER.md)（サイズ分類）、[F-0042](FACTS_LEDGER.md)（WIP制限）

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **TICKET**: タスクの標準フォーマット（Goal/Non-Goals/Acceptance/Plan/Verify/Evidence/Rollback を含む）
- **VIBEKANBAN**: [glossary/GLOSSARY.md#VIBEKANBAN](../glossary/GLOSSARY.md)（並列エージェント実行の安全装置）
- **WIP（Work In Progress）**: 並列実行中のタスク数
- **worktree**: [glossary/GLOSSARY.md#worktree](../glossary/GLOSSARY.md)（Git の物理分離機能）
- **DoD**: [glossary/GLOSSARY.md#DoD](../glossary/GLOSSARY.md)（Definition of Done）
- **Spec Freeze**: 仕様凍結（実装開始の前提条件）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-0401: TICKET 標準フォーマット【MUST】
各 TICKET は以下の **9項目を必ず含む**：

1. **Goal**: 何を達成するか（1文）
2. **Non-Goals**: やらないこと（暴走防止）
3. **Inputs**: 参照データ（SSOT の該当箇所、ファイル、URL等）
4. **Acceptance**: 機械判定可能な受入条件
5. **Risks**: 壊れやすい箇所/権限/鍵/外部依存
6. **Plan**: 手順（箇条書き、実行可能な粒度）
7. **Verify**: 実行コマンド/チェック項目
8. **Evidence**: 保存先と保存物
9. **Rollback**: 戻し方

**根拠**: [FACTS_LEDGER F-0040](FACTS_LEDGER.md)
**違反例**: Goal だけ書いて他を省略 → Acceptance/Verify/Rollback がないため、未完了。

**テンプレート例**:
```markdown
## TICKET-001: Part00 の作成

### Goal
Part00（SSOT憲法）を作成し、全12セクションを埋める。

### Non-Goals
- Part01以降の作成（別TICKET）
- checks/ の実装（別TICKET）

### Inputs
- FACTS_LEDGER.md（F-0001〜F-0003）
- ADR-0001（SSOT運用ガバナンス）
- docs/Part00.md（テンプレート）

### Acceptance
- Part00.md が全12セクション（0〜12）を満たしている
- 各ルールに FACTS_LEDGER or ADR への参照が付いている
- Verify観点（V-0001〜V-0005）が機械判定可能

### Risks
- リンク切れ（FACTS_LEDGER/ADR へのパスミス）
- 用語揺れ（glossary/ との不一致）

### Plan
1. FACTS_LEDGER から F-0001, F-0002, F-0003 を読む
2. Part00.md を12セクション構成で作成
3. 各ルールに根拠を付ける
4. commit（メッセージ: "Fill Part00 (SSOT constitution)"）

### Verify
- checks/verify_repo.ps1 の Test-Links を実行
- Part00.md の存在確認
- 禁止コマンド検出

### Evidence
- evidence/verify_reports/YYYYMMDD_HHMMSS_part00_check.md
- git commit log

### Rollback
- git revert <commit_hash>
- docs/Part00.md をテンプレートに戻す
```

---

### R-0402: タスクサイズ分類【MUST】
タスクは以下のサイズに分類し、**XL は禁止**（必ず L以下に分割）：

- **S（30〜90分）**: 単一ファイルor単一バグ、変更≤50行、Verify≤5分
- **M（半日）**: 複数ファイル、変更≤300行、Verify≤20分
- **L（1〜3日）**: 設計変更あり、テスト拡充、移行含む
- **XL（1週間+）**: **禁止**（必ず L以下に割る）

**根拠**: [FACTS_LEDGER F-0041](FACTS_LEDGER.md)
**理由**: XL タスクは収束しない、VRループが回らない、失敗時の影響範囲が大きい。

**分割例**:
- XL: 「Part00〜Part20 を全部埋める」→ 禁止
- L: 「Part00 を埋める」→ OK
- M: 「Part00 の Verify観点を追加」→ OK
- S: 「Part00 のリンク切れ修正」→ OK

---

### R-0403: WIP（Work In Progress）制限【MUST】
並列実行するタスク数は以下の上限を守る：

- **S: 並列2まで**
- **M: 並列1まで**（単独実行）
- **L: 並列0**（他のタスクを全て停止し、単独集中）

**前提**: エージェント並列は **worktree 隔離** が前提。隔離できないなら並列禁止。

**根拠**: [FACTS_LEDGER F-0042](FACTS_LEDGER.md)
**理由**: 並列過多は衝突・破壊・迷いの原因。

---

### R-0404: VIBEKANBAN の状態遷移【MUST】
タスクは以下の状態を遷移し、**必ず DONE に到達**する：

1. **READY**: Spec 凍結済み（実装開始可能）
2. **DOING**: 実装中（変更が発生）
3. **VERIFYING**: Verify 実行中
4. **REPAIRING**: 失敗修正（VRループ中）
5. **DONE**: DoD 満たし Evidence 保存済み
6. **BLOCKED**: 外部依存/不明点があり停止（解除条件を明記）

**根拠**: [FACTS_LEDGER F-0043](FACTS_LEDGER.md)
**違反例**: DOING → DONE へ直接遷移（VERIFYING を飛ばす）→ Verify 不足。

---

### R-0405: VIBEKANBAN の運用型【MUST】
VIBEKANBAN は「人間の計画 → AI の実行 → 人間の承認」の型に固定する。

**手順**:
1. 人間が TICKET を作成（Goal/Acceptance/Plan を明記）
2. AI（Claude Code等）が実装・Verify・Evidence 保存
3. 人間が diff をレビューし、承認（merge to main）

**根拠**: [FACTS_LEDGER F-0010](FACTS_LEDGER.md)
**理由**: AI の暴走を防ぎ、main を守る。

---

### R-0406: worktree 隔離の強制【MUST】
並列タスクは **必ず worktree で物理分離**する。

**理由**: 同一ディレクトリでの並列実行は、ファイル衝突・Git 衝突・破壊のリスクが高い。
**根拠**: [FACTS_LEDGER F-0010](FACTS_LEDGER.md)、[F-0007](FACTS_LEDGER.md)（Git戦略）

**例外**: worktree が使えない環境では、並列禁止（順次実行）。

---

### R-0407: BLOCKED 状態の解除条件明記【MUST】
タスクが BLOCKED 状態になった場合、**解除条件を明記**する。

**例**:
- `BLOCKED: Part09 の完成を待つ（依存）`
- `BLOCKED: API鍵の取得待ち（HumanGate）`
- `BLOCKED: 不明点（U-XXXX）の確定待ち`

**理由**: 解除条件がないと、永遠に BLOCKED のまま放置される。

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: TICKET の作成
1. タスクの Goal を1文で定義
2. Non-Goals を明記（暴走防止）
3. Inputs（参照先）を列挙
4. Acceptance を機械判定可能な形で記述
5. Risks を洗い出し（権限/鍵/外部依存）
6. Plan を実行可能な粒度で箇条書き
7. Verify の実行方法を明記
8. Evidence の保存先を指定
9. Rollback 手順を記述
10. VIBEKANBAN に READY 状態で追加

### 手順B: タスクの実行（AI）
1. VIBEKANBAN から READY 状態の TICKET を取得
2. WIP 制限を確認（並列上限を超えていないか）
3. worktree を作成（並列タスクの場合）
4. TICKET の Plan に従って実装
5. 状態を DOING → VERIFYING に変更
6. Verify を実行
7. 全て Green なら Evidence を保存し、DONE に変更
8. 失敗なら REPAIRING に変更し、VRループを回す

### 手順C: タスクの承認（人間）
1. DONE 状態の TICKET を取得
2. diff をレビュー（変更内容・影響範囲）
3. Evidence を確認（Verify ログ・manifest/sha256）
4. 問題なければ merge to main
5. VIBEKANBAN から TICKET を削除（アーカイブ）

### 手順D: タスクの分割（XL → L以下）
1. XL サイズのタスクを検出
2. Goal を複数の L/M/S に分割
3. 各サブタスクに TICKET を作成
4. 依存関係を明記（順序固定）
5. 元の XL TICKET を削除

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: WIP 制限を超えてしまった
**対処**:
1. 新規タスクを READY で待機させる
2. 既存タスクが DONE に到達してから開始
3. 緊急タスクの場合、既存タスクを BLOCKED に変更（理由明記）

**エスカレーション**: WIP 超過が常態化する場合、タスクサイズの見直し。

---

### 例外2: BLOCKED 状態が長期化
**対処**:
1. 解除条件を再確認（不明点が確定したか？依存タスクが完了したか？）
2. 解除できない場合、ADR で「TICKET の中止」を決定
3. 代替手段を検討

**エスカレーション**: BLOCKED が増殖する場合、計画の見直し。

---

### 例外3: worktree が使えない環境
**対処**:
1. 並列禁止（WIP=1 固定）
2. 順次実行（1タスクずつ完了させる）
3. 環境改善を検討（Git worktree のインストール）

**エスカレーション**: 並列実行が必須の場合、環境移行を検討。

---

### 例外4: AI が TICKET の Plan を無視
**対処**:
1. 即座に作業を停止
2. Evidence に「逸脱の経緯・影響範囲」を記録
3. Rollback（git revert）
4. TICKET の Plan を修正（曖昧さを排除）

**エスカレーション**: Part09（Permission Tier）の見直し。

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-0401: TICKET フォーマット充足率
**判定条件**: R-0401 の9項目が全て記載されているか
**合否**: 1つでも欠けていたら Fail
**実行方法**: `checks/verify_ticket.ps1` の `Test-TicketFormat` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_ticket_format.md`

---

### V-0402: XL タスクの検出
**判定条件**: VIBEKANBAN に XL サイズのタスクが存在するか
**合否**: 1つでも存在したら Fail
**実行方法**: `checks/verify_wip.ps1` の `Test-NoXLTasks` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_xl_detection.md`

---

### V-0403: WIP 制限違反の検出
**判定条件**: 並列実行中のタスク数が WIP 上限を超えていないか
**合否**: 超過していたら Fail
**実行方法**: `checks/verify_wip.ps1` の `Test-WIPLimit` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_wip_limit.md`

---

### V-0404: VIBEKANBAN 状態整合性
**判定条件**: DOING 状態のタスクに対応する worktree が存在するか
**合否**: 不一致があれば Fail
**実行方法**: `checks/verify_kanban.ps1` の `Test-KanbanState` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_kanban_state.md`

---

### V-0405: BLOCKED 解除条件の明記
**判定条件**: BLOCKED 状態のタスクに解除条件が記載されているか
**合否**: 記載なしなら警告（Fail ではない）
**実行方法**: `checks/verify_kanban.ps1` の `Test-BlockedCondition` 関数
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_blocked_check.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-0401: TICKET 作成時の Evidence
**保存内容**:
- TICKET 全文（Goal/Non-Goals/Acceptance/Plan/Verify/Evidence/Rollback）
- 参照元（SSOT/ADR/FACTS_LEDGER）

**参照パス**: `VIBEKANBAN/100_SPEC/TICKET-XXX.md`
**保存場所**: `VIBEKANBAN/100_SPEC/`

---

### E-0402: タスク実行時の Evidence
**保存内容**:
- 実行ログ（コマンド履歴）
- diff（変更前後）
- Verify 結果
- manifest/sha256

**参照パス**: `evidence/tasks/YYYYMMDD_HHMMSS_ticket_<ID>.md`
**保存場所**: `evidence/tasks/`

---

### E-0403: タスク承認時の Evidence
**保存内容**:
- レビュー結果（diff の承認）
- merge commit hash
- 承認者・承認日時

**参照パス**: `evidence/approvals/YYYYMMDD_HHMMSS_ticket_<ID>.md`
**保存場所**: `evidence/approvals/`

---

### E-0404: WIP 状況のスナップショット
**保存内容**:
- 現在の WIP 数
- 各タスクの状態（READY/DOING/VERIFYING/REPAIRING/DONE/BLOCKED）
- worktree 一覧

**参照パス**: `evidence/wip_snapshots/YYYYMMDD_HHMMSS_wip.md`
**保存場所**: `evidence/wip_snapshots/`

---

### E-0405: BLOCKED タスクの履歴
**保存内容**:
- BLOCKED になった理由
- 解除条件
- BLOCKED 期間

**参照パス**: `evidence/blocked_history/YYYYMMDD_HHMMSS_blocked_<ID>.md`
**保存場所**: `evidence/blocked_history/`

---

## 10. チェックリスト

- [x] 本Part04 が全12セクション（0〜12）を満たしているか
- [x] TICKET 標準フォーマット（R-0401）が明記されているか
- [x] タスクサイズ分類（R-0402）が明記されているか
- [x] WIP 制限（R-0403）が明記されているか
- [x] VIBEKANBAN 状態遷移（R-0404）が明記されているか
- [x] VIBEKANBAN 運用型（R-0405）が明記されているか
- [x] worktree 隔離の強制（R-0406）が明記されているか
- [x] BLOCKED 解除条件明記（R-0407）が明記されているか
- [x] 各ルールに FACTS_LEDGER への参照が付いているか
- [x] Verify観点（V-0401〜V-0405）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-0401〜E-0405）が参照パス付きで記述されているか
- [ ] checks/verify_ticket.ps1 が実装されているか（次タスク）
- [ ] 本Part04 を読んだ人が「タスクの進め方」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-0401: VIBEKANBAN の物理実装
**問題**: VIBEKANBAN を「フォルダ」「Git Issue」「外部ツール（Trello等）」のどれで実装するか不明。
**影響Part**: Part04（本Part）
**暫定対応**: フォルダベース（`VIBEKANBAN/100_SPEC/`）で開始。運用が安定したら外部ツールへ移行を検討。

---

### U-0402: worktree の命名規則
**問題**: worktree のフォルダ名を「TICKET-ID」「ブランチ名」のどちらにするか不明。
**影響Part**: Part04、Part14（変更管理）
**暫定対応**: `worktree_<TICKET-ID>` 形式で統一。

---

### U-0403: BLOCKED の自動検出
**問題**: BLOCKED 状態を自動検出する方法が不明（依存タスクの未完了を機械判定できるか？）。
**影響Part**: Part10（Verify Gate）
**暫定対応**: 手動で BLOCKED を設定。自動検出は将来の改善課題。

---

### U-0404: タスク完了後のアーカイブ先
**問題**: DONE 状態のタスクを VIBEKANBAN から削除する際、どこにアーカイブするか不明。
**影響Part**: Part04、Part14（変更管理）
**暫定対応**: `VIBEKANBAN/900_RELEASE/` にアーカイブ。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part01.md](Part01.md) : 目標・DoD
- [docs/FACTS_LEDGER.md](FACTS_LEDGER.md) : 確定情報（F-0010, F-0040, F-0041, F-0042, F-0043）
- [docs/Part02.md](Part02.md) : 用語運用ルール
- [docs/Part09.md](Part09.md) : Permission Tier
- [docs/Part10.md](Part10.md) : Verify Gate
- [docs/Part14.md](Part14.md) : 変更管理

### sources/
- [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md) : 原文（L143-197）

### decisions/
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : SSOT運用ガバナンス

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_ticket.ps1` : TICKET フォーマット検証（次タスクで作成予定）
- `checks/verify_wip.ps1` : WIP制限・XLタスク検出（次タスクで作成予定）
- `checks/verify_kanban.ps1` : VIBEKANBAN 状態整合性検証（次タスクで作成予定）

### evidence/
- `evidence/tasks/` : タスク実行時の Evidence
- `evidence/approvals/` : タスク承認時の Evidence
- `evidence/wip_snapshots/` : WIP 状況スナップショット
- `evidence/blocked_history/` : BLOCKED タスク履歴

### VIBEKANBAN/
- `VIBEKANBAN/000_INBOX/` : 未分類タスク
- `VIBEKANBAN/100_SPEC/` : Spec 作成中（TICKET 保存先）
- `VIBEKANBAN/200_BUILD/` : 実装中
- `VIBEKANBAN/300_VERIFY/` : Verify 実行中
- `VIBEKANBAN/400_REPAIR/` : 修正中（VRループ）
- `VIBEKANBAN/900_RELEASE/` : 完了（アーカイブ）

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
