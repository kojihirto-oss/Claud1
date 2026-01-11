# Part 09：Permission Tier（S/M/L権限設計・HumanGate・2段階承認フロー）

## 0. このPartの位置づけ
- 目的：Claude Codeエージェントの操作権限を3段階（S/M/L）に分類し、破壊的操作にHumanGate（人間承認）を適用する
- 依存：decisions/0001-ssot-governance.md（ADR→docs原則）、decisions/0002-humangate-permission-tiers.md（本Part根拠）
- 影響：全Part（実行権限）、checks/（Fast Verify）、evidence/（承認記録）

## 1. 目的（Purpose）

VCG/VIBE 2026プロジェクトにおいて、Claude Codeエージェントが自律的にSSOT（docs/）を編集・検証・リリースする際、
**破壊的操作・全域変更・リリース確定・例外処理** などの高リスク操作に対して、
人間承認（HumanGate）を義務付け、「誰が・いつ・何を・どの証跡に残すか」を明確化する。

Permission Tier（S/M/L）を定義し、操作規模とリスクに応じた承認フローを運用する。

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- docs/ 全Part（Part00-20）の編集・削除・移動
- decisions/ ADR追加・変更・廃止
- glossary/ 用語追加・変更・削除
- evidence/ 証跡保存（実行ログ・Verify結果・承認記録）
- checks/ Fast Verify実行
- git操作（commit, push, branch, tag, revert）
- リリース確定操作（バージョンタグ、外部公開）

### Out of Scope（適用外）
- sources/ の追記（読み取り専用、改変禁止は別ルール）
- 外部API呼び出し（VCG/VIBEシステム本体は別ガバナンス）
- 開発環境ローカル操作（個人PCでの検証は制約なし）

## 3. 前提（Assumptions）

1. Claude Codeエージェントは CLAUDE.md ルールを遵守する（MUST）
2. 人間レビュアー・承認者は24時間以内に応答可能（SHOULD）
3. Fast Verify（checks/）は自動実行可能で、PASS/FAIL判定が明確（MUST）
4. git履歴は破壊しない（force push禁止、例外はHumanGate必須）
5. 緊急事態（本番障害・セキュリティインシデント）では事後承認を許可（MUST 24h以内記録）

## 4. 用語（Glossary参照：Part02）

| 用語 | 定義 | 参照 |
|------|------|------|
| Permission Tier | S/M/L の3段階権限分類（Small/Medium/Large） | 本Part, decisions/0002 |
| HumanGate | 人間承認が必須の操作（L Tier） | 本Part, decisions/0002 |
| 2段階承認フロー | 提案→レビュー→承認→実行→記録 の5ステップ | 本Part, decisions/0002 |
| Fast Verify | checks/ による自動検証（PASS/FAIL） | Part08（未作成）, checks/ |
| 破壊的操作 | Part番号変更・sources削除・git force push等 | decisions/0002 |
| 全域変更 | glossary大規模変更・フォルダ構造変更等 | decisions/0002 |
| 緊急承認（事後） | 24h以内に事後ADR作成・追認取得 | decisions/0002 |

※ Part02（用語集）未作成の場合、本Part定義を暫定とする（未決事項へ移動検討）

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 Permission Tier 分類（MUST）

| Tier | 規模 | 対象操作 | 承認 | 記録 |
|------|------|----------|------|------|
| **S** (Small) | 単一ファイル・局所変更 | 誤字修正、コメント追加、局所的バグ修正 | 不要 | evidence/に実行ログ |
| **M** (Medium) | 複数ファイル・機能追加 | Part内容充実、新機能追加、複数Part横断変更 | Fast Verify PASS必須 | evidence/にVerify結果 |
| **L** (Large) | 破壊的・全域・リリース・例外 | Part番号変更、全域用語変更、リリース確定、ADR例外 | HumanGate（2段階承認） | decisions/ または evidence/ |

### 5.2 HumanGate 対象操作（MUST）

以下の操作は **必ず** HumanGate（L Tier）を通す：

1. **破壊的操作**
   - Part番号・ファイル名変更（参照破壊リスク）
   - sources/ の削除・上書き（証跡消失）
   - 危険なgit操作（force push, hard reset, rebase -i, filter-branch, push --force-with-lease）
   - リリース済みバージョンの改変（タグ移動・削除）

2. **全域変更**
   - glossary/ 用語の大規模変更（全Part影響）
   - フォルダ構造変更（docs/, decisions/, evidence/, checks/ のリネーム・移動）
   - テンプレート・規約変更（全Part書式影響、CLAUDE.md改定）

3. **リリース確定**
   - Part xx を「確定版」としてgitタグ付け（v1.0.0等）
   - 外部公開・配布・APIリリース
   - バージョン番号確定（セマンティックバージョニング）

4. **例外・ポリシー変更**
   - ADR-0001, ADR-0002 自体の変更（メタガバナンス）
   - CLAUDE.md ルール変更（破壊防止原則の緩和等）
   - Verify条件の緩和・スキップ（Fast Verify必須を免除等）

### 5.3 危険コマンド記述禁止（MUST NOT）

以下のコマンドは **docs/ に生の文字列として記述禁止**（実行例外・監査ログでは表記崩しで記載）：

```
MUST NOT: git push --force, rm -rf sources/, DROP TABLE, DELETE FROM WHERE 1=1
表記崩し例: git push --f[削除禁止]orce, r[破壊]m -rf, DROP TA[危険]BLE
```

- 理由: 誤コピペ実行防止、検索時の誤検知回避
- 参照: decisions/0002-humangate-permission-tiers.md

### 5.4 2段階承認フロー（MUST for L Tier）

```
[提案] → [レビュー] → [承認] → [実行] → [記録]
```

#### 5.4.1 提案フェーズ
- **誰が**: Claude Code エージェント または 人間
- **何を**: decisions/ に提案ADR追加（状態: 提案）
- **いつ**: L Tier操作を検討した時点
- **証跡**: decisions/XXXX-proposal-description.md
- **記載内容**: 背景・決定内容・影響範囲・実行計画・ロールバック手順

#### 5.4.2 レビューフェーズ
- **誰が**: 人間レビュアー（開発者・PM・セキュリティ担当）
- **何を**: ADRレビュー、影響範囲確認、代替案検討、リスク評価
- **いつ**: 提案後24時間以内（SHOULD）
- **証跡**: ADR内にレビューコメント追記 or evidence/review-XXXX-YYYYMMDD.md
- **記載内容**: レビュー日時・レビュアー名・指摘事項・条件付き承認可否

#### 5.4.3 承認フェーズ
- **誰が**: 承認者（プロジェクトオーナー・テックリード）
- **何を**: ADRステータスを「承認」に変更、承認日時・承認者記録
- **いつ**: レビュー完了後、実行前（MUST）
- **証跡**: ADRヘッダーに「承認日時」「承認者」追記
- **記載内容**: 承認者名・承認日時・条件（あれば）

#### 5.4.4 実行フェーズ
- **誰が**: Claude Code エージェント
- **何を**: 承認されたADRに従ってdocs/変更、Fast Verify実行、git commit/push
- **いつ**: 承認後（承認なしで実行は禁止）
- **証跡**: evidence/execution-XXXX-YYYYMMDD.log
- **記載内容**: 実行日時・変更ファイルリスト・Fast Verify結果・コミットハッシュ

#### 5.4.5 記録フェーズ
- **誰が**: Claude Code エージェント
- **何を**: ADRに「結果」セクション追記、Verify証跡リンク、完了報告
- **いつ**: 実行完了後即座（MUST）
- **証跡**: ADR最終版（状態:承認→完了） + evidence/ 実行ログ
- **記載内容**: 実行結果・発見事項・改善提案・次回ADR候補

### 5.5 緊急時 事後承認（SHOULD for Emergency）

**緊急事態**（本番障害・セキュリティインシデント・データ損失危機）では、事前承認なしで実行可能。
ただし **24時間以内** に事後承認記録を残す（MUST）。

#### 5.5.1 緊急実行
1. 実行前に `evidence/emergency-YYYYMMDD-HHMM.md` 作成
2. 記載内容: 発生日時、緊急理由（障害内容）、実行操作、影響範囲、実行者
3. 実行後即座にコミット（メッセージ: "Emergency: [理由]"）
4. Slack/メール等で承認者へ緊急通知（MUST）

#### 5.5.2 事後承認
1. 24時間以内に decisions/ に事後承認ADR追加
2. ステータス: 「緊急承認（事後）」
3. レビュアー・承認者の追認署名を取得
4. 再発防止策を「結果」セクションに記載
5. 参照: evidence/emergency-YYYYMMDD-HHMM.md

### 5.6 HumanGate 記録の置き場所（MUST）

| 記録種別 | 保管場所 | ファイル名規約 | 保持期間 |
|---------|---------|----------------|----------|
| 提案ADR | decisions/ | XXXX-proposal-description.md | 永続 |
| 承認ADR | decisions/ | XXXX-approved-description.md（番号同一） | 永続 |
| レビュー記録 | evidence/ | review-XXXX-YYYYMMDD.md | 永続 |
| 実行ログ | evidence/ | execution-XXXX-YYYYMMDD.log | 永続 |
| 緊急対応 | evidence/ | emergency-YYYYMMDD-HHMM.md | 永続 |
| Verify証跡 | evidence/ | verify-partXX-YYYYMMDD.log | 永続 |

- XXXX: ADR番号（0001, 0002, ...）
- YYYYMMDD: 実行日（20260111等）
- HHMM: 実行時刻（緊急時のみ）

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 S Tier操作の実行手順
1. 変更対象ファイルを特定（単一ファイル・局所変更のみ）
2. 変更内容を確認（誤字修正・コメント追加・明らかなバグ修正）
3. 変更実行（Edit tool使用）
4. 実行ログを evidence/ に保存（`echo "操作内容" > evidence/edit-partXX-YYYYMMDD.log`）
5. git commit/push（メッセージ: "Fix typo in PartXX" 等）

### 6.2 M Tier操作の実行手順
1. 変更対象ファイルを特定（複数ファイル可）
2. 変更内容を確認（Part内容充実・新機能追加・横断変更）
3. 変更実行（Edit/Write tool使用）
4. **Fast Verify実行**（checks/fast-verify.sh または 同等ツール）
5. Verify結果を確認（**PASS必須**、FAILの場合は修正して再実行）
6. Verify証跡を evidence/ に保存（`verify-partXX-YYYYMMDD.log`）
7. git commit/push（メッセージ: "Add content to PartXX (Fast Verify PASS)" 等）

### 6.3 L Tier操作の実行手順（HumanGate）
1. **提案**: decisions/ に提案ADR作成（状態: 提案）
   - ファイル名: `XXXX-proposal-description.md`
   - 内容: 背景・決定・選択肢・影響範囲・実行計画・ロールバック
2. **レビュー依頼**: 人間レビュアーへ通知（Slack/Issue/PR）
3. **レビュー待機**: レビュアーがADRにコメント追記（24h以内目安）
4. **承認待機**: 承認者がADRステータスを「承認」に変更、承認日時・承認者記録
5. **実行**: 承認後、ADRに従って変更実行
6. **Fast Verify実行**（L Tierでも実行、PASS必須）
7. **Verify証跡4点収集**:
   - ① Part構造チェック（全セクション存在）
   - ② MUST/MUST NOT/SHOULD記法チェック
   - ③ 参照パス有効性チェック（decisions/XXXX存在）
   - ④ 未決事項チェック（推測禁止違反なし）
8. **証跡保存**: evidence/execution-XXXX-YYYYMMDD.log
9. **git commit/push**（メッセージ: "Execute ADR-XXXX: [description] (HumanGate approved)"）
10. **記録**: ADRに「結果」セクション追記、完了報告

### 6.4 緊急時 事後承認の実行手順
1. **緊急判断**: 本番障害・セキュリティインシデント・データ損失危機を確認
2. **緊急記録作成**: `evidence/emergency-YYYYMMDD-HHMM.md` 作成
3. **緊急実行**: 必要な操作を実行（破壊的操作含む）
4. **即座にコミット**: git commit/push（メッセージ: "Emergency: [理由]"）
5. **緊急通知**: Slack/メール等で承認者へ通知（MUST）
6. **24h以内事後ADR作成**: decisions/ に事後承認ADR追加
7. **追認取得**: レビュアー・承認者の署名取得
8. **再発防止策記載**: ADR「結果」セクションに記載

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 Fast Verify FAIL時（M/L Tier）
- **失敗分岐**: Verify FAILの場合、変更をコミットしない（MUST NOT）
- **復旧手順**:
  1. Verify結果（evidence/verify-partXX-YYYYMMDD.log）を確認
  2. 失敗箇所を修正（例: MUST記法漏れ、参照パス誤り）
  3. Fast Verify再実行
  4. PASS確認後、手順継続
- **エスカレーション**: 3回連続FAILの場合、人間レビュアーへ相談（Slack/Issue）

### 7.2 HumanGate承認拒否時（L Tier）
- **失敗分岐**: 承認者がADRを「却下」にステータス変更
- **復旧手順**:
  1. 却下理由をADR「結果」セクションに記録
  2. 代替案を検討（選択肢B/C等）
  3. 新規ADR提案（XXXX+1番号）
  4. 再レビュー・再承認フロー
- **エスカレーション**: プロジェクトオーナーへ最終判断依頼

### 7.3 緊急時24h以内事後承認取得失敗
- **失敗分岐**: 24時間以内に承認者から追認取得できず
- **復旧手順**:
  1. 緊急実行をgit revert（可能なら）
  2. 承認者へ再通知（電話・直接連絡）
  3. 承認取得後、再実行（通常L Tierフロー）
- **エスカレーション**: プロジェクトオーナー・セキュリティ担当へ報告

### 7.4 破壊的操作の誤実行（sources/ 削除等）
- **失敗分岐**: sources/ を誤って削除・上書き
- **復旧手順**:
  1. git履歴から即座に復元（`git checkout HEAD~1 -- sources/`）
  2. 復元確認（`git diff HEAD sources/`）
  3. 緊急記録作成（evidence/emergency-YYYYMMDD-HHMM.md）
  4. 事後承認ADR作成
- **エスカレーション**: 復元不可の場合、プロジェクトオーナーへ即時報告

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 Fast Verify 判定条件（M/L Tier共通）

| 検証項目 | 判定条件 | 合否 | ログ出力 |
|---------|---------|------|---------|
| ① Part構造チェック | 全セクション（0-12）存在 | 12個全てあればPASS | `[PASS] Part09: All sections present` |
| ② MUST記法チェック | ルールセクションに MUST/MUST NOT/SHOULD 存在 | 1個以上あればPASS | `[PASS] Part09: MUST rules found (count: X)` |
| ③ 参照パス有効性 | 参照セクションのパスが実在 | 全パス存在でPASS | `[PASS] Part09: All refs valid (decisions/0002 exists)` |
| ④ 未決事項チェック | 未決事項に「推測」「たぶん」「おそらく」等の推測語なし | 推測語0個でPASS | `[PASS] Part09: No speculation in open items` |

### 8.2 Fast Verify 実行方法（未作成時は手動確認）

```bash
# checks/fast-verify.sh が存在する場合
cd /home/user/Claud1
bash checks/fast-verify.sh docs/Part09.md > evidence/verify-part09-$(date +%Y%m%d).log 2>&1
echo $? # 0ならPASS、非0ならFAIL

# checks/ 未作成時の手動確認（暫定）
# ① セクション数確認
grep -c '^## ' docs/Part09.md # 13行（0-12セクション）あればPASS

# ② MUST記法確認
grep -E 'MUST|MUST NOT|SHOULD' docs/Part09.md | wc -l # 1行以上でPASS

# ③ 参照パス確認
grep -oP 'decisions/\d{4}' docs/Part09.md | xargs -I{} test -f {}.md && echo PASS

# ④ 推測語確認
grep -iE '推測|たぶん|おそらく|maybe|probably' docs/Part09.md | wc -l # 0行でPASS
```

### 8.3 Verify証跡4点の保存形式

```
# evidence/verify-part09-20260111.log
[2026-01-11 14:30:00] Fast Verify START: Part09
[PASS] ① Part構造チェック: 13セクション検出（0-12）
[PASS] ② MUST記法チェック: MUST/MUST NOT/SHOULD 45箇所検出
[PASS] ③ 参照パス有効性: decisions/0002-humangate-permission-tiers.md 存在確認
[PASS] ④ 未決事項チェック: 推測語0件
[2026-01-11 14:30:01] Fast Verify RESULT: PASS (4/4)
```

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 S Tier監査証跡
- **実行ログ**: evidence/edit-partXX-YYYYMMDD.log
- **記載内容**: 変更日時・変更ファイル・変更内容（diff）・実行者（エージェントID）
- **保持期間**: 永続（削除禁止）

### 9.2 M Tier監査証跡
- **Verify結果**: evidence/verify-partXX-YYYYMMDD.log
- **記載内容**: Verify実行日時・判定結果（PASS/FAIL）・検証項目4点
- **保持期間**: 永続（削除禁止）

### 9.3 L Tier監査証跡（HumanGate）
- **提案ADR**: decisions/XXXX-proposal-description.md
- **レビュー記録**: evidence/review-XXXX-YYYYMMDD.md（または ADR内コメント）
- **承認記録**: ADRヘッダーに「承認日時」「承認者」
- **実行ログ**: evidence/execution-XXXX-YYYYMMDD.log
- **Verify証跡**: evidence/verify-partXX-YYYYMMDD.log
- **保持期間**: 永続（削除禁止）

### 9.4 緊急時監査証跡
- **緊急記録**: evidence/emergency-YYYYMMDD-HHMM.md
- **事後ADR**: decisions/XXXX-emergency-description.md（ステータス: 緊急承認（事後））
- **追認署名**: ADR「結果」セクションに承認者・レビュアー署名
- **保持期間**: 永続（削除禁止）

### 9.5 監査時の確認項目
1. L Tier操作に対応するADRが存在するか
2. ADRステータスが「承認」または「緊急承認（事後）」か
3. Fast Verify証跡4点が全てPASSか
4. 実行ログと git commit が紐付いているか（コミットハッシュ記録）
5. 緊急対応の場合、24h以内に事後ADR作成されているか

## 10. チェックリスト

### 10.1 S Tier操作チェックリスト
- [ ] 変更対象が単一ファイル・局所変更である
- [ ] 実行ログを evidence/ に保存した
- [ ] git commit メッセージが明確である

### 10.2 M Tier操作チェックリスト
- [ ] 変更対象が複数ファイル・機能追加・横断変更である
- [ ] Fast Verify を実行した
- [ ] Fast Verify が PASS した
- [ ] Verify証跡を evidence/ に保存した
- [ ] git commit メッセージに "Fast Verify PASS" を含めた

### 10.3 L Tier操作チェックリスト（HumanGate）
- [ ] 提案ADRを decisions/ に作成した（状態: 提案）
- [ ] レビュアーへ通知した
- [ ] レビューコメントを受領した
- [ ] 承認者がADRを「承認」にした
- [ ] 承認後に変更実行した（事前実行禁止）
- [ ] Fast Verify を実行し PASS した
- [ ] Verify証跡4点を収集した
- [ ] 実行ログを evidence/ に保存した
- [ ] git commit メッセージに "ADR-XXXX" と "HumanGate approved" を含めた
- [ ] ADRに「結果」セクションを追記した

### 10.4 緊急時チェックリスト
- [ ] 緊急記録を evidence/ に作成した
- [ ] 緊急実行前に承認者へ通知した（可能な限り）
- [ ] 緊急実行後即座にコミットした
- [ ] 24時間以内に事後ADRを作成した
- [ ] レビュアー・承認者の追認を取得した
- [ ] 再発防止策をADRに記載した

### 10.5 DoD（Definition of Done: 運用観点）
- [ ] Permission Tier（S/M/L）を正しく判定した
- [ ] M Tier以上はFast Verify PASS を確認した
- [ ] L TierはHumanGate（2段階承認）を完了した
- [ ] 全ての証跡を evidence/ または decisions/ に保存した
- [ ] git履歴を破壊していない（force push未使用）
- [ ] 危険コマンドを生文字列で記述していない
- [ ] 未決事項に推測を含めていない
- [ ] 参照パス（decisions/0002等）が有効である

## 11. 未決事項（推測禁止）

- Part02（用語集）未作成のため、本Part「4. 用語」を暫定定義とする（Part02作成後に移動検討）
- checks/fast-verify.sh 未作成のため、「8.2 Fast Verify実行方法」の手動確認を暫定とする（checks/作成後に更新）
- Part08（Verify詳細）未作成のため、Fast Verify詳細仕様は本Partに簡易記載（Part08作成後に参照へ変更）
- 緊急時通知手段（Slack/メール）の具体的連絡先は別途決定（evidence/contacts.md 等に記載予定）

## 12. 参照（パス）

### docs/
- Part00: ドキュメント憲法・SSOT原則・破壊防止ルール（参照: docs/Part00.md）
- Part02: 用語集（未作成、作成後に本Part「4. 用語」を移動）
- Part08: Verify詳細仕様（未作成、作成後にFast Verify詳細を参照）

### decisions/
- ADR-0001: SSOT運用ガバナンス（ADR→docs原則）（参照: decisions/0001-ssot-governance.md）
- ADR-0002: HumanGate・Permission Tier詳細（本Part根拠）（参照: decisions/0002-humangate-permission-tiers.md）

### evidence/
- edit-partXX-YYYYMMDD.log: S Tier実行ログ
- verify-partXX-YYYYMMDD.log: M/L Tier Fast Verify証跡
- review-XXXX-YYYYMMDD.md: L Tierレビュー記録
- execution-XXXX-YYYYMMDD.log: L Tier実行ログ
- emergency-YYYYMMDD-HHMM.md: 緊急時記録

### checks/
- fast-verify.sh: Fast Verify自動実行スクリプト（未作成、作成後に参照）

### CLAUDE.md
- 破壊防止絶対ルール（sources/改変禁止、推測禁止、Part番号変更禁止、ADR→docs原則）
