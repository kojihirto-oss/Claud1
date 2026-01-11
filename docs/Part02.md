# Part 02：共通語彙（用語固定で迷いを消す：SSOT/VAULT/RELEASE/DoD/ADR/Permission Tier等）

## 0. このPartの位置づけ
- 目的：プロジェクト全体で使用する用語を統一し、表記揺れ・認識齟齬を排除する
- 依存：glossary/GLOSSARY.md（用語の唯一定義）
- 影響：全Part（用語の参照元）、checks/（用語揺れ検証）

## 1. 目的（Purpose）

このPartは、プロジェクト全体で使用する **共通語彙（用語）** を定義し、表記揺れを防ぐための唯一の正（SSOT）を提供する。
- 用語の表記・意味・使用例を明確化
- Part 間の認識齟齬を防止
- 新規参加者の学習コストを低減

## 2. 適用範囲（Scope / Out of Scope）

### Scope
- プロジェクト固有の用語（SSOT、Permission Tier、HumanGate等）
- 技術用語の本プロジェクトにおける定義（Verify Gate、Evidence Pack等）
- 略語・頭字語の展開（ADR、DoD等）

### Out of Scope
- 一般的なIT用語（Git、Markdown等）の基本的な説明
- プログラミング言語固有の用語（本プロジェクトではドキュメント中心のため）

## 3. 前提（Assumptions）

1. 用語の唯一定義は **glossary/GLOSSARY.md** に配置される
2. Part02 は GLOSSARY.md の内容を補足・詳細化する
3. すべての Part は Part02 で定義された用語を使用する
4. 用語の追加・変更は Part02 と GLOSSARY.md を同期する

## 4. 用語（Glossary参照：Part02）

本Partが用語定義の基準となるため、セクション4は自己参照となる。
各用語の詳細はセクション5以降を参照。

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 用語使用のルール

- **MUST**: すべての Part は Part02 で定義された用語を使用する
- **MUST**: 用語の表記は Part02 の定義に完全一致させる（大文字/小文字、略語展開を含む）
- **MUST NOT**: Part02 で定義されていない用語を独自に定義しない（Part02 に追加する）
- **SHOULD**: 新規用語の追加時は、既存用語との重複・類似を確認する

### 5.2 用語の定義

#### SSOT (Single Source of Truth)
- **定義**: 唯一の正である情報源。本プロジェクトでは **docs/** が SSOT。
- **使用例**: 「SSOT である docs/ を変更する際は ADR を先に作成する」
- **関連**: ADR-0001（decisions/0001-ssot-governance.md）

#### Permission Tier
- **定義**: AI Agent/CLI/IDE による作業の権限階層。ReadOnly / PatchOnly / ExecLimited / HumanGate の4段階。
- **使用例**: 「この操作は ExecLimited Tier が必要」
- **詳細**: Part09（Permission Tier設計）
- **関連用語**: HumanGate、ReadOnly、PatchOnly、ExecLimited

#### HumanGate
- **定義**: 人間による明示的な承認が必要な操作。Permission Tier の最上位。
- **使用例**: 「ADR の作成は HumanGate が必要」
- **詳細**: Part09 セクション 5.1.4（Tier 4: HumanGate）
- **関連用語**: Permission Tier、承認プロセス

#### DoD (Definition of Done)
- **定義**: 作業完了の判定基準。以下の4項目：
  1. DoD-1: 差分明確化
  2. DoD-2: Verify PASS
  3. DoD-3: Evidence Pack 生成
  4. DoD-4: Commit/Push 完了
- **使用例**: 「DoD をすべて満たすまで完了としない」
- **詳細**: Part09 セクション 5.2（DoD の基準）

#### Verify Gate
- **定義**: 品質ゲート。Fast Verify（4点チェック）と Full Verify（詳細検証）の2種類。
- **使用例**: 「変更後は Fast Verify を実行する」
- **詳細**: Part10（Verify Gate設計）
- **関連用語**: Fast Verify、Full Verify

#### Fast Verify
- **定義**: 必須4点チェック（リンク切れ/用語揺れ/Part間整合/未決事項）による簡易検証。
- **使用例**: 「DoD-2 では Fast Verify の PASS が必須」
- **詳細**: Part09 セクション 6.2（Fast Verify の実行手順）
- **関連用語**: Verify Gate、Full Verify

#### Full Verify
- **定義**: 詳細検証。Fast Verify に加えて追加の検証項目を実施（詳細は Part10 で定義予定）。
- **使用例**: 「重要な変更時は Full Verify を実行すべき」
- **詳細**: Part10（未定義）
- **関連用語**: Verify Gate、Fast Verify

#### Evidence Pack
- **定義**: 作業の証跡パッケージ。変更差分/Verify レポート/実行ログ/承認記録（該当時）を含む。
- **使用例**: 「DoD-3 では Evidence Pack の生成が必須」
- **詳細**: Part09 セクション 9.1（必須 Evidence）
- **関連用語**: DoD、監査、証跡

#### ADR (Architecture Decision Record)
- **定義**: 意思決定記録。仕様/運用の変更は必ず **decisions/** に ADR を追加してから docs/ を変更する。
- **使用例**: 「SSOT運用ルールの変更には新規 ADR が必要（HumanGate）」
- **詳細**: decisions/ADR_TEMPLATE.md
- **関連用語**: SSOT、HumanGate

#### ReadOnly
- **定義**: Permission Tier の Tier 1。ファイル読み取り・検索・分析のみ実行可能。
- **使用例**: 「sources/ は ReadOnly のため改変禁止」
- **詳細**: Part09 セクション 5.1.1（Tier 1: ReadOnly）
- **関連用語**: Permission Tier、sources/

#### PatchOnly
- **定義**: Permission Tier の Tier 2。既存ファイルへの差分適用（Edit）のみ実行可能。
- **使用例**: 「docs/Part*.md の更新は PatchOnly で実行」
- **詳細**: Part09 セクション 5.1.2（Tier 2: PatchOnly）
- **関連用語**: Permission Tier、Edit

#### ExecLimited
- **定義**: Permission Tier の Tier 3。限定的な実行（新規ファイル作成、Git操作等）が可能。
- **使用例**: 「新規 Part の作成は ExecLimited が必要」
- **詳細**: Part09 セクション 5.1.3（Tier 3: ExecLimited）
- **関連用語**: Permission Tier、Git操作

#### 1Part=1Branch 原則
- **定義**: 並列タスク運用の型。1つのブランチで編集する Part は最大1つ（必要最小限の共有ファイルを除く）。
- **使用例**: 「1Part=1Branch 原則により、Part09 の編集は専用ブランチで実施」
- **詳細**: Part09 セクション 5.3（並列タスク運用の型）
- **関連用語**: 並列タスク、ブランチ戦略

#### VAULT
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

#### RELEASE
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

#### WORK
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

#### RFC
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

#### VIBEKANBAN
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

#### Context Pack
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

#### Patchset
- **定義**: （未定義、今後追加予定）
- **使用例**: -
- **詳細**: -

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 新規用語の追加手順

1. **用語の必要性を確認**
   - 既存用語で代替できないか確認
   - 類似用語との重複を確認（Part02 全体を検索）

2. **用語定義の作成**
   - 定義：明確かつ簡潔に（1〜2文）
   - 使用例：実際の使用例を1つ以上記載
   - 詳細：詳細説明がある Part/セクションへの参照
   - 関連用語：関連する用語をリストアップ

3. **Part02 への追加**
   - セクション 5.2（用語の定義）に追記（アルファベット順/五十音順）
   - GLOSSARY.md にも同期追加

4. **Verify 実行**
   - Fast Verify（用語揺れチェック）を実行
   - Part02 追加後、他の Part で用語が正しく使用されているか確認

5. **Commit/Push**
   - 変更を commit（メッセージ例：「Add term: [用語名] to Part02」）

### 6.2 用語の修正手順

1. **修正理由の明確化**
   - なぜ修正が必要か（表記揺れ、意味の不明確さ等）
   - 影響範囲の確認（どの Part で使用されているか）

2. **Part02 の修正**
   - セクション 5.2 の該当用語を修正
   - GLOSSARY.md にも同期修正

3. **他 Part の更新**
   - 修正した用語を使用している Part を検索（Grep ツール使用）
   - 必要に応じて他 Part も更新（表記統一）

4. **Verify 実行**
   - Fast Verify（用語揺れチェック）を実行
   - 全 Part で用語が統一されているか確認

5. **Commit/Push**
   - 変更を commit（メッセージ例：「Update term: [用語名] in Part02 and related Parts」）

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 用語揺れの検出

**検出条件**：
- Fast Verify の用語揺れチェックで FAIL
- 同じ概念を表す複数の表記が存在

**対処**：
1. 揺れている用語をリストアップ
2. Part02 の定義を確認（正しい表記を特定）
3. 誤った表記を使用している Part を修正
4. 再度 Fast Verify を実行

### 7.2 未定義用語の使用

**検出条件**：
- Part02 で定義されていない用語が docs/ 内で使用されている

**対処**：
1. 用語が必要か判断（一般的なIT用語なら定義不要の可能性）
2. 定義が必要な場合、セクション 6.1 の手順で追加
3. 不要な場合、他の表現に置き換え

### 7.3 用語の重複定義

**検出条件**：
- 複数の Part で同じ用語が異なる意味で定義されている

**対処**：
1. Part02 での定義を確認（Part02 が正）
2. 他 Part の独自定義を削除
3. Part02 への参照に置き換え

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 用語揺れの判定

| 項目 | 判定条件 | PASS | FAIL |
|------|----------|------|------|
| 表記統一 | Part02 の用語定義と docs/ 内の使用が一致 | 揺れ 0件 | 揺れ 1件以上 |
| 未定義用語 | docs/ 内の専門用語がすべて Part02 に定義されている | 未定義 0件 | 未定義 1件以上 |

### 8.2 用語定義の完全性

| 項目 | 判定条件 | PASS | WARN |
|------|----------|------|------|
| 定義の存在 | すべての用語に「定義」セクションがある | 100% | 90%未満 |
| 使用例の存在 | すべての用語に「使用例」がある | 100% | 90%未満 |

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 用語追加・修正時の Evidence

- 変更差分（Part02 の before/after）
- 影響範囲（修正した用語を使用している Part のリスト）
- Verify レポート（用語揺れチェックの結果）

### 9.2 定期監査

- **SHOULD**: 四半期ごとに Part02 の完全性を監査
  - 未定義用語の洗い出し
  - 使用頻度の低い用語の削除検討
  - 新規追加すべき用語の検討

## 10. チェックリスト

新規用語追加・修正時：

- [ ] 既存用語との重複・類似を確認した
- [ ] 定義を明確かつ簡潔に記述した（1〜2文）
- [ ] 使用例を1つ以上記載した
- [ ] 詳細説明への参照（Part/セクション）を記載した
- [ ] 関連用語をリストアップした
- [ ] GLOSSARY.md にも同期追加/修正した
- [ ] Fast Verify（用語揺れチェック）を実行し PASS を確認した
- [ ] 影響範囲（他 Part での使用）を確認した
- [ ] Commit/Push を完了した

## 11. 未決事項（推測禁止）

- VAULT、RELEASE、WORK、RFC、VIBEKANBAN、Context Pack、Patchset の定義（今後追加予定）
- 用語の使用頻度分析（どの用語が頻繁に使用されているか）
- 用語集の多言語対応（必要性の検討）
- 自動用語揺れチェックツールの実装（checks/ で今後開発）

## 12. 参照（パス）

- glossary/GLOSSARY.md（用語の唯一定義）
- docs/Part00.md（前提・目的）
- docs/Part09.md（Permission Tier設計）
- docs/Part10.md（Verify Gate設計）
- checks/README.md（検証手順、用語揺れチェック）
- decisions/0001-ssot-governance.md（SSOT運用ガバナンス）
