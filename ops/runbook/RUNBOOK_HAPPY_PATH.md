# RUNBOOK: Happy Path（標準運用レーン）

## 0. このRunbookの目的
迷いなく、最速で、安全にタスクを完了させるための「唯一の正解ルート」。
**原則**: このルートを外れる場合は `Break-glass`（例外手順）となる。

---

## 1. ワークフロー（Happy Path）

### Step 1: 準備 (Prepare)
- [ ] **作業ブランチ作成**: `git switch -c feature/<client>_<description>`
- [ ] **worktree隔離**: `git worktree add ../worktree_<id> feature/<id>` (推奨)
- [ ] **TICKET作成**: `ops/vibekanban/lanes/100_SPEC/` に TICKET-XXX.md を作成
  - 必須項目: Goal, Acceptance, Plan, Verify, Evidence

### Step 2: 設計・仕様 (Spec/Design)
- [ ] **Spec凍結**: TICKETの内容を確定させる
- [ ] **ADR作成** (必要な場合): `decisions/ADR-XXXX.md`
  - 必須: `Status: Proposed`, `Enforcement`

### Step 3: 実装 (Build/Edit)
- [ ] **Docs更新**: `docs/PartXX.md` を編集 (PatchOnly)
- [ ] **ローカル検証**: `pwsh checks/verify_repo.ps1 Fast` (推奨)
  - → 失敗したら修正 (VRループ)

### Step 4: 検証・証跡 (Verify/Evidence)
- [ ] **Verify実行**: `pwsh checks/verify_repo.ps1 Fast`
  - 必須: 全項目 PASS
- [ ] **Evidence保存**: `evidence/verify_reports/` にレポート保存
- [ ] **Commit**: `git commit -m "feat: <description>"`

### Step 5: 承認・マージ (Review/Merge)
- [ ] **PR作成**: Mainブランチへ Pull Request
- [ ] **CI実行**: `verify-gate-windows` (必須) が PASS
- [ ] **承認**: Owner/Role の Review (LGTM)
- [ ] **Merge**: Main に統合

---

## 2. 例外フロー（Break-glass）

**条件**: サイトダウン、セキュリティインシデント、デッドロック発生時。

### 手順
1. **承認**: 緊急承認者（Emergency Role）の承認を得る (Chat/Oral OK)
2. **実行**: 運用の強制力を解除して実行（システム的なバイパス手段がない場合は手動対応）
3. **事後対応** (24時間以内):
   - ADRを作成（事後承認）
   - Full Verify を実行
   - `evidence/incidents/` にレポート保存

---

## 3. チェックリスト

### PR作成前（Self Check）
- [ ] `pwsh checks/verify_repo.ps1 Fast` が PASS している
- [ ] `docs/` の変更が TICKET の範囲内である
- [ ] `out/` ディレクトリ（統合テキスト等）はコミット対象外である
- [ ] 未決事項（U-XXXX）を増やしていない（増やした場合はIssue化）

### マージ前（Reviewer Check）
- [ ] CI が All Green である
- [ ] Evidence が `evidence/` に含まれている
- [ ] 破壊的変更（削除等）が含まれていない（またはHumanGate承認済み）

### リリース前（Release Gate）
- [ ] Full Verify が PASS している
- [ ] `RELEASE/` フォルダが作成され、sha256/SBOM がある
- [ ] `STATUS.md` が `APPROVED` になっている

---

## 4. 参照リンク
- [SSOT憲法](../../docs/Part00.md)
- [Verify Gate](../../docs/Part10.md)
- [変更管理](../../docs/Part14.md)
