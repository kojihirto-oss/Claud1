# Part 10：Verify Gate（Fast/Full・必須カテゴリ・Verifyレポート・機械判定の裁定）

## 0. このPartの位置づけ
- 目的：SSOT破壊を防ぐための品質ゲート（Verify）の実行手順・判定基準・証跡管理を定義
- 依存：Part00（SSOT原則）、Part09（Permission Tier）、checks/verify_repo.ps1
- 影響：全ての docs/ 変更作業、git commit前の必須ゲート、evidence/verify_reports の管理

## 1. 目的（Purpose）

### 1.1 Verifyの役割
Verify Gateは、リポジトリの整合性を機械的に検証し、以下を保証する：
- **SSOT破壊の防止**：docs/ 内のリンク切れ、Part間矛盾、sources/ 改変を検出
- **事故ゼロの作業フロー**：コミット前に必ず検証を通すことで、壊れた状態のマージを防ぐ
- **証跡の保持**：検証結果を evidence/verify_reports に保存し、監査可能にする

### 1.2 位置づけ
- **必須ゲート**：全ての docs/ 変更において、git commit 前に Verify Fast PASS が必須（DoD）
- **HumanGateとの連携**：Verify FAIL時は原則コミット禁止（例外は HumanGate で「障害解析のため保持」を許可した場合のみ）

## 2. 適用範囲（Scope / Out of Scope）

### In Scope
- docs/ 配下の全ファイル変更時の検証
- sources/ の改変検出（読み取り専用の保証）
- evidence/verify_reports の証跡管理（保持ルール、採用ルール）
- Fast/Full の2モード定義（Fullは将来拡張）

### Out of Scope
- CI/CD環境での自動実行（将来的に導入可能だが本Partでは手動実行を標準とする）
- sources/ の内容妥当性検証（改変検出のみ、内容の真偽は検証しない）
- glossary/ の用語整合性（将来拡張候補）

## 3. 前提（Assumptions）

- Windows環境で PowerShell 7+ が利用可能（pwsh コマンド）
- Linux/macOS環境では pwsh または同等のシェルスクリプト版を使用（将来対応）
- checks/verify_repo.ps1 が実装済みであること
- evidence/verify_reports ディレクトリが存在すること（初回実行時に自動作成も可）

## 4. 用語（Glossary参照：Part02）

- **Verify Fast**：必須項目のみ検証（リンク、Part整合、sources改変、禁止文字列）。所要時間 < 30秒
- **Verify Full**：Fast + 追加検証（用語揺れ、未決事項集計、外部URL生存確認）。所要時間 数分（将来実装）
- **PASS**：全検証項目が合格。コミット可能
- **FAIL**：1つ以上の検証項目が不合格。原則コミット禁止
- **証跡セット**：1回のverify実行で生成される4つのレポートファイル（link/parts/forbidden/sources_integrity）

## 5. ルール（MUST / MUST NOT / SHOULD）

### 5.1 実行タイミング
- **MUST**：docs/ を変更した場合、git commit 前に Verify Fast を **1回だけ** 実行する
- **MUST NOT**：作業途中で verify を何度も実行しない（証跡が量産され、どれが最終かわからなくなる）
- **SHOULD**：verify 実行は「作業完了・コミット直前」のタイミングに限定する

### 5.2 PASS時の扱い
- **MUST**：Verify PASS の証跡セット（4ファイル）を git add でステージングに含める
- **SHOULD**：evidence/verify_reports には「最新PASS 1セットのみ」を追加する（過去分は削除推奨）
- **MAY**：運用上の理由で「直近3セットまで」を保持してもよい（それ以上は `git r m` で整理する）

### 5.3 FAIL時の扱い
- **MUST NOT**：Verify FAIL の状態では git commit しない（例外：HumanGate承認あり）
- **MUST**：FAIL原因を修正し、再度 Verify Fast を実行してPASSを確認する
- **SHOULD**：FAIL時の証跡は git add せず、未追跡のまま残す（または削除する）
- **例外（HumanGate）**：障害解析目的でFAIL証跡を保持する場合、decisions/ にADRを追加してから保持する

### 5.4 sources/ 改変の禁止
- **MUST NOT**：sources/ 配下のファイルは一切変更・削除・上書きしない（追記のみ許可）
- **MUST**：Verify は sources/ の改変を検出し、FAIL とする

### 5.5 危険コマンドの検出
- **MUST NOT**：docs/ 内に危険なコマンド文字列（`r m - r f`、`git push - - f orce`、`git reset - - h ard`、`curl | s h` など）を生で記述しない
- **MUST**：Verify は禁止文字列パターンを検出し、FAIL とする
- **SHOULD**：危険コマンドを説明する場合は表記崩し（スペース挿入、ハイフン分離など）を使用する

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 標準作業フロー（事故らない順）
以下の順序を厳守することで、壊れた状態のコミット・プッシュを防ぐ。

1. **git fetch/pull**（最新状態を取得）
   ```powershell
   git fetch origin
   git pull origin <branch-name>
   ```

2. **作業実施**（docs/ の編集、Part追加など）
   - Part00-20 の編集
   - 新規 Part 追加（必要に応じて）
   - sources/ は読み取りのみ（変更禁止）

3. **Verify Fast 実行（1回のみ）**
   ```powershell
   pwsh .\checks\verify_repo.ps1 -Mode Fast
   ```
   - 実行完了まで待機（通常 < 30秒）
   - 出力メッセージで PASS/FAIL を確認

4. **PASS確認と証跡追加**
   - PASSの場合：
     ```powershell
     git add evidence/verify_reports/*
     ```
   - FAILの場合：手順7（例外処理）へ

5. **変更ファイルのステージング**
   ```powershell
   git add docs/Part10.md  # 変更したPartを追加
   git status -sb          # ステージング内容を確認
   ```

6. **コミット**
   ```powershell
   git commit -m "Part10: standardize Verify Gate + evidence retention (Fast verify PASS 2026-01-11)"
   ```
   - コミットメッセージは「Part番号: 変更概要 (Fast verify PASS YYYY-MM-DD)」形式を推奨

7. **プッシュ**
   ```powershell
   git push -u origin <branch-name>
   ```
   - ネットワークエラー時は最大4回リトライ（2秒、4秒、8秒、16秒の指数バックオフ）

### 6.2 Verify実行の詳細

#### Fast モード（標準・必須）
```powershell
pwsh .\checks\verify_repo.ps1 -Mode Fast
```
**検証項目**：
1. **リンク整合性**（link_check）：docs/ 内の相対パス・Part参照が切れていないか
2. **Part間整合性**（parts_integrity）：Part00-20 のテンプレート構造、相互参照の矛盾
3. **禁止文字列検出**（forbidden_patterns）：危険コマンド、禁止表記の有無
4. **sources改変検出**（sources_integrity）：sources/ のハッシュ値チェック

**出力**：
- `evidence/verify_reports/YYYYMMDD_HHMMSS_link_check.txt`
- `evidence/verify_reports/YYYYMMDD_HHMMSS_parts_integrity.txt`
- `evidence/verify_reports/YYYYMMDD_HHMMSS_forbidden_patterns.txt`
- `evidence/verify_reports/YYYYMMDD_HHMMSS_sources_integrity.txt`

**判定**：4項目すべてが合格で PASS、1つでも不合格で FAIL

#### Full モード（将来拡張）
```powershell
pwsh .\checks\verify_repo.ps1 -Mode Full
```
**追加検証項目**（未実装）：
- 用語揺れ検出（glossary/ と docs/ の不一致）
- 未決事項集計（Part別の未決リスト）
- 外部URL生存確認（HTTP 200応答チェック）
- ADR参照整合性（decisions/ と docs/ のリンク）

**所要時間**：数分（外部URL確認が含まれるため）

### 6.3 証跡の保持・削除ルール

#### 推奨（最新1セットのみ）
- **保持**：最新のPASS証跡セット（4ファイル）のみをgit管理下に置く
- **削除**：過去のPASS証跡は `git r m evidence/verify_reports/2026*` で削除してOK
- **理由**：証跡履歴はgit logで追跡可能。大量の証跡ファイルは可読性を下げる

#### 許容（直近3セットまで）
- **保持**：運用上の理由で直近3セットまで保持可能（監査要件など）
- **整理**：4セット目以降は削除する
- **コマンド例**：
  ```powershell
  # 古い証跡を削除（手動で日付を指定）
  git r m evidence/verify_reports/20260108_*
  ```

#### 禁止（FAIL証跡の混入）
- **MUST NOT**：FAIL証跡を誤ってコミットしない
- **確認方法**：
  ```powershell
  git status -sb
  # evidence/verify_reports/ のファイル名に PASS/FAIL が含まれているか確認
  ```

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 7.1 Verify FAIL時の対処

#### FAIL原因の分類
1. **リンク切れ**：docs/ 内の `[Part01](Part01.md)` などが不正
   - 修正：パスを正しく修正し、再verify
2. **sources改変**：sources/ を誤って編集した
   - 修正：`git checkout sources/` で復元し、再verify
3. **禁止文字列**：危険コマンドが生で記述されている
   - 修正：表記崩しに変更（例：`r m - r f`）し、再verify
4. **Part間矛盾**：Part00の原則とPart10が衝突している
   - エスカレーション：HumanGateで方針を決定 → decisions/ にADR追加 → 修正

#### 復旧手順
1. FAIL原因を `evidence/verify_reports/*_YYYYMMDD_HHMMSS.txt` から特定
2. 該当ファイルを修正
3. 再度 `pwsh .\checks\verify_repo.ps1 -Mode Fast` を実行
4. PASS確認後、手順6.1の4番（証跡追加）から再開

### 7.2 例外承認（HumanGate）

以下の場合のみ、FAIL状態でのコミットを許可する：
- **障害解析目的**：FAIL証跡を保持して原因調査を行う必要がある
- **条件**：
  1. decisions/ に ADR を追加（例：`ADR-00XX-exception-verify-fail-for-analysis.md`）
  2. ADR に FAIL理由、保持期間、削除予定日を明記
  3. コミットメッセージに `[HumanGate approved]` を付記

### 7.3 スクリプトエラー時の対処

verify_repo.ps1 が異常終了した場合：
1. エラーメッセージを確認
2. PowerShell バージョン確認（pwsh 7+ 必須）
3. 再実行してもエラーが続く場合：
   - checks/README.md の手動検証手順を実施（フォールバック）
   - 問題をIssue登録し、スクリプト修正を依頼

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### 8.1 link_check（リンク整合性）
- **判定条件**：docs/ 内の `[テキスト]\(パス\)` がすべて有効
- **合格**：リンク切れ0件
- **不合格**：リンク切れ1件以上
- **ログ出力例**：
  ```
  [PASS] link_check: All internal links are valid (0 broken links)
  ```

### 8.2 parts_integrity（Part整合性）
- **判定条件**：Part00-20 がテンプレート構造に従い、相互参照が矛盾しない
- **合格**：構造違反0件
- **不合格**：構造違反1件以上
- **ログ出力例**：
  ```
  [PASS] parts_integrity: All Parts follow template structure
  ```

### 8.3 forbidden_patterns（禁止文字列検出）
- **判定条件**：docs/ 内に危険コマンド文字列が生で記述されていない
- **合格**：禁止パターン検出0件
- **不合格**：禁止パターン検出1件以上
- **ログ出力例**：
  ```
  [FAIL] forbidden_patterns: Found 'r m - r f' in docs/Part10.md:123
  ```

### 8.4 sources_integrity（sources改変検出）
- **判定条件**：sources/ 配下のファイルハッシュが前回commit時と一致
- **合格**：改変0件
- **不合格**：改変1件以上
- **ログ出力例**：
  ```
  [FAIL] sources_integrity: sources/data.json was modified
  ```

### 8.5 総合判定
- **PASS**：4項目すべてが合格
- **FAIL**：1項目でも不合格

## 9. 監査観点（Evidenceに残すもの・参照パス）

### 9.1 証跡ファイル命名規則
```
evidence/verify_reports/YYYYMMDD_HHMMSS_<category>.txt
```
- **YYYYMMDD**：実行日（例：20260111）
- **HHMMSS**：実行時刻（例：143052）
- **category**：検証カテゴリ（link_check / parts_integrity / forbidden_patterns / sources_integrity）

### 9.2 証跡セットの構成
1回のverify実行で以下4ファイルが生成される：
1. `YYYYMMDD_HHMMSS_link_check.txt`
2. `YYYYMMDD_HHMMSS_parts_integrity.txt`
3. `YYYYMMDD_HHMMSS_forbidden_patterns.txt`
4. `YYYYMMDD_HHMMSS_sources_integrity.txt`

### 9.3 証跡の採用ルール
- **標準**：最新PASS 1セットのみをgit管理下に置く
- **許容**：直近3セットまで保持可能
- **禁止**：FAIL証跡をコミットしない（例外：HumanGate承認あり）

### 9.4 監査時の参照方法
```powershell
# 最新の証跡を確認
ls evidence/verify_reports/ | Sort-Object -Descending | Select-Object -First 4

# 特定日時の証跡を確認
cat evidence/verify_reports/20260111_143052_link_check.txt
```

## 10. チェックリスト

作業完了前に以下を確認する：
- [ ] docs/ の変更が完了している
- [ ] sources/ は一切変更していない（読み取りのみ）
- [ ] `pwsh .\checks\verify_repo.ps1 -Mode Fast` を **1回だけ** 実行した
- [ ] Verify結果が **PASS** である
- [ ] evidence/verify_reports に最新PASS 4ファイルが生成されている
- [ ] 過去の証跡は削除した（または直近3セットまで保持）
- [ ] `git add evidence/verify_reports/*` で証跡をステージングした
- [ ] `git add docs/Part10.md` など変更ファイルをステージングした
- [ ] `git status -sb` でステージング内容を確認した
- [ ] コミットメッセージに "(Fast verify PASS YYYY-MM-DD)" を含めた
- [ ] Part10.md が他Part（Part00, Part09）と矛盾していない

## 11. 未決事項（推測禁止）

現時点で確定していない項目：
- **Verify Full の詳細仕様**：用語揺れ検出、未決事項集計の具体的アルゴリズム（将来実装）
- **Linux/macOS対応**：pwsh 以外の環境での verify 実行方法（シェルスクリプト版を検討中）
- **CI/CD統合**：GitHub Actions などでの自動実行タイミング・失敗時の通知方法（将来検討）

### 運用上の選択肢（HumanGateで決定）
- **証跡保持数**：「最新1セット」vs「直近3セット」
  - 推奨：最新1セット（シンプル・可読性優先）
  - 許容：直近3セット（監査要件がある場合）
- **FAIL証跡の扱い**：「即削除」vs「未追跡で残す」vs「別ディレクトリ退避」
  - 推奨：未追跡で残す（障害解析時に参照可能）
  - 許容：即削除（証跡量産を防ぐ）

## 12. 参照（パス）

### docs/
- [Part00.md](Part00.md) — SSOT原則、禁止事項
- [Part09.md](Part09.md) — Permission Tier、HumanGate
- [00_INDEX.md](00_INDEX.md) — 全体導線

### sources/
- （現時点で参照なし。将来、verify仕様の根拠となる会話ログを追加予定）

### evidence/
- `evidence/verify_reports/` — Verify実行結果の証跡（本Part定義に従い生成）

### decisions/
- [0001-ssot-governance.md](../decisions/0001-ssot-governance.md) — SSOT運用ガバナンス
- （将来、verify例外承認のADRを追加予定）

### checks/
- `checks/verify_repo.ps1` — Verify Fast/Full の実行スクリプト（本Part定義に準拠）
- [checks/README.md](../checks/README.md) — 検証手順の概要
