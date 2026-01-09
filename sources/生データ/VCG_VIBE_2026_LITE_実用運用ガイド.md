# VCG/VIBE 2026 LITE — 実用運用ガイド

**目的**: 50+フォルダ級の大規模開発を、個人が**毎日実際に回せる**運用で完走する

**設計思想**: 理想版の思想（SSOT→Verify→Evidence→Release）を維持しつつ、認知負荷とファイル数を1/3に圧縮

---

## 0. 変更サマリー（理想版→LITE版）

| 観点 | 理想版 | LITE版 |
|------|--------|--------|
| ステージ数 | 8段階 | **4段階**（統合） |
| 必須ファイル | 8種類/チケット | **1〜3種類**（サイズ別） |
| 並列運用 | 4AI同時 | **疑似並列**（フェーズ分離） |
| 自動化 | 未実装多数 | **3コマンド**で最小MVP |
| テンプレ | 全項目必須 | **必須/任意**を明確分離 |

---

## 1. コア思想（これだけは絶対に守る）

### 1.1 精度の定義（変更なし）
```
精度 = 仕様解釈が正しい
     + Verifyで機械的に合否が出る
     + 修理が最小差分で収束する
     + 証跡が残り再利用できる
```

### 1.2 気合い禁止（物理的強制）
```
❌ 「今日は疲れてるからチェック省略」
⭕ 権限・環境で物理的に不可能化する
```

**必須3点**（これだけは今日やる）:
1. `VAULT/` と `RELEASE/` を ReadOnly 化
2. 作業は必ず `WORK/` または worktree で行う
3. CLAUDE.md に禁止事項を明記

### 1.3 ファイル納品主義（変更なし）
```
AIに「自由作文」させない → 必ずファイルで引き継ぐ
```

---

## 2. 4ステージ運用（8→4に圧縮）

### 理想版との対応表

```
【理想版 8ステージ】          【LITE版 4ステージ】
INBOX  ─┐
TRIAGE ─┼─────────────────→  PLAN（計画）
SPEC   ─┘

BUILD  ─┬─────────────────→  BUILD（実装）
REPAIR ─┘

VERIFY ─┬─────────────────→  CHECK（検証）
        │
EVIDENCE─┼────────────────→  DONE（完了）
RELEASE ─┘
```

### 4ステージの定義

| ステージ | 目的 | 主担当 | 出力 |
|----------|------|--------|------|
| **PLAN** | 何をやるか決める | Gemini→GPT | TICKET.md |
| **BUILD** | 最小差分で実装 | Claude | PATCH.diff |
| **CHECK** | 機械で合否判定 | CI→GPT | （失敗時のみ記録） |
| **DONE** | 証跡を残して封印 | GPT | DONE.md |

---

## 3. チケットサイズ別運用（最重要）

### サイズ判定基準

| サイズ | 目安 | 例 |
|--------|------|-----|
| **S** | 30分以内 | typo修正、設定変更、小さなバグ修正 |
| **M** | 半日〜1日 | 機能追加、中規模リファクタ |
| **L** | 2日〜1週間 | 新モジュール、大規模改修 |
| **XL** | 1週間以上 | アーキテクチャ変更、基盤刷新 |

### サイズ別の必須ファイル

```
【Sサイズ】最小運用（1ファイル）
└── TICKET.md のみ（3行でOK）

【Mサイズ】標準運用（2ファイル）
├── TICKET.md（計画+仕様）
└── DONE.md（証跡+完了）

【Lサイズ】フル運用（3ファイル）
├── TICKET.md（計画+仕様+リスク）
├── CONTEXT_PACK.md（AIへの入力束）
└── DONE.md（証跡+学び+リリースノート）

【XLサイズ】理想版フル（必要に応じて追加）
├── 上記3ファイル
├── ADR.md（アーキテクチャ決定記録）
├── RISK_REGISTER.md
└── VERIFY_REPORT.md（詳細）
```

---

## 4. テンプレート（コピペ即運用）

### 4.1 TICKET.md（統合版）

```markdown
# TICKET: <チケット名>

## サイズ: S / M / L / XL（選択）

## 何をやるか（1行）
<!-- 例: ログイン画面にパスワードリセット機能を追加 -->

## なぜやるか（1行）
<!-- 例: ユーザーからの問い合わせが月50件発生 -->

## 受入基準（Verifyで判定できる形で）
- [ ] パスワードリセットメールが送信される
- [ ] リセットリンクは24時間で失効する
- [ ] 既存のログイン機能に影響がない

## 制約（破ってはいけないこと）
<!-- 任意: 技術/互換/性能/セキュリティ -->

## リスク（Mサイズ以上で記入）
<!-- 任意: 最大3件。脅威/対策/残余 -->

## ロールバック手順（Lサイズ以上で記入）
<!-- 任意: 戻し方を明記 -->

---
## 調査メモ（Gemini/検索結果を貼る場所）
<!-- 参照URL、既存コード影響、代替案など -->
```

### 4.2 DONE.md（証跡+完了統合版）

```markdown
# DONE: <チケット名>

## 完了日: YYYY-MM-DD

## 何を変えたか
<!-- 変更ファイル、差分の要約 -->

## なぜ変えたか
<!-- TICKET.mdの「なぜやるか」を実装観点で補足 -->

## どう検証したか
- [ ] Fast Verify: lint/test 通過
- [ ] Full Verify: CI全部通過（該当する場合）
- 確認コマンド: `npm test` / `pytest` / etc.

## 学び・再発防止（任意だが推奨）
<!-- 次回から使える知見 -->

## リリースノート（Mサイズ以上）
<!-- ユーザー向けの変更説明 -->
```

### 4.3 CONTEXT_PACK.md（Lサイズ以上で使用）

```markdown
# CONTEXT_PACK: <チケット名>

## SPEC要約（1画面で収まる量）
<!-- TICKET.mdから抜粋 -->

## 変更対象ファイル（最小集合）
- `src/auth/login.ts` - ログイン処理本体
- `src/auth/reset.ts` - 新規作成
- `tests/auth.test.ts` - テスト追加

## 現状の差分（あれば）
```diff
// 予定差分または現状差分を貼る
```

## 制約（絶対に破るな）
1. 既存のログイン処理は変更しない
2. メール送信は既存のMailServiceを使う

## 既知の落とし穴（過去の失敗から）
<!-- 過去のVERIFY失敗、類似チケットのエラーなど -->
```

---

## 5. AI役割分担（Core4 LITE版）

### 基本分担（変更なし）

| AI | 役割 | いつ使う |
|----|------|----------|
| **Claude** | 実装・修理 | BUILD時 |
| **GPT** | 設計確認・監査・判定 | PLAN確定時、CHECK時 |
| **Gemini** | 調査・根拠収集 | PLAN時の調査 |
| **Z.ai** | 整形・要約・前処理 | CONTEXT_PACK生成 |

### 疑似並列フロー（現実的な運用）

```
【理想版の並列】
Claude──┐
GPT────┼──→ 同時進行（認知負荷：高）
Gemini──┤
Z.ai───┘

【LITE版の疑似並列】
Phase 1: Gemini → 調査（バックグラウンド可）
    ↓
Phase 2: Z.ai → CONTEXT_PACK生成（自動化推奨）
    ↓
Phase 3: Claude → 実装（ここだけ人間が集中）
    ↓
Phase 4: GPT → 監査・判定（実装完了後）
```

**ポイント**: 人間の集中が必要なのはPhase 3だけ。他は非同期で回せる。

---

## 6. 自動化MVP（3コマンド）

### 最小限これだけ作る

```powershell
# PowerShell版の例

# 1. vibekanban status - 現在の状態を表示
function vibekanban-status {
    Write-Host "=== VIBEKANBAN Status ===" -ForegroundColor Cyan
    Get-ChildItem -Path ".\WORK\*\TICKET.md" | ForEach-Object {
        $ticket = $_.Directory.Name
        $done = Test-Path ".\WORK\$ticket\DONE.md"
        $status = if ($done) { "✅ DONE" } else { "🔨 ACTIVE" }
        Write-Host "$status : $ticket"
    }
}

# 2. vibekanban new <name> <size> - 新規チケット作成
function vibekanban-new {
    param([string]$name, [string]$size = "M")
    $path = ".\WORK\$name"
    New-Item -ItemType Directory -Path $path -Force
    # TICKET.mdテンプレートをコピー
    Copy-Item ".\TEMPLATES\TICKET_$size.md" "$path\TICKET.md"
    Write-Host "Created: $path\TICKET.md" -ForegroundColor Green
}

# 3. vibekanban verify - Fast Verify実行
function vibekanban-verify {
    Write-Host "=== Fast Verify ===" -ForegroundColor Cyan
    # lint
    Write-Host "Running lint..." -ForegroundColor Yellow
    npm run lint 2>&1 | Tee-Object -Variable lintResult
    # test
    Write-Host "Running tests..." -ForegroundColor Yellow
    npm test 2>&1 | Tee-Object -Variable testResult
    # 結果判定
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PASS" -ForegroundColor Green
    } else {
        Write-Host "❌ FAIL" -ForegroundColor Red
    }
}
```

### 将来の自動化（Phase 2以降）

```
【MVP後に追加】
4. vibekanban pack   → CONTEXT_PACK自動生成（Z.ai呼び出し）
5. vibekanban done   → DONE.md生成 + RELEASE/へ移動
6. vibekanban cost   → Cost Ledger集計

【さらに後】
7. Conductor Agent（ステージ自動提案）
8. 自己修復ループ（REPAIR自動化）
9. SSOT限定MCPサーバ
```

---

## 7. フォルダ構成（推奨）

```
PROJECT/
├── SSOT/                    # 唯一の真実（ReadOnly推奨）
│   ├── SPEC/               # 凍結仕様群
│   ├── ADR/                # アーキテクチャ決定記録
│   └── RUNBOOK/            # 運用手順書
│
├── VAULT/                   # 証跡保管庫（ReadOnly推奨）
│   ├── VERIFY/             # 検証結果
│   ├── TRACE/              # 障害・失敗ログ
│   └── COST/               # コスト記録
│
├── RELEASE/                 # 不変リリース（ReadOnly必須）
│   └── v1.0.0/
│
├── WORK/                    # 作業領域（ここだけ書き込み可）
│   ├── feature-login/
│   │   ├── TICKET.md
│   │   ├── CONTEXT_PACK.md  # Lサイズ以上
│   │   └── DONE.md          # 完了時
│   └── bugfix-auth/
│       └── TICKET.md
│
├── TEMPLATES/               # テンプレート置き場
│   ├── TICKET_S.md
│   ├── TICKET_M.md
│   ├── TICKET_L.md
│   └── DONE.md
│
├── CLAUDE.md                # Claude Code用プロジェクト規約
├── AGENTS.md                # Codex用プロジェクト規約
└── .vibekanban/             # 自動化スクリプト・設定
```

---

## 8. CLAUDE.md（Claude Code規約テンプレート）

```markdown
# CLAUDE.md - プロジェクト規約

## 許可された操作
- WORK/ 配下のファイル作成・編集・削除
- テスト実行（npm test, pytest, etc.）
- lint実行
- git add, git commit（WORK/配下のみ）

## 禁止された操作（絶対に実行しない）
- SSOT/, VAULT/, RELEASE/ への書き込み
- 全域リライト（ファイル全体の書き換え）
- rm -rf, git reset --hard, git push --force
- 無承認の自動実行（人間の確認なしにコマンド連続実行）
- 本番環境への直接操作

## 出力契約
実装時は必ず以下を出力:
1. 最小パッチ差分（理由つき）
2. 影響範囲の説明
3. 追加/更新テストの内容

## コンテキスト
- TICKET.md を読んで仕様を理解する
- CONTEXT_PACK.md がある場合はそれも読む
- 既存コードのスタイルに合わせる
```

---

## 9. AGENTS.md（Codex規約テンプレート）

```markdown
# AGENTS.md - Codex/OpenAI Agent規約

## プロジェクト概要
<!-- プロジェクトの簡潔な説明 -->

## コーディング規約
- 言語: TypeScript / Python / etc.
- スタイル: Prettier / Black / etc.
- テスト: Jest / pytest / etc.

## 作業ルール
1. WORK/ 配下でのみ作業する
2. 変更前に TICKET.md を確認する
3. 大きな変更は事前に計画を提示する

## 禁止事項
- SSOT/, VAULT/, RELEASE/ への書き込み
- 破壊的操作（rm -rf, reset, force push）
- 無承認の自動実行
```

---

## 10. 毎日のワークフロー（実践版）

### 朝のルーティン（5分）

```
1. vibekanban status で現状確認
2. 今日やるチケットを1つ選ぶ
3. サイズを判定（S/M/L/XL）
```

### チケット作業フロー

```
【Sサイズ】所要: 30分以内
┌─────────────────────────────────────┐
│ 1. TICKET.md に3行書く              │
│ 2. Claude で実装                    │
│ 3. vibekanban verify               │
│ 4. git commit                       │
└─────────────────────────────────────┘

【Mサイズ】所要: 半日〜1日
┌─────────────────────────────────────┐
│ 1. TICKET.md を埋める（受入基準まで）│
│ 2. Gemini で調査（必要なら）         │
│ 3. Claude で実装                    │
│ 4. vibekanban verify               │
│ 5. DONE.md を書く                   │
│ 6. git commit                       │
└─────────────────────────────────────┘

【Lサイズ】所要: 2日〜1週間
┌─────────────────────────────────────┐
│ Day 1: PLAN                         │
│   - TICKET.md をフル記入            │
│   - Gemini で調査                   │
│   - GPT で仕様レビュー              │
│                                     │
│ Day 2+: BUILD                       │
│   - Z.ai で CONTEXT_PACK 生成       │
│   - Claude で実装（差分ベース）     │
│                                     │
│ 最終日: CHECK & DONE                │
│   - vibekanban verify (Full)        │
│   - GPT で最終監査                  │
│   - DONE.md を書く                  │
│   - RELEASE/ へ移動                 │
└─────────────────────────────────────┘
```

### 夕方のルーティン（3分）

```
1. 今日の進捗を TICKET.md に追記
2. 明日の予定を確認
3. （週1回）Cost Ledger を更新
```

---

## 11. トラブルシューティング

### Q: Verifyが通らない（REPAIR地獄）

```
1. FAIL_SUMMARY を作成（エラーログ要約）
2. Claude に「最小修正で通す方法」を2案出させる
3. GPT に「どちらが最短でGreen」か判定させる
4. 3回ループしても通らない → 設計を疑う（SPECに戻る）
```

### Q: チケットが膨張する

```
1. サイズを再判定（SだったのがLになってないか）
2. Lなら分割を検討（複数のMに分ける）
3. 「これはやらない」を TICKET.md の非目的に明記
```

### Q: 証跡を書くのが面倒

```
1. DONE.md は「最小4点」だけ書く
   - 何を変えたか（1行）
   - なぜ変えたか（1行）
   - どう検証したか（コマンド名だけ）
   - 学び（任意）

2. 詳細は git log と CI結果で補完される
```

### Q: 複数チケットが並行して進む

```
1. WORK/ 配下にチケット別フォルダを作る
2. 各フォルダに TICKET.md を置く
3. 1日1チケットに集中を推奨（コンテキストスイッチ削減）
```

---

## 12. 導入チェックリスト

### Phase 1: 今日やること（30分）

- [ ] VAULT/, RELEASE/ を ReadOnly 化
- [ ] CLAUDE.md をプロジェクトルートに配置
- [ ] TEMPLATES/ フォルダを作成し、テンプレをコピー
- [ ] vibekanban-status 関数を PowerShell プロファイルに追加

### Phase 2: 1週間以内

- [ ] vibekanban-new, vibekanban-verify を追加
- [ ] 最初の3チケットを新運用で回す
- [ ] 運用に合わない部分をメモ

### Phase 3: 1ヶ月後

- [ ] Cost Ledger を週1で記録開始
- [ ] CONTEXT_PACK 自動生成を検討
- [ ] 失敗RAG（過去のエラー検索）を検討

---

## 13. 理想版との対応表（困ったら参照）

| LITE版の概念 | 理想版での対応箇所 |
|--------------|-------------------|
| TICKET.md | SPEC.md + TRIAGE.md + RISK_REGISTER.md |
| DONE.md | EVIDENCE.md + RELEASE_NOTE.md |
| CONTEXT_PACK.md | 同じ |
| vibekanban verify | Fast Verify + Full Verify |
| 4ステージ | 8ステージを統合 |
| サイズ別運用 | 新規追加（理想版にはない） |

---

## 14. 最終メッセージ

> **「完璧な運用を目指して何もしない」より「60%の運用を今日から回す」**

このLITE版は理想版の80%の効果を20%の労力で得るための設計です。

まずは **Sサイズのチケットを3つ** この運用で回してみてください。
慣れてきたら、必要に応じて理想版の要素を追加していけばOKです。

---

*Document Version: 2026-01-09 LITE v1.0*
*Based on: VCG/VIBE 2026 AI統合運用マスタードキュメント*
