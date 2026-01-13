# Part 09：Permission Tier（ReadOnly/PatchOnly/ExecLimited/HumanGateの権限設計）

## 0. このPartの位置づけ
- 目的：AI Agent/CLI/IDEによる作業の権限階層を定義し、越権・破壊・不正変更を防止する
- 依存：Part02（用語）、Part10（Verify Gate）、decisions/0001-ssot-governance.md
- 影響：Part06（IDE/司令塔運用）、Part11（並列タスク運用）、全Part（実行権限の基準）

## 1. 目的（Purpose）

SSOT（docs/）を壊さず、安全に更新するための **権限階層（Permission Tier）** を定義する。
- AI Agentや自動化ツールが「どこまで自律実行できるか」を明確化
- 破壊的操作・方針変更・例外承認は **HumanGate（人間判断）** を必須化
- 全ての作業に **DoD（Definition of Done）** を設定し、証跡（Evidence）を残す

## 2. 適用範囲（Scope / Out of Scope）

### Scope
- リポジトリ内のすべてのファイル操作（読み取り/変更/削除/実行）
- AI Agent/CLI/IDE/人間による作業の権限レベル
- HumanGate（人間承認）が必要な操作の明確化
- 例外承認プロセスと証跡要件
- DoD（Definition of Done）の基準

### Out of Scope
- 外部システム（GitHub API、CI/CD）の権限管理（Part14参照）
- ユーザー認証・認可の実装詳細（インフラ層）

## 3. 前提（Assumptions）

1. このリポジトリは **SSOT（Single Source of Truth）** であり、破壊は許容しない
2. AI Agentは指示に従うが、**判断ミス・過剰実行・暴走** のリスクがある
3. 人間の承認（HumanGate）は **最終防衛線** として機能する
4. すべての変更は **再現可能・監査可能** でなければならない

## 4. 用語（Glossary参照：Part02）

- **Permission Tier**：作業の権限レベル（ReadOnly / PatchOnly / ExecLimited / HumanGate）
- **HumanGate**：人間による明示的な承認が必要な操作
- **DoD (Definition of Done)**：作業完了の判定基準
- **Evidence Pack**：作業の証跡（ログ/差分/判定結果）
- **ADR**：Architecture Decision Record（意思決定記録、decisions/に配置）
- **SSOT**：Single Source of Truth（docs/が正本）
- **Verify Gate**：品質ゲート（Fast/Full、Part10参照）

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 Permission Tier の定義

#### Tier 1: ReadOnly（読み取りのみ）
- **MUST**: AI Agentはファイル読み取り、検索、分析のみ実行可能
- **MUST NOT**: ファイルの変更・削除・実行は禁止
- **適用対象**:
  - sources/（根拠資料、改変禁止）
  - evidence/（監査証跡、改変禁止）
  - decisions/（ADR、既存ファイルの改変禁止、追加のみ HumanGate）

#### Tier 2: PatchOnly（差分適用のみ）
- **MUST**: AI Agentは既存ファイルへの差分適用（Edit）のみ実行可能
- **MUST NOT**: 新規ファイル作成、ファイル削除、ファイル名変更は禁止
- **MUST**: 変更前に必ずファイルを読み取り（Read）してから Edit を実行
- **MUST**: 変更後は必ず Verify Gate（Fast）を実行
- **適用対象**:
  - docs/Part*.md（既存Partの内容更新）
  - glossary/GLOSSARY.md（用語の定義追加・修正）

#### Tier 3: ExecLimited（限定的な実行）
- **MUST**: AI Agentは以下の操作を実行可能：
  - 新規ファイル作成（docs/Part*.md、glossary/、checks/ の範囲内）
  - Verify スクリプトの実行（checks/ 配下のみ）
  - Git操作（commit、push、branch作成）
- **MUST NOT**: 以下は禁止：
  - sources/ 内のファイル削除・上書き
  - Part番号の変更・ファイル名変更
  - 既存ADR（decisions/*.md）の改変
- **MUST**: 実行前に DoD（Definition of Done）を確認
- **MUST**: 実行後に Evidence Pack を生成

#### Tier 4: HumanGate（人間承認必須）
- **MUST**: 以下の操作には人間の明示的な承認が必要：
  - 新規ADR（decisions/）の作成
  - Part番号・ファイル名の変更
  - sources/ の削除・上書き
  - SSOT運用ルール（CLAUDE.md、ADR-0001）の変更
  - 破壊的な変更（互換性喪失、過去の証跡削除）
  - 例外承認（Permission Tierの一時的な緩和）
- **MUST**: 承認プロセスは以下の手順で実行（セクション 6.3 参照）
- **MUST**: 承認結果は evidence/ に記録

##### HumanGate 承認者・SLA・承認チャネル
- **MUST**: 承認者は `decisions/0004-humangate-approvers.md` に記録（主要/代理/緊急の3系統）
- **MUST**: 承認SLAを明記し、期限超過時は自動エスカレーション（SLA: 通常24h、重要48h、緊急2h）
- **MUST**: 承認チャネルは「PR Review」または「Issue/Chatの明示承認（LGTM + 確認ログ）」に限定
- **MUST**: 承認ログは `evidence/humangate_approvals/` に保存し、参照パスを明記

### 5.2 DoD（Definition of Done）の基準

すべての作業は以下の **DoD** を満たさなければ完了とみなさない：

#### DoD-1: 差分明確化
- **MUST**: 変更内容を明確に文章化（変更点の要約）
- **MUST**: 編集ファイル一覧を列挙（パス付き）

#### DoD-2: Verify PASS
- **MUST**: Fast Verify（4点チェック）を実行し、全項目 PASS を確認
  1. docs 内リンク切れ（相対パス/外部URL）
  2. 用語揺れ（glossary と docs の不一致）
  3. Part間整合（Part00 との衝突チェック）
  4. 未決事項の残存一覧（TODO/未決の集計）
- **SHOULD**: Full Verify（詳細検証）は重要な変更時に実行

#### DoD-3: Evidence Pack 生成
- **MUST**: 以下を evidence/ に保存：
  - 変更差分（git diff または編集前後の比較）
  - Verify レポート（Fast Verify の実行結果）
  - 実行ログ（タイムスタンプ、実行者、コマンド履歴）

#### DoD-4: Commit/Push 完了
- **MUST**: 変更を Git commit し、適切なブランチに push
- **MUST**: Commit メッセージは変更内容を簡潔に記述
- **MUST**: ブランチ名は `claude/<task-description>-<session-id>` 形式

### 5.3 並列タスク運用の型（1Part=1Branch原則）

#### 原則
- **MUST**: 1つのブランチで編集する Part は最大1つ（必要最小限の共有ファイルを除く）
- **MUST**: 共有ファイル（Part02 用語集、GLOSSARY.md など）の担当を固定化
- **MUST**: Verify は作業完了後に1回のみ実行（中間実行は任意）
- **MUST**: 証跡（Evidence Pack）は作業完了時に生成・保存

#### 共有ファイルの扱い
- **Part02（用語集）**: 用語追加・修正は PatchOnly で実行可能
- **GLOSSARY.md**: Part02 と同期、用語定義の唯一の正
- **00_INDEX.md**: リンク追加のみ（構造変更は HumanGate）
- **CLAUDE.md**: 変更は HumanGate 必須

#### 衝突回避
- **MUST**: 並列作業時は異なる Part を担当
- **MUST**: 共有ファイル更新は1ブランチで完結させる
- **SHOULD**: Part02/GLOSSARY.md の更新は優先的に merge

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 通常作業の手順（PatchOnly / ExecLimited）

1. **タスク開始前の確認**
   - Permission Tier を確認（このタスクは ReadOnly / PatchOnly / ExecLimited / HumanGate のいずれか？）
   - DoD（Definition of Done）を確認（完了条件を把握）
   - 並列タスクがある場合、編集対象 Part が重複していないか確認

2. **ファイル読み取り**
   - 対象ファイルを Read ツールで読み取り
   - 関連 Part（Part00、Part02など）も読み取り、整合性を事前確認

3. **変更実行**
   - PatchOnly の場合：Edit ツールで差分適用
   - ExecLimited の場合：Write ツールで新規ファイル作成、または Git操作実行

4. **DoD 確認**
   - DoD-1: 変更点の要約を文章化
   - DoD-2: Fast Verify を実行し、4点 PASS を確認
   - DoD-3: Evidence Pack を生成（差分/Verify結果/ログ）
   - DoD-4: Commit/Push を実行

5. **完了報告**
   - 変更内容の要約を出力
   - 編集ファイル一覧を出力
   - Fast Verify PASS 4点の証跡を出力

### 6.2 Fast Verify の実行手順

1. **docs 内リンク切れチェック**
   - 各 Part 内の `[...](...)`形式のリンクを抽出
   - 相対パスの存在確認、外部URLの到達確認
   - 結果：PASS / FAIL（リンク切れ数）

2. **用語揺れチェック**
   - glossary/GLOSSARY.md の用語定義を読み取り
   - docs/ 内の用語使用を検索
   - 未定義用語、表記揺れを検出
   - 結果：PASS / FAIL（揺れ数）

3. **Part間整合チェック**
   - Part00（前提・目的）のルールを読み取り
   - 各 Part がPart00 のルールに違反していないか確認
   - 矛盾する記述を検出
   - 結果：PASS / FAIL（矛盾数）

4. **未決事項の残存チェック**
   - 各 Part の「## 11. 未決事項」を抽出
   - 未解決項目を集計
   - 結果：PASS（0件） / WARN（1件以上、内容リスト化）

### 6.3 HumanGate（人間承認）の手順

1. **承認要求の作成**
   - 操作内容を明確に記述（何を、なぜ、どのように変更するか）
   - リスク評価を記述（破壊的影響、復旧方法）
   - 代替案を検討（より安全な方法はないか）

2. **人間への提示**
   - 承認要求を出力（明確に「HumanGate承認が必要です」と明記）
   - 質問形式で承認を求める（「この操作を実行してよろしいですか？ [Yes/No]」）
   - 承認者は `decisions/0004-humangate-approvers.md` を参照し、主要/代理/緊急の順で依頼

3. **承認結果の記録**
   - 承認の場合：`evidence/humangate_approvals/` に承認ログを保存（日時/承認者/操作内容/SLA判定）
   - 却下の場合：操作を中止し、代替案を検討

4. **承認後の実行**
   - 承認された操作を実行
   - DoD に従って完了確認
   - 緊急時は「緊急承認者→事後ADR→再Verify」を必須手順として追記

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 Permission Tier 違反の検出

**検出条件**：
- ReadOnly 対象への Edit/Write 実行
- PatchOnly 対象への削除・ファイル名変更
- HumanGate 必須操作を承認なしで実行

**対処**：
1. 操作を即座に中止
2. 違反内容をログに記録（evidence/）
3. ユーザーに報告（「Permission Tier 違反を検出しました」）
4. 代替手段を提案（正しい Tier での実行方法）

### 7.2 Verify FAIL の対処

**検出条件**：
- Fast Verify の4点チェックのいずれかが FAIL

**対処**：
1. FAIL の詳細を出力（どの項目が、なぜ FAIL したか）
2. 修正方法を提案（リンク修正、用語統一など）
3. 修正後に再度 Verify を実行
4. PASS するまで繰り返し

### 7.3 DoD 未達の対処

**検出条件**：
- DoD-1〜DoD-4 のいずれかが満たされていない

**対処**：
1. 未達項目を明確化
2. 不足している作業を実行（差分生成、Evidence Pack作成など）
3. 全 DoD を満たすまで完了としない

### 7.4 例外承認の記録

**条件**：
- Permission Tier を一時的に緩和する必要がある場合（例：緊急修正）

**手順**：
1. 例外理由を明確に記述
2. HumanGate で承認を得る
3. decisions/ に例外 ADR を作成
4. 例外の有効期限・適用範囲を明記
5. Evidence Pack に例外承認記録を含める

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 Fast Verify の判定基準

| 項目 | 判定条件 | PASS | FAIL |
|------|----------|------|------|
| 1. リンク切れ | docs/ 内の全リンクが有効 | リンク切れ 0件 | リンク切れ 1件以上 |
| 2. 用語揺れ | glossary/ と docs/ の用語が一致 | 揺れ 0件 | 揺れ 1件以上 |
| 3. Part間整合 | Part00 との矛盾なし | 矛盾 0件 | 矛盾 1件以上 |
| 4. 未決事項 | 未決事項の集計 | WARN許容 | - |

### 8.2 Permission Tier 判定

| 操作 | 対象 | 必要Tier | 判定方法 |
|------|------|----------|----------|
| Read | 全ファイル | ReadOnly | 常に許可 |
| Edit | docs/Part*.md | PatchOnly | ファイル存在確認 |
| Write | docs/（新規） | ExecLimited | Part番号の重複確認 |
| Delete | sources/ | HumanGate | 人間承認の有無 |
| ADR作成 | decisions/ | HumanGate | 人間承認の有無 |

### 8.3 DoD 判定

| DoD項目 | 判定条件 | ログ出力 |
|---------|----------|----------|
| DoD-1 | 変更点要約が存在 | 「変更点の要約：[内容]」 |
| DoD-2 | Fast Verify PASS | 「Fast Verify PASS 4点」 |
| DoD-3 | Evidence Pack 生成 | 「Evidence Pack: evidence/[path]」 |
| DoD-4 | Git commit/push 完了 | 「Commit: [hash], Branch: [name]」 |

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 必須 Evidence

すべての作業（PatchOnly / ExecLimited / HumanGate）は以下を evidence/ に保存：

1. **変更差分（Diff）**
   - ファイルパス：`evidence/YYYYMMDD_HHMM_<task-id>_diff.md`
   - 内容：git diff 出力、または編集前後の比較

2. **Verify レポート**
   - ファイルパス：`evidence/verify_reports/YYYYMMDD_HHMMSS_Fast_PASS.md`
   - 内容：Fast Verify の4点チェック結果

3. **実行ログ**
   - ファイルパス：`evidence/YYYYMMDD_HHMM_<task-id>_log.md`
   - 内容：タイムスタンプ、実行者（AI/人間）、コマンド履歴

4. **HumanGate 承認記録（該当時）**
   - ファイルパス：`evidence/humangate_approvals/YYYYMMDD_HHMMSS_<task-id>_APPROVED.md`
   - 内容：承認日時、承認者、操作内容、承認理由、SLA判定

### 9.2 Evidence の保持期間

- **MUST**: すべての Evidence は削除禁止（追記のみ）
- **SHOULD**: 定期的なアーカイブ（年次、evidence/archive/ へ移動）

## 10. チェックリスト

作業完了前に以下を確認：

- [ ] Permission Tier を確認し、越権操作をしていない
- [ ] 変更前に対象ファイルを読み取った（PatchOnly/ExecLimited）
- [ ] HumanGate 必須操作には承認を得た
- [ ] DoD-1: 変更点の要約を文章化した
- [ ] DoD-2: Fast Verify を実行し、4点 PASS を確認した
- [ ] DoD-3: Evidence Pack を生成した
- [ ] DoD-4: Git commit/push を完了した
- [ ] sources/ を改変・削除していない（ReadOnly厳守）
- [ ] Part番号・ファイル名を変更していない
- [ ] 並列タスク時、編集 Part が重複していない（1Part=1Branch）

## 11. 未決事項（推測禁止）

- Full Verify の詳細仕様（Part10で定義予定）
- Evidence Pack の自動生成スクリプト（checks/ で今後実装）
- Permission Tier の動的変更（セキュリティレベルの切り替え）

## 12. 参照（パス）

- docs/Part00.md（前提・目的）
- docs/Part02.md（共通語彙）
- docs/Part10.md（Verify Gate）
- docs/Part11.md（並列タスク運用、今後定義）
- glossary/GLOSSARY.md（用語定義）
- decisions/0001-ssot-governance.md（SSOT運用ガバナンス）
- decisions/0004-humangate-approvers.md（HumanGate承認者・SLA）
- checks/README.md（検証手順）
- CLAUDE.md（常設ルール）
