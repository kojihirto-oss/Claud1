# ADR-0006: Antigravity Safety Rails（IDE司令塔の安全柵と権限境界）

- 日付: 2026-01-13
- 状態: 承認
- 影響Part: Part06, Part09, Part18
- 参照: docs/Part06.md（IDE/司令塔運用）, docs/Part09.md（Permission Tier）

## 背景

Antigravity（IDE/司令塔UI）は作業の指示と確認の場として機能するが、
操作範囲が広すぎると誤削除・権限越境・作業ディレクトリ破壊のリスクが高い。

特に以下のリスクが顕在化している：
- 削除系操作（rm -rf, git clean -fdx等）の誤実行
- worktree外への意図しないファイル操作
- Permission Tier超過の実行（HumanGate不要な操作の自動承認）
- sources/ への改変（Part00 R-0003違反）

司令塔UIを「司令塔/レビュー/確認」に限定し、
破壊的操作はHumanGate必須とする安全柵を明文化する必要がある。

## 決定

### D-0006-1: Antigravityの役割限定【MUST】
Antigravity（IDE/司令塔）は以下の役割に限定する：

1. **司令塔**: TICKET作成、AI割当指示、進捗確認
2. **レビュー**: diff確認、Evidence確認、DoD確認
3. **確認**: Verify結果、状態遷移、証跡整合性

**禁止**: 直接のファイル編集・削除・一括置換・git操作（commit/push以外）

### D-0006-2: 削除系操作の安全柵【MUST】
以下の削除系操作は **HumanGate必須**：

- `rm -r`, `rm -rf` （ファイル・ディレクトリ削除）
- `git clean -fdx` （未追跡ファイル削除）
- sources/ 内の任意の変更・削除
- decisions/ 内のADR削除
- evidence/ 内の証跡削除
- worktree削除（`git worktree remove`）

**例外**:
- 一時ファイル削除（`*.tmp`, `*.log`）はPatchOnly Tierで可
- 削除前にDry-run表示必須（影響範囲確認）

### D-0006-3: 作業ディレクトリ固定【MUST】
AIエージェント実行時は以下のディレクトリ固定を強制：

- **worktree内限定**: `worktree_TICKET-{ID}/` 配下のみ操作可
- **読み取り専用**: `docs/`, `sources/`, `decisions/`, `glossary/` （変更不可）
- **書き込み可**: `evidence/tasks/TICKET-{ID}/` （証跡保存専用）

**検証**: Fast Verifyで `sources/` 無改変確認（V-0004）

### D-0006-4: Permission Tier強制【MUST】
Antigravity経由のAI実行は以下のTier制限を強制：

| 操作種別 | 必要Tier | 確認方法 |
|---------|---------|---------|
| ファイル読み取り | ReadOnly | なし |
| docs/編集（最小差分） | PatchOnly | Dry-run表示 |
| Verify実行 | ExecLimited | 実行前確認 |
| 削除・sources改変・ADR追加 | HumanGate | 明示的承認 |

### D-0006-5: 緊急停止（Emergency Stop）【MUST】
以下の検出時は **即座に操作停止**：

- sources/ への改変検出（V-0004 FAIL）
- Permission Tier超過の実行試行
- worktree外への書き込み試行
- 禁止コマンド検出（V-0003 FAIL）

**復旧**:
1. 操作ログをevidence/emergency/に保存
2. HumanGateで原因確認
3. Rollback実行

## 選択肢

### 案A: 役割限定＋安全柵強化（採用）
**メリット**:
- 事故率激減
- 証跡とPermission Tierが明確
- HumanGateの範囲が明確

**デメリット**:
- 操作が若干手間（承認ステップ増加）

### 案B: 全操作許可（不採用）
**理由**:
- sources/改変、誤削除のリスク高
- Permission Tier無視
- 事故時の復旧困難

### 案C: Antigravity完全ReadOnly（不採用）
**理由**:
- TICKETコ作成・進捗更新ができない
- 運用が回らない

## 影響範囲

### 互換/移行
- 既存のPart06（IDE運用）と整合
- Part09（Permission Tier）と整合

### セキュリティ/権限
- Permission Tier強制により越権防止
- HumanGate範囲の明確化

### Verify/Evidence/Release への影響
- 緊急停止時の証跡保存
- Evidence PackにPermission Tier履歴を含める

## 実行計画

### 手順
1. Part18.md に「Antigravity安全柵」セクション追加
2. 禁止コマンドリスト（Part00 V-0003）に削除系を追記
3. Fast Verifyに「worktree外書き込み検出」を追加
4. evidence/emergency/ ディレクトリ作成

### ロールバック
- ADR-0006 を廃止マークし、Part18 の追記箇所を削除
- 緊急停止機能を無効化（ただし推奨しない）

### 検証（Verify Gate）
- Fast Verify: sources無改変（V-0004）、禁止コマンド検出（V-0003）
- 証跡4点: link/parts/forbidden/sources

## 結果

（後日記入：安全柵導入後の事故率、誤操作の減少率など）
