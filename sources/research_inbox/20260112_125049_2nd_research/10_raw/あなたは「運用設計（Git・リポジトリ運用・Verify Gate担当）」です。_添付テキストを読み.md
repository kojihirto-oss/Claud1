<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# あなたは「運用設計（Git・リポジトリ運用・Verify Gate担当）」です。

添付テキストを読み、ローカル作業とGitHub運用の“混乱ポイント”を中心に、
再現性・事故防止・初心者耐性が最大になるようにルールを最適化してください。

# 目的

- 「ローカル」と「GitHub」の使い分けを明文化し、迷いゼロ手順にする
- ブランチ戦略（main / integrate / feat）、PR作成、マージ、リリース、証跡維持（recent-3）を
1本道のチェックリストに落とす
- Verify Gate の設計が実運用で破綻しないか（例：証跡の拡張子、削除ポリシー、誤検知）を監査


# 重要条件

- 公式ソース（git-scm / GitHub Docs / 公式リリースノート）を優先し、URLで根拠を提示する
- マージ競合・conflict marker（<<<<<<< 等）の事故を避ける具体策を入れる
（conflictの一般仕様は git-merge ドキュメントを根拠にしてよい）
- 出力は「設計書へ追記できる文章」と「運用のコマンド手順（例）」を分けて書く


# 出力フォーマット（厳守）

1) 混乱ポイント一覧（P0/P1/P2）: 例と原因
2) 改善後の “迷いゼロ” 運用フロー（チェックリスト形式）
3) 設計書へ追記する文章案（そのまま貼れる）
4) Verify Gate 改善案（誤検知/漏れ/証跡運用/命名/保持ポリシー）
5) 最低限のトラブルシュート（症状→原因→手順）

それでは、最終的な設計書を作成します。

# 【Git・リポジトリ運用設計書】ローカル↔GitHub混乱ポイント最適化

## 1. 混乱ポイント一覧（P0/P1/P2優先度付き）

### **P0（重大：運用破綻リスク）**

| ID | 混乱ポイント | 具体例 | 原因 | 初心者への影響 |
| :-- | :-- | :-- | :-- | :-- |
| **P0-1** | ブランチ名義が不明確 | `feat/123` と `feature/fix-bug` が混在 | 命名規則の明記なし | PR レビューで差し戻し/競合頻発 |
| **P0-2** | main / integrate / feat の役割不明 | feat ブランチを main に直接 push | 階層関係・マージ順序が図示されていない | 検証抜きのリリース/事故 |
| **P0-3** | マージ競合の事故防止策がない | conflict marker （`<<<<<<<`） が見落とされマージ実行 | 競合検出ツール未実装 | マージ失敗/コード混在 |
| **P0-4** | ロールバック手順が不明確 | 誤マージ後に git reset vs revert で迷う | 破壊的変更対応が Part09 に分散 | 回復遅延/本流汚染 |
| **P0-5** | Verify Gate と Git 操作の連携欠落 | Fast Verify と PR マージが独立実行 | タイミング指定がない | 検証未了でリリース |

### **P1（高：初心者が迷う）**

| ID | 混乱ポイント | 具体例 | 原因 |
| :-- | :-- | :-- | :-- |
| **P1-1** | ローカル rebase vs merge の使い分け | `git rebase origin/main` と `git merge origin/main` どちらを使うか | Git philosophy（linear history vs. merge graph）が明記されていない |
| **P1-2** | origin 同期のタイミング | PR マージ前に `git pull` すべきか | 手順の単線化がない |
| **P1-3** | recent-3 ポリシー未実装 | evidence/ に古いファイルが溜まる/削除判断がない | 保持期限・削除ルール未定義 |
| **P1-4** | AI Permission Tier と Git 操作の対応欠落 | PatchOnly AI が git merge を実行できるか不明 | Permission と操作の対応表がない |
| **P1-5** | PR テンプレート未整備 | 何を書くべきか不明/Verify 証跡が付かない | チェックリスト形式の明記なし |

### **P2（中：効率化の余地）**

| ID | 混乱ポイント | 具体例 |
| :-- | :-- | :-- |
| **P2-1** | init → main merge の "1本道" がない | 各自が独自の手順で実行 |
| **P2-2** | コマンド例が不足 | 誰が何を実行するかが明記されていない |
| **P2-3** | branch protection rules（GH設定）が明記されていない | main への直接 push が防止されているか不明 |


***

## 2. 改善後の「迷いゼロ」運用フロー

### **2.1 ローカル作業フロー（図式版）**

```
┌─ START: ticket-123 を READY から DOING へ
│
├─ 1. ローカルでブランチ作成
│   ```bash
│   git fetch origin main
│   git checkout -b feat/123-user-auth origin/main
│   ```
│   ✅ RULE: 常に origin/main から新規分岐（古い main と同期ズレを防止）
│
├─ 2. ローカルで実装・テスト
│   ```bash
│   # 実装する
│   git add . && git commit -m "feat(123): Add user auth endpoint"
│   # ローカル Fast Verify
│   bash checks/verify_repo.sh
│   ```
│   ✅ RULE: 実装後は必ずローカル Verify（Part10参照）
│
├─ 3. リモート同期前に競合確認
│   ```bash
│   git fetch origin main
│   # Rebase で線形 history を保ち、競合を本流の最新に当てる
│   git rebase -i origin/main
│   # 競合があれば:
│   #   - エディタで conflict marker を確認
│   #   - 手動解決（<<<<<<<, =======, >>>>>>> を削除）
│   #   - git add . && git rebase --continue
│   ```
│   ✅ RULE: ローカルで競合解決（リモート側に競合を持ち込まない）
│   📄 根拠: git-scm conflict resolution section
│
├─ 4. リモート push
│   ```bash
│   git push -u origin feat/123-user-auth
│   ```
│
├─ 5. PR 作成（GitHub）
│   - Base: `integrate` (※main ではない！)
│   - Template を使う（.github/pull_request_template.md）
│   - ✅ Checklist:
│     □ Fast Verify: PASS (スクショ貼付)
│     □ Evidence Pack: evidence/YYYYMMDD_* に保存済み
│     □ リンク切れなし（Fast Verify で確認）
│     □ 用語揺れなし（Part02 で確認）
│
├─ 6. PR レビュー & リクエスト修正
│   ```bash
│   # レビューコメント対応して commit
│   git add . && git commit -m "fix: review comment"
│   git push origin feat/123-user-auth
│   # PR 自動更新（GitHub が検出）
│   ```
│
└─ 7. integrate へマージ（CI/CD + HumanGate 承認後）
    git merge --no-ff feat/123-user-auth
    # GitHub "Squash and merge" or "Rebase and merge" を選択
    ✅ RULE: GitHub マージ機能を使う（ローカル merge を push しない）
```


### **2.2 GitHub 上のマージフロー（3層ブランチ戦略）**

```
┌─────────────────────────────────────────────────────────────┐
│  feat/*** ブランチ（複数並列）                               │
│  - 権限: Developer (PatchOnly)                              │
│  - 保護: 有（direct push 禁止）                              │
│  - マージ先: integrate（PR → マージ）                        │
└──────────────────────┬──────────────────────────────────────┘
                       │ (Squash or Rebase and merge)
                       │ Verify Gate: 必須 (Fast+Full)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  integrate ブランチ（統合・検証用）                           │
│  - 権限: CI/CD (ExecLimited) + HumanGate 承認               │
│  - 保護: 有（PR + CI/CD 通過必須）                           │
│  - マージ先: main（自動マージ or 手動）                      │
│  - TTL: 7日（古い integrate は削除）                         │
└──────────────────────┬──────────────────────────────────────┘
                       │ (Create merge commit --no-ff)
                       │ Verify Gate: Full (全項目検証)
                       │ Approval: HumanGate 必須
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  main ブランチ（本流・リリース用）                            │
│  - 権限: Release管理者 (HumanGate のみ)                     │
│  - 保護: 有（PR + 全 CI/CD + 署名必須）                      │
│  - マージ: integrate からのみ（fast-forward 許容）           │
│  - Release Tag: v*.*.* で固定                              │
│  - Rollback: git revert で履歴を残す                        │
└─────────────────────────────────────────────────────────────┘
```


### **2.3 リリース・証跡フロー**

```
┌─ main ブランチの commit に Release Tag を付ける
│  git tag -a v1.2.3 -m "Release v1.2.3"
│  git push origin v1.2.3
│
├─ Release Package を生成（Part13参照）
│  RELEASE/RELEASE_20260111_000000/
│  ├── manifest.csv      # ファイル一覧
│  ├── sha256.csv        # 整合性チェック（削除/改ざん検出用）
│  ├── sbom.json         # 依存関係（CycloneDX形式）
│  ├── security_scan.md  # セキュリティスキャン結果
│  └── STATUS.md         # DoD チェックリスト
│
├─ Release フォルダを READ-ONLY に変更
│  chmod -R a-w RELEASE/RELEASE_20260111_000000/
│
└─ recent-3 ポリシー: 最新3世代の Release を保持
   - RELEASE_20260111 (latest)
   - RELEASE_20260110
   - RELEASE_20260109
   - RELEASE_20260108 以降 → evidence/archive/ へ移動
```


***

## 3. 設計書へ追記する文章案

### **【新規セクション】Part04 追記: 1本道のブランチ戦略**

```markdown
## 4.5 ブランチ戦略（3層構造・競合防止・初心者向け）

### 4.5.1 ブランチの3層構造

本プロジェクトは以下の3層ブランチ戦略を採用する：

**Layer 1: Feature Branch（feat/***）**
- **目的**: 個別タスクの作業ブランチ
- **命名規則**: `feat/<TICKET-ID>-<description>` 例: `feat/123-add-user-auth`
- **生成元**: `origin/main` の最新から毎回新規作成
- **保護設定**: 直接 push 禁止、PR + Fast Verify PASS で merge
- **有効期限**: 14日（未マージの古いブランチは削除）
- **特別な型**:
  - `bugfix/ID-description`: バグ修正（同じ命名規則）
  - `hotfix/ID-description`: 緊急修正（HumanGate 承認必須、main へも merge）
  - `spike/ID-description`: 調査・PoC（成果は別途 Spec へ移す）

**Layer 2: Integrate Branch（integrate）**
- **目的**: Feature ブランチから上がった変更を統合・検証
- **生成元**: 初期は `origin/main` から作成、以降は git worktree で管理
- **マージ受け入れ**: PR ベース（Squash or Rebase and merge）
- **保護設定**: PR + Full Verify（CI/CD 含む）+ HumanGate 承認必須
- **検証項目**: リンク切れ、用語揺れ、Part間整合、未決事項、セキュリティスキャン
- **有効期限**: 7日（テスト完了後は main へマージ）
- **特殊ルール**: integrate へのマージ順序は FIFO（先着順、競合回避）

**Layer 3: Main Branch（main）**
- **目的**: 本流・リリース対象
- **マージ元**: integrate のみ
- **マージ方法**: Create merge commit（--no-ff）で merge 履歴を残す
- **保護設定**: PR + 全 CI/CD 通過 + GPG 署名必須
- **ロールバック**: `git revert` で履歴を保存（git reset 使用禁止）
- **リリース**: main 上でタグを付け、Release Package を生成

### 4.5.2 ローカル作業での競合回避ルール【重要】

**RULE-A: ローカルで rebase、リモート側で merge する（一方通行）**
```bash
# ローカル: rebase で線形 history を保つ
git fetch origin main
git rebase -i origin/main  # 競合あれば手動解決
git push -u origin feat/123-...

# リモート（GitHub）: "Squash and merge" or "Rebase and merge"
# → GitHub UI で実行、merge commit 履歴を自動生成
```

**理由**:

- ローカル rebase → conflict を早期発見・解決
- リモート merge → merge commit で feature 単位を可視化
- 結果: 本流が常に clean で、rollback が容易

**根拠**: git-scm merge strategies (ort algorithm) [git-scm.com/docs/git-merge]

### 4.5.3 Conflict Marker 検出と解決【必須手順】

Conflict marker（`<<<<<<<`, `=======`, `>>>>>>>`）は以下の手順で対応：

**発生時**:

```bash
git merge origin/main  # 競合が発生
# or
git rebase origin/main
```

**marker の場所を確認**:

```bash
git diff --name-only --diff-filter=U  # 競合ファイル一覧
grep -r "<<<<<<<\|=======" --include="*.md" --include="*.py"  # marker 検出
```

**手動解決**（エディタで):

```
<<<<<<< HEAD (当分支の内容)
実装内容 A
=======
実装内容 B (マージ元の内容)
>>>>>>>  origin/main
```

→ どちらか一方を残すか、両方を統合するか判断し marker を削除

**解決後**:

```bash
git add <resolved-file>
git rebase --continue  # or git merge --continue
```

**Fast Verify に追加**:

- V-0504: Conflict marker の残存チェック（FAIL: 1個以上の marker が存在）
- 手順: `grep -r "<<<<<<\|=======" docs/ checks/ evidence/`

**根拠**: git-scm "HOW CONFLICTS ARE PRESENTED" section [git-scm.com/docs/git-merge]

### 4.5.4 誤マージのロールバック

**パターン1: マージ直後（未 push）**

```bash
git merge --abort  # マージ前の状態に戻す
```

**パターン2: マージ済み（リモートに push 済み）**

```bash
# ❌ git reset --hard HEAD~1  は使用禁止（履歴が消える）
# ✅ git revert を使う（履歴が残る）
git revert -m 1 <merge-commit-hash>
git push origin main
# → 「このマージを取り消した」という新しい commit が記録される
# → 後から原因調査が可能
```

**ロールバック後の対応**:

1. evidence/ に「revert 理由」を記録
2. ADR を追加（再発防止策を明記）
3. PR を新規作成（修正版を上げる）

**根拠**: Part00 R-0006（禁止事項）, Part01 例外処理

```

### 【新規セクション】Part04 追記: recent-3 ポリシー運用

```markdown
## 4.6 証跡保持ポリシー（Recent-3）

### 4.6.1 保持対象ファイル

以下の情報は削除禁止（Append-only）：
- **sources/**: 原文・根拠（改変禁止）
- **evidence/verify_reports/**: Verify 実行ログ（削除禁止）
- **evidence/incidents/**: 事故記録（削除禁止）
- **evidence/vr_loops/**: VRループログ（削除禁止）
- **RELEASE/**: リリース成果物（削除禁止）
- **decisions/**: ADR（削除禁止）

### 4.6.2 Recent-3 ポリシー（ディスク容量対策）

**Release Package の保持**:
```

RELEASE/
├── RELEASE_20260111_000000  ← latest (1世代目)
├── RELEASE_20260110_180000  ← 2世代目
├── RELEASE_20260109_120000  ← 3世代目
└── archive/
├── RELEASE_20260108_000000  ← アーカイブ（圧縮・クラウド保管可）
└── RELEASE_20260107_...

```

**アーカイブルール**:
- **タイミング**: 4世代目がリリースされた時点で、3世代目を archive/ へ移動
- **アーカイブ形式**: `tar.gz` で圧縮、checksum（sha256）を保存
- **保管場所**: Google Cloud Storage 等、低頻度アクセス ストレージ
- **復元手順**: `tar -xzf RELEASE_20260108.tar.gz` で復旧可能

**evidence/ ファイルの整理**:
```

evidence/verify_reports/
├── recent_3_YYYYMMDD_*.md   ← 最新3ファイル（常時アクセス可能）
└── archive/
└── old_YYYYMMDD_*.md    ← 4世代目以降

```

**自動化スクリプト**（checks/cleanup_recent3.sh）:
```bash
#!/bin/bash
# 毎月1日 00:00 実行（cron）

# RELEASE アーカイブ
ls -t RELEASE/RELEASE_* | tail -n +4 | xargs -I {} sh -c '
  mkdir -p RELEASE/archive
  tar -czf RELEASE/archive/{}_$(date +%Y%m%d).tar.gz {}
  rm -rf {}
  sha256sum RELEASE/archive/{}_*.tar.gz > RELEASE/archive/{}.sha256
'

# evidence/verify_reports 整理
ls -t evidence/verify_reports/ | tail -n +10 | xargs -I {} sh -c '
  mkdir -p evidence/archive
  mv evidence/verify_reports/{} evidence/archive/
'
```

**根拠**: Part00 R-0005（evidence/ 保存義務）、Part01 メトリクス計測

```

### 【新規セクション】Part04 追記: PR テンプレート（GitHub標準機能）

```markdown
## 4.7 Pull Request テンプレート & チェックリスト

### 4.7.1 ファイル配置

`.github/pull_request_template.md` をリポジトリに追加：

```markdown
## 📝 Description
<!-- 何をしたか、なぜしたか -->

## 🎯 Closes
<!-- Part04 R-0401: TICKET形式で記載 -->
Closes #123 (TICKET-123: User authentication endpoint)

## ✅ Checklist

### Spec 確認
- [ ] Part00-01 を読み、前提を理解した
- [ ] FACTS_LEDGER で未決事項を確認した
- [ ] 用語揺れなし（glossary/GLOSSARY.md と一致）

### Local 作業
- [ ] Fast Verify PASS（4点）
  - [ ] リンク切れ: 0件
  - [ ] 用語揺れ: 0件
  - [ ] Part間整合: 矛盾 0件
  - [ ] 未決事項: 警告表示確認
- [ ] ローカルで `git rebase -i origin/main` 実行済み
- [ ] Conflict marker (<<<<<, =====, >>>>>) がない

### Evidence Pack
- [ ] `evidence/verify_reports/YYYYMMDD_HHMMSS_*.md` に Verify 結果保存
- [ ] `evidence/YYYYMMDD_HHMM_<task-id>_diff.txt` に変更差分を保存

### Git リモート操作
```

- [ ] Branch: `feat/<ID>-<description>` 命名規則に従っている

```
- [ ] Base Branch: `integrate` を選択している（main ではない）
- [ ] Commit message: conventional commits 形式 (feat:, fix:, docs: 等)

### ブランチ保護ルール
- [ ] この PR は自動 CI/CD を実行済み
- [ ] このブランチは 14日以内に作成

### 追加コメント
<!-- 重要な情報、設計判断の根拠、既知の制限事項等 -->

***
**Evidence Pack**: [verify_reports/](../evidence/verify_reports/)
**Relevant ADR**: [decisions/](../decisions/)
```


### 4.7.2 PR マージの実行手順（GitHub UI）

**手順1: PR レビュー完了を待つ**

- Reviewer 2名以上が Approve
- CI/CD パイプラインが全て Green
- Fast Verify + Full Verify が PASS

**手順2: マージ方法の選択**
GitHub の "Merge" ボタンから以下を選択：

- **通常推奨**: 「Squash and merge」
    - 複数の作業 commit を1つにまとめる
    - commit message を自動生成（conventional commits で補正）
- **複雑な変更の場合**: 「Rebase and merge」
    - feature の commit 履歴を保存（commit 単位での review が必要な場合）
- **❌ 使用禁止**: 「Create a merge commit」← ローカルで commit 履歴を整理してから merge すること

**手順3: ブランチ削除**

- マージ完了後、feature branch を削除
- GitHub 自動削除オプション: 有効化推奨

**根拠**: GitHub Docs "About pull request merges" [docs.github.com/.../merging-a-pull-request]

```

***

## 4. Verify Gate 改善案

### **4.1 Fast Verify に「Conflict Marker 検出」を追加**

| 項目 | V-0505 |
|------|--------|
| **検査内容** | docs/, checks/, evidence/ に conflict marker がないか |
| **実行方法** | `grep -r "<<<<<<\|=======" --include="*.md" --include="*.py" --include="*.sh"` |
| **合否判定** | **PASS**: 0件 / **FAIL**: 1個以上検出 |
| **FAIL時の対応** | PR マージを自動ブロック（GitHub branch protection） |
| **ログ保存** | `evidence/verify_reports/YYYYMMDD_HHMMSS_conflict_check.md` |

**実装（checks/verify_conflict.ps1 例）**:
```powershell
function Test-ConflictMarkers {
    param([string]$RepoPath = ".")
    
    $markers = @("<<<<<<<<", "========", ">>>>>>>>")
    $conflicts = @()
    
    foreach ($marker in $markers) {
        $found = Get-ChildItem -Path $RepoPath -Recurse -Include "*.md", "*.py", "*.sh" | 
                 Select-String -Pattern $marker
        if ($found) {
            $conflicts += $found
        }
    }
    
    if ($conflicts.Count -gt 0) {
        Write-Output "❌ FAIL: Conflict markers detected ($($conflicts.Count))"
        $conflicts | ForEach-Object { Write-Output "  - $($_.Path):$($_.LineNumber)" }
        return $false
    } else {
        Write-Output "✅ PASS: No conflict markers"
        return $true
    }
}
```


### **4.2 誤検知・漏れ対策**

| 対策 | 説明 | 実装 |
| :-- | :-- | :-- |
| **誤検知対策** | コード内の文字列 `"<<<<"` を誤検知しない | grep を `^<<<<<<< ` に限定（行頭） |
| **誤検知回避** | markdown コード ブロック内の marker を許容 | ```\n$marker\n``` パターンは除外 |
| **漏れ対策** | 非テキストファイル（バイナリ）はスキップ | file コマンドで テキスト判定 |
| **定期スキャン** | commit-msg hook で自動チェック | `.git/hooks/pre-commit` に組み込み |

### **4.3 証跡命名規則の統一**

**現在の問題**:

```
evidence/YYYYMMDD_HHMMSS_<check_name>.md  ← Part14
evidence/YYYYMMDD_HHMM_<task-id>_diff.txt ← Part04
evidence/verify_reports/YYYYMMDD_HHMMSS_*.md ← Part01
```

→ 命名がバラバラで、古いファイル判定が難しい

**改善案（統一フォーマット）**:

```
evidence/<LAYER>/<YYYYMMDD_HHMMSS>_<TYPE>_<ID>.md

レイヤー定義:
- verify_reports/   : Fast/Full Verify 実行ログ
- diffs/            : 変更差分（git diff 出力）
- incidents/        : 事故記録（ロールバック含む）
- vr_loops/         : VRループログ
- approval/         : HumanGate 承認記録
- metrics/          : メトリクス計測結果

例:
evidence/verify_reports/20260111_143500_fast_verify_feat-123.md
evidence/diffs/20260111_140000_feat-123_vs_origin-main.txt
evidence/approval/20260111_120000_humangate_hotfix-456.md
```

**メリット**:

- `ls -t evidence/*/*` で world-gen ソート可能
- タイプ別集計が容易（`find evidence/verify_reports -name "*.md" -mtime +30`）
- Recent-3 自動化が単純化


### **4.4 削除ポリシーの明確化**

**削除禁止（永続保持）**:

- sources/
- decisions/ 内の ADR
- RELEASE/ リリースパッケージ
- evidence/approval/ 承認記録

**アーカイブ対象**（Recent-3 後の移動）:

- evidence/verify_reports/ （保持: 3ヶ月）
- evidence/diffs/ （保持: 3ヶ月）
- evidence/vr_loops/ （保持: 1ヶ月）
- evidence/metrics/ （保持: 1年）

**削除スクリプト（自動化）**:

```bash
#!/bin/bash
# /usr/local/bin/archive-old-evidence.sh (cron: 毎月1日 00:00)

ARCHIVE_DIR="evidence/archive"
CUTOFF_DATE=$(date -d "30 days ago" +%s)

for file in evidence/*/*.md; do
    FILE_DATE=$(stat -c %Y "$file")
    if [[ $FILE_DATE -lt $CUTOFF_DATE ]]; then
        tar -czf "$ARCHIVE_DIR/$(basename $file .md)_$(date +%Y%m%d).tar.gz" "$file"
        rm "$file"
        echo "Archived: $file"
    fi
done

# Checksum 生成
sha256sum "$ARCHIVE_DIR"/* > "$ARCHIVE_DIR/manifest.sha256"
```


***

## 5. 最低限のトラブルシュート

### **【症状】Conflict が発生して、どう対応すればいいか分からない**

| 症状 | 原因 | 手順 |
| :-- | :-- | :-- |
| `git merge origin/main` 実行後、「CONFLICT (content)」と表示 | ローカルと origin/main で同じ行を変更 | 1. `git status` でファイル一覧を確認<br>2. エディタで `<<<<<<<` `=======` `>>>>>>>` を見つける<br>3. 保持すべき部分を選択（両方 keep することも可）<br>4. marker を削除<br>5. `git add .` \& `git merge --continue` |
| rebase 中に「CONFLICT」 | rebase 対象の commit が競合 | 1. 同上（エディタで編集）<br>2. `git rebase --continue`（merge ではなく rebase） |
| conflict marker が分からない | HTML/JSON など複雑な形式 | 1. IDE (VS Code) の "Merge Editor" を使用<br>2. `git mergetool` で GUI マージツール起動（kdiff3 等） |
| マージを中止したい | 変更を保留・再検討 | `git merge --abort`（or `git rebase --abort`） |

### **【症状】誤って main に push してしまった**

| 状況 | 対応 | 注意 |
| :-- | :-- | :-- |
| ローカル commit（未 push） | `git reset --hard HEAD~1`<br>→ 1つ前の commit に戻す | ✅ ローカルのみ安全 |
| リモート push 済み | `git revert -m 1 <commit-hash>`<br>→ リバート commit を記録<br>`git push origin main` | ✅ 履歴を残す（推奨）<br>❌ git reset は禁止 |
| main branch を整理する | 1. ADR で「revert 理由」を記録<br>2. evidence/ に「復旧記録」を保存<br>3. 再発防止策を明記 | branch protection rules で再発防止（HumanGate 必須化） |

### **【症状】 recent-3 ポリシーで古い evidence が削除されている**

| 状況 | 確認方法 | 復旧 |
| :-- | :-- | :-- |
| 4ヶ月前の Release パッケージが必要 | `ls -la evidence/archive/*.tar.gz` | `tar -xzf evidence/archive/RELEASE_20220911.tar.gz` |
| Verify レポートが見つからない | `find evidence -name "*.md" -mtime +30` | Google Cloud Storage などの long-term backup から復元 |
| Recent-3 で上書きされた | Git のリファレンス（tag）で世代追跡 | Release Tag：`git show v1.2.3` で世代確認 |

### **【症状】 「Verify FAIL: 用語揺れ 3件」と言われたが、修正方法が分からない**

| エラー | 原因 | 修正方法 |
| :-- | :-- | :-- |
| 「SSOTダッシュボード」と「SSOT Dashboard」が混在 | glossary/GLOSSARY.md と Part の表記不一致 | 1. glossary/GLOSSARY.md で正しい表記を確認<br>2. 全 docs/ を grep で統一<br>3. Fast Verify 再実行 |
| 「Permission Tier」と「PermissionTier」 | スペース忘れ | Part02 GLOSSARY.md に従い「Permission Tier」に統一 |
| 「DoD」と「DOD」 | 大文字小文字混在 | 同上（多くは大文字） |
| 削除機能と修正が困難 | 手作業は対応時間が長い | 自動化スクリプト検討（checks/unify_glossary.sh）← 実装予定 |


***

## 6. 運用のコマンド手順（テンプレート）

### **【例1】Feature 作成→ Integrate マージまで（完全なワンシーン）**

```bash
# ===== STEP 1: 準備 =====
# Jira/GitHub Issue で TICKET-123 を確認（description, AC を読む）
# VIBEKANBAN で READY → DOING に移動

# ===== STEP 2: ローカル feature branch 作成 =====
$ git fetch origin main
$ git checkout -b feat/123-add-user-auth origin/main
# → 新しいブランチ上で作業開始

# ===== STEP 3: 実装＆テスト =====
$ # エディタで docs/Part*.md 編集
$ git add .
$ git commit -m "feat(123): Add user authentication endpoint"
$ # 複数 commit ある場合は rebase で整理予定

# ===== STEP 4: ローカル Fast Verify =====
$ bash checks/verify_repo.sh
# 出力例:
#   ✅ PASS: リンク切れ 0件
#   ✅ PASS: 用語揺れ 0件
#   ✅ PASS: Part間整合 矛盾 0件
#   ⚠️  WARN: 未決事項 U-0102（既知、Part13で解決予定）

# ===== STEP 5: リモート同期前に競合確認 =====
$ git fetch origin main
$ git rebase -i origin/main
# (競合があれば手動解決 → git add . && git rebase --continue)

# ===== STEP 6: リモート push =====
$ git push -u origin feat/123-add-user-auth

# ===== STEP 7: PR 作成（GitHub）=====
# → PR_TEMPLATE.md に従い記入
#    - Base: integrate （main ではない！）
#    - Title: "feat(123): Add user authentication"
#    - Checklist を全チェック

# ===== STEP 8: CI/CD & レビュー =====
# → GitHub Actions が自動実行（Full Verify）
# → 2名以上の Reviewer が Approve

# ===== STEP 9: マージ実行（GitHub）=====
# → "Squash and merge" を選択
# → Commit message を確認（自動生成されている）
# → "Confirm merge" クリック
# → ブランチ削除（自動）

# ===== STEP 10: 証跡確認（ローカル） =====
$ git fetch origin integrate
$ git log --oneline -5 origin/integrate
# → feat/123 の commit が integrate に入ったことを確認

# ===== STEP 11: VIBEKANBAN 更新 =====
# DOING → VERIFYING（integrate での検証中）
# → VERIFYING → DONE（main へマージされたら終了）

# ===== Evidence 確認 =====
$ ls -la evidence/verify_reports/
# → YYYYMMDD_HHMMSS_fast_verify_feat-123.md
# → YYYYMMDD_HHMMSS_full_verify_feat-123.md
```


### **【例2】誤マージをロールバック**

```bash
# ===== 検出： integrate に誤ったコミットが入った =====
$ git fetch origin integrate
$ git log --oneline -3 origin/integrate

# ===== ロールバック実行 =====
# (例) 誤マージ commit のハッシュが "abc1234" の場合
$ git checkout integrate
$ git revert -m 1 abc1234  # merge commit の親(1)を保持
$ git push origin integrate

# ===== Evidence 記録 =====
# evidence/approval/YYYYMMDD_HHMMSS_revert_abc1234.md を作成
cat > evidence/approval/20260111_150000_revert_abc1234.md << 'EOF'
# Revert Record: abc1234

## 誤マージ内容
- Commit: abc1234
- PR: #456 (feat/789-wrong-feature)
- Reason: Spec not frozen, conflicts with ongoing work on feat/123

## Revert 実行
```bash
git revert -m 1 abc1234
git push origin integrate
```


## 確認

- integrate ブランチが正常状態に復旧
- feat/789 を修正して再度 PR を作成予定
- ADR 追加: 「Spec 凍結前のマージ禁止」を enforce 化


## 承認

- HumanGate: Approved at 2026-01-11 15:00
EOF


# ===== ADR 追加：再発防止 =====

cat > decisions/0999-prevent-spec-unfrozen-merge.md << 'EOF'

# ADR-0999: Spec 凍結前のマージを自動ブロック

## 背景

abc1234 で Spec 凍結前のコミットが integrate にマージされ、ロールバックが必要に。

## 決定

integrate へのマージ PR に「Spec Frozen: Yes/No」チェックボックスを必須化。

- Unchecked の場合は GitHub が自動 block


## 実装

- PR Template に checkbox 追加
- Branch Protection Rule に custom check を追加
EOF


# ===== 確認 =====

\$ git log --oneline -3 origin/integrate

# → "Revert "feat/789-..."" というコミットが最新に

```

***

本設計書は **git-scm 公式仕様** と **GitHub 公式ドキュメント** に準拠し、初心者でも「次に何をすべきか」が迷わない運用を実現します。[^1_1][^1_2]

***

## 【参考資料】

| 出典 | URL | 内容 |
|------|-----|------|
| [^1_1] git-scm.com | https://git-scm.com/docs/git-merge | Merge 仕様・Conflict Marker・3-way merge |
| [^1_2] GitHub Docs | https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request | PR マージ方法（Squash/Rebase/Create merge commit） |
| [^1_3] git-scm.com | https://git-scm.com/book/en/v2/Git-Branching-Branch-Management | ブランチ管理・命名規則・削除安全性確認 |
<span style="display:none">[^1_10][^1_11][^1_12][^1_13][^1_14][^1_15][^1_16][^1_4][^1_5][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: DESIGN_MASTER_20260111_230526.txt
[^1_2]: https://www.reddit.com/r/git/comments/n8yx5h/correct_workflow_to_resolve_conflict_and_merge/
[^1_3]: https://www.youtube.com/watch?v=bAn7gcZ9WRA
[^1_4]: https://git-scm.com/docs/git-rebase
[^1_5]: https://izymes.com/2023/09/14/advanced-git-merge-conflict-resolution-techniques/
[^1_6]: https://www.chucksacademy.com/en/topic/git-branching/best-practices-branching-merging
[^1_7]: https://about.gitlab.com/ja-jp/blog/git-merge-command-overview/
[^1_8]: https://docs.gitlab.com/topics/git/git_rebase/
[^1_9]: https://thoughtbot.com/blog/github-pull-request-merge-strategies
[^1_10]: https://stackoverflow.com/questions/76236777/where-is-the-official-documentation-on-the-set-of-pipes-parent-of-in-git-mer
[^1_11]: https://stackoverflow.com/questions/60154023/git-possible-conflict-resolution-workflow
[^1_12]: https://www.reddit.com/r/git/comments/1arnu5l/best_practice_when_main_branch_is_a_few_commits/
[^1_13]: https://git-scm.com/docs/git-merge
[^1_14]: https://learn.microsoft.com/en-us/azure/devops/repos/git/merging?view=azure-devops
[^1_15]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request
[^1_16]: https://zenn.dev/suwash/articles/git_20250824```

