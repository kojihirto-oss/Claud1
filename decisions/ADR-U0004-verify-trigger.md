# ADR-U0004: Verify実行トリガの定義（Verify Trigger Definition）

## 1. Context（背景）

Verify（検証）をいつ、どこで、どの強度で実行すべきか不明確であり（U-0004）、以下の問題があった：
- ローカルでVerify忘れ → CIで落ちる（手戻り）
- 軽微な修正にFull Verifyを実行 → 時間の無駄
- CIでの強制力が弱く、壊れたままマージされるリスク

## 2. Decision（決定事項）

Verifyを「CI必須」「ローカル推奨」とし、変更内容に応じて「Fast/Full」を使い分ける。

### 2.1 トリガマトリクス（Trigger Matrix）

| 環境 | タイミング | 対象スコープ | Verify Mode | 強制力 |
|------|-----------|-------------|-------------|--------|
| **Local** | ファイル保存時 | 編集ファイル周辺 | **Fast** | 推奨 (Watcher) |
| **Local** | Commit前 | 変更セット (Staged) | **Fast** (推奨) / Full (任意) | 推奨 (Hooks) |
| **Local** | Push前 | Branch全体 | **Full** (推奨) | 推奨 |
| **CI** | PR作成/更新 | PR差分 + 影響範囲 | **Fast** | **必須 (Block)** |
| **CI** | Merge前 | Main統合後 | **Full** | **必須 (Block)** |
| **CI** | Schedule | 全体 | **Full** (Daily) | 通知のみ |

### 2.2 モード定義

- **Fast Verify**:
  - 目的: 開発リズムを止めない（< 30秒）
  - 内容: Link check, Lint, Format, Static Analysis (Light), Part structure check
  - 対象: docs/, scripts/ (syntax only)

- **Full Verify**:
  - 目的: 品質の完全保証（< 10分）
  - 内容: Fast + Unit Tests, Integration Tests, Security Scan, SBOM generation, Build check
  - 対象: 全リポジトリ

### 2.3 CI Required Checks

GitHub Actions 等で以下のジョブ成功をマージ条件とする：
1. `verify-fast`: PR作成・更新時に実行
2. `verify-full`: マージキュー、または重要なPR（`decisions/`, `scripts/` 変更時）で実行

### 2.4 自動選択ロジック（Local/CI共通）

```powershell
if (変更ファイルに decisions/*, scripts/*, ops/* が含まれる) {
    Execute-Verify -Mode Full
} elseif (変更ファイルが docs/ のみ) {
    Execute-Verify -Mode Fast
} else {
    Execute-Verify -Mode Fast (Default)
}
```

## 3. Evidence（証跡要件）

Verify結果は `evidence/verify_reports/YYYYMMDD_HHMMSS_<Mode>_<Result>.md` に保存する。

**CIの場合**:
- CIログへのリンクとSummaryをEvidenceとして残す（Artifact保存）。

## 4. Consequences（影響）

- **Positive**:
  - 「いつ検証すればいいか」の迷いがなくなる
  - CIでのブロックにより、Mainブランチの健全性が保たれる
  - ローカルFast Verifyにより、手戻りが減る
- **Negative**:
  - CI待ち時間が発生する（Fast化で軽減）
  - ローカル環境構築（PowerShell 7+）が必須になる

## 5. Verification（検証）

- **V-U0004**: `pwsh checks/verify_repo.ps1 Fast` がローカルでPASSすること
- **Manual**: CI上で `verify-fast` が実行され、失敗時にマージブロックされること
