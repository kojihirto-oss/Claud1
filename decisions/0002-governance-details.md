# ADR-0002: 運用ガバナンス詳細（HumanGate・sources保護・verify証跡・RAG）

- 日付: 2026-01-11
- 状態: 承認
- 影響Part: Part02, Part09, Part10, Part12, Part13
- 参照: sources/生データ/VCG_VIBE_MASTER_DATASET_CONSOLIDATED_20260109.txt, decisions/0001-ssot-governance.md

## 背景
ADR-0001でSSOT運用の基本を定めたが、以下の4点が未決のまま運用に入ると判断ブレが発生する：
1. HumanGate（最終裁定者）の定義と権限範囲
2. sources/ フォルダの禁止操作と例外条件
3. verify_reports（証跡）の採用・保持ルール
4. RAG保存先（rag/ or .rag/）とバージョン管理方針

## 決定

### 1) HumanGate（Permission Tierの最上位）
- **定義**: 破壊的操作・全域変更・リリース確定など、**人間の明示的承認が必須**の操作レベル
- **対象操作（MUST NOT without approval）**:
  - 破壊コマンド: `rm -rf`, `git push --force`, `git reset --hard`, `curl | sh`
  - 全域変更: sources/の削除・上書き、VAULT/RELEASE直接編集、API破壊的変更
  - リリース確定: Production deploy, スナップショットRAG更新
- **承認フロー**:
  - 2段階承認（提案→レビュー→承認）
  - 緊急時: 事後承認可（ただし24時間以内に記録、再発防止をADR化）
- **例外**: なし（HumanGateを超える権限は存在しない）

### 2) sources/ 禁止操作（ADR-0001を詳細化）
- **禁止**: 削除・上書き・改変（MUST NOT）
- **許可**: 追記のみ（SHOULD: 日付suffix付きで新規ファイル追加、例: `sources/生データ/補足_20260111.md`）
- **例外**:
  - 誤コミット直後（1commit以内）の revert（git revert のみ、force pushは不可）
  - HumanGate承認の下での意図的削除（ADRに理由記録必須）
- **根拠**: sources/は「原文・一次情報」の保管庫。改変すると証跡の信頼性が破壊される。

### 3) verify_reports 採用ルール
- **標準**: 最新のFast PASS 1セットを採用
  - 4点セット: TICKET.md, CONTEXT_PACK.md, VERIFY_REPORT.md, EVIDENCE.md
  - 保存先: evidence/verify_reports/ （タイムスタンプ付き）
- **保持期間**: 直近3セットを保持（古いものは削除可）
- **Full Verify**: Mサイズ以上、または高リスク変更時に必須（Fast→Full昇格）
- **PASS基準**:
  - lint/unit/type check すべてGreen
  - secrets漏洩チェック通過
  - VERIFY_REPORT.mdに実行コマンド・成否・ログパス記録済み

### 4) RAG保存先と.gitignore方針
- **保存先**: `.rag/` （ドット始まり、隠しフォルダ）
- **.gitignore**: `.rag/` を追加（MUST: RAG indexは巨大化するためgit管理外）
- **スナップショット**: Release時のみ `.rag-snapshot-YYYYMMDD/` として手動保存（HumanGate）
- **再生成**: 必要時に `sources/` と `docs/` から再生成可能な設計（RAGは使い捨て）

## 選択肢

### HumanGate
1) **採用**: 2段階承認固定（提案→承認）— 事故防止を最優先
2) 却下: 1段階承認 — 速度重視だが、誤操作リスク高
3) 却下: 承認不要 — 最速だが、破壊操作を防げない

### sources/ 禁止操作
1) **採用**: 削除・上書き禁止、追記のみ許可 — 証跡保全
2) 却下: 自由編集可 — 柔軟だが、改竄リスク・根拠喪失
3) 却下: 完全Read-Only — 安全だが、補足追加不可

### verify_reports
1) **採用**: 最新Fast PASS 1セット + 直近3保持 — 軽量・実用的
2) 却下: 全履歴保持 — 安全だが、容量肥大
3) 却下: 最新1のみ — 最軽量だが、比較困難

### RAG保存先
1) **採用**: `.rag/` + .gitignore — 標準的な隠しフォルダ運用
2) 却下: `rag/` (非ドット) — 視認性高いが、git肥大リスク
3) 却下: git管理 — 完全履歴だが、巨大化で破綻

## 影響範囲

### 互換/移行
- 既存sources/は保護強化（削除不可が明確化）
- .rag/ フォルダ新規作成、.gitignore更新必須
- verify_reports/ フォルダ新規作成（evidence/配下）

### セキュリティ/権限
- HumanGate定義により、破壊操作の権限分離が明確化
- sources/保護により、証跡改竄防止

### Verify/Evidence/Release への影響
- verify_reports採用ルールにより、Evidence収集が標準化
- RAG方針により、Release時のスナップショット手順が確定

## 実行計画

### 手順
1. .gitignore に `.rag/` 追加
2. evidence/verify_reports/ フォルダ作成（.gitkeep配置）
3. Part02.md に用語定義追加（HumanGate, sources保護, verify_reports, RAG）
4. Part09.md（Permission Tier）にHumanGate運用詳細を追記（次回作業）

### ロールバック
- .gitignore修正: git revertで復元
- フォルダ作成: rmdir（空なら即削除可）
- Part02編集: git revertで復元

### 検証（Verify Gate）
- Fast Verify PASS確認（checks/verify_repo.ps1 -Mode Fast）
- .gitignore構文チェック（git check-ignore -v .rag/）

## 結果
（後日記入：運用開始後の学び、調整事項）
