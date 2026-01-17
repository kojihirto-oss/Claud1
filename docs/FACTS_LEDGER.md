# FACTS LEDGER（事実台帳）

> sources/ から抽出した「確定情報」「要求」「制約」「決定」「未決事項」を、根拠パス付きで列挙する。
> 設計書本文を書き始める前に必ず埋める。

**抽出日**: 2026-01-09
**主要根拠**: sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md（以下「MASTER」）

---

## 1) 確定情報（方針/ルール）

### F-0001: 真実の優先順位（Truth Order）
**定義**: 矛盾時の裁定順序を固定する。
**内容**:
1. SSOT（本書/運用法規）が最上位
2. Verify（機械判定：テスト・静的解析・整合性検査）
3. Evidence（証跡：ログ・差分・manifest・sha256）
4. Release（固定成果物：凍結された成果物）
5. 会話・感想・推測は最下位（必ずVerify/Evidenceに昇格させる）

**根拠**: MASTER L14-19
**関連用語**: SSOT, Verify, Evidence, Release
**重要度**: 最高（Part00で明記必須）

---

### F-0002: 禁止事項（破壊防止）
**定義**: 以下の行為は原則禁止。
**内容**:
- 仕様凍結前に実装を開始しない（例外: SPIKEは隔離）
- Verifyを通していない変更をReleaseに入れない
- 証跡のない成功を成功と見なさない（再現性必須）
- 無言でファイル/フォルダ/名前を変えない（変更理由・影響・ロールバック手順をEvidenceに残す）
- AIに削除・整理・大掃除を丸投げしない（Dry-run→レビュー→実行→Verify）

**根拠**: MASTER L21-26
**関連用語**: Verify, Evidence, SPIKE, Dry-run
**重要度**: 最高（Part00で明記必須）

---

### F-0003: 変更規約（SSOT更新プロトコル）
**定義**: SSOTの更新手順を固定する。
**内容**:
- SSOTの更新は「PATCHSET」として作成し、VERIFYを通してからマージ
- 変更単位は「最小差分」で、目的が単一であること（混ぜない）
- 更新のたびに版番号（YYYY-MM-DD）とCHANGELOGを必ず更新
- 失敗した更新は即座にロールバックまたはRevert（放置禁止）

**根拠**: MASTER L28-32
**関連用語**: PATCHSET, Verify, CHANGELOG
**重要度**: 最高（Part00, Part14で明記）

---

### F-0004: フォルダ構造（ルート設計）
**定義**: 大規模開発でも迷わないための物理構造。
**推奨構造**（Windows前提）:
```
C:\Emperor\                # プロジェクト母艦（VCG_ROOT）
├── CodingDB_work\         # 作業領域（可変、破壊されても再生成可能）
├── CodingDB_releases\     # リリース領域（不変、READ-ONLY）
├── RAG\                   # RAG生成/投入のレーン
└── VAULT\                 # 証跡保管庫（Append-only）
```

**詳細構造**:
```
PROJECT_ROOT/
├── SSOT/
│   ├── STATUS.md
│   ├── POLICY.md          # 運用憲法
│   └── ADR/               # 意思決定ログ
├── VIBEKANBAN/
│   ├── 000_INBOX/
│   ├── 100_SPEC/
│   ├── 200_BUILD/
│   ├── 300_VERIFY/
│   ├── 400_REPAIR/
│   └── 900_RELEASE/
├── VAULT/
│   ├── RUNLOG.jsonl       # 全実行履歴
│   ├── VERIFY/
│   ├── EVIDENCE/
│   └── TRACE/
├── RELEASE/
│   └── RELEASE_YYYYMMDD_HHMMSS/
│       ├── manifest.jsonl
│       ├── sha256.csv
│       └── sbom/
├── WORK/                  # 作業コピー（worktree推奨）
└── _TRASH/                # 退避（削除しない）
```

**根拠**: MASTER L87-95, L522-551
**関連用語**: SSOT, VAULT, VIBEKANBAN, WORK, RELEASE
**重要度**: 高（Part00, Part02で明記）

---

### F-0005: レーン（Lane）概念
**定義**: 性質の違うデータを混ぜない物理隔離。
**内容**:
- `ai_ready/`: テキスト化・正規化済み（LLMにそのまま渡せる）
- `pdf_ocr_ready/`: PDF・画像→OCR専用レーン
  - `raw_pdf/`: 原本
  - `ocr_text/`: OCR結果
  - `manifest.jsonl`: 対応表
- `raw/`: 未加工（ノイズあり）
- `staging/`: 変換中（途中成果物）
- `release/`: 凍結成果（READ-ONLY）

**根拠**: MASTER L96-107
**関連用語**: RAG, manifest
**重要度**: 中（Part02, Part06で明記）

---

### F-0006: 不変リリース（Immutable Release）
**定義**: リリースは「成果物」ではなく「証拠付きの状態」。
**内容**:
- リリースフォルダ命名: `generated_YYYYMMDD_HHMMSS/`
- 付随必須ファイル:
  - `_manifest.csv`: ファイル一覧とサイズ
  - `_sha256.csv`: 全ファイルのSHA-256
  - `STATUS.md`: 目的・DoD・Verify結果
  - `TRACE/`: ログ・diff・コマンド履歴
- ルール: リリース生成後に編集禁止。修正は新しいリリースで行う。

**根拠**: MASTER L108-117
**関連用語**: Release, Evidence, manifest, sha256, DoD
**重要度**: 高（Part01, Part10, Part14で明記）

---

### F-0007: Git戦略（事故ゼロの基本）
**定義**: Gitの安全運用ルール。
**内容**:
- `main`（または`trunk`）は常にGreen
- 作業は必ず分岐（branch）＋可能ならworktree（物理分離）
- 破壊的操作は `feature/*` でのみ実施し、Verifyを通してからマージ

**根拠**: MASTER L119-123
**関連用語**: Verify, worktree, branch
**重要度**: 高（Part09, Part14で明記）

---

### F-0008: Core4（AI役割固定）
**定義**: 4つの課金AIを役割で固定する運用設計。
**内容**:
- **ChatGPT（司令塔/編集長）**: SSOT維持、設計・統合判断、レビュー設計、品質ゲート設計
- **Claude Code（実装エンジン）**: 実装・修正・テスト駆動の反復（CLI/デスクトップ）
- **Gemini / Google One Pro（調査・統合ハブ）**: 外部情報、長文理解、Google連携、Antigravity連動
- **Z.ai Lite（補助LLM/API/MCP）**: 軽量タスク、補助分析、並列ワーク（データ分類で制限）

**注意**: 軽量・安価なモデルを"本流の真実"にしない。必ずVerify/Evidenceで固定する。

**根拠**: MASTER L129-136
**関連用語**: Core4, Verify, Evidence
**重要度**: 高（Part03で明記）

---

### F-0009: IDEハブ（Google Antigravity）
**定義**: Antigravityは「コードを書く場所」ではなく「エージェントの指揮所」。
**内容**:
- Editor: 人間が読む/編集する
- Mission Control: エージェントが計画→実行→検証する
- ブラウザ・ターミナル・エディタの同期を前提に、作業の迷いをゼロにする

**根拠**: MASTER L137-142
**関連用語**: Antigravity, Agent Pack
**重要度**: 中（Part03で明記）

---

### F-0010: オーケストレーション（Vibe Kanban）
**定義**: Vibe Kanbanは「並列エージェント実行の安全装置」。
**内容**:
- タスクごとに**隔離されたgit worktree**で実行される（衝突防止）
- diffツールでレビューし、mainを守る
- 重要: Vibe Kanbanを「人間の計画→AIの実行→人間の承認」の型に固定する

**根拠**: MASTER L143-148
**関連用語**: VIBEKANBAN, worktree, diff
**重要度**: 高（Part04, Part14で明記）

---

### F-0011: MCP（Model Context Protocol）導入方針
**定義**: LLMアプリと外部データ/ツールを「安全に接続」するためのオープンプロトコル。
**目的**:
- "コピペ地獄"を終わらせ、同じコンテキストを複数AIで共有
- ツール実行（検索/DB/ファイル操作）を標準化

**方針**:
- 読み取り系MCPから開始（Read-only）
- 書き込み系は「Patch-only」「許可制」
- 監査ログ（Evidence）を必須化

**根拠**: MASTER L149-159
**関連用語**: MCP, Evidence, Permission Tier
**重要度**: 中（Part03, Part09で明記）

---

## 2) 要求（やりたいこと）

### F-0020: プロジェクト目的
**内容**:
- 50+フォルダ級の大規模開発を、**迷いゼロ**（次に何をすべきかが常に一意）で進める
- 事故ゼロ: 誤削除/誤上書き/依存壊し/ビルド不能化/セキュリティ事故（鍵混入など）/「動いてる気がする」状態の放置
- トップクラス精度: 仕様準拠が機械的に担保される/変更が最小化される/検証・証跡・再現性・ロールバックが常備される

**根拠**: MASTER L39-50
**関連用語**: DoD, Verify, Evidence, Rollback
**重要度**: 最高（Part00, Part01で明記）

---

### F-0021: タスク（TICKET）DoD
**定義**: タスク単位の完了条件。
**内容**:
- Spec（仕様）が凍結され、Acceptance（受入条件）が機械判定可能
- Build（実装）がSpecに一致し、差分が最小
- Verify（テスト・静的解析・スキャン）が全てGreen
- Evidence（ログ・diff・manifest・sha256・実行結果）が保存される
- Release（必要な場合）は版管理され、復元できる

**根拠**: MASTER L55-60
**関連用語**: DoD, Spec, Verify, Evidence, Release
**重要度**: 最高（Part01, Part10で明記）

---

### F-0022: リリースDoD
**定義**: リリース単位の完了条件。
**内容**:
- リリースフォルダがREAD-ONLY（改変不能）である
- バイナリ/生成物の整合性（sha256）が取れている
- SBOMが生成され、依存が追跡できる（最小でもCycloneDXまたはSPDX）
- 主要なセキュリティスキャンが実施され、重大な問題がゼロか、例外が承認済み（例外には期限がある）

**根拠**: MASTER L62-66
**関連用語**: DoD, SBOM, sha256, Permission Tier
**重要度**: 高（Part01, Part10で明記）

---

### F-0023: メトリクス（運用で回す）
**定義**: 運用精度を計測する指標。
**内容**:
- 収束性: VRループが何回でGreenに戻るか
- 再現性: クリーン環境でVerifyが通るか
- 変更最小性: パッチ行数/ファイル数/影響範囲
- 事故率: 破壊的変更の回数、鍵混入、ロールバック回数
- 迷いゼロ指数: 次アクションがSSOT/ダッシュボードで明確か

**根拠**: MASTER L75-80
**関連用語**: Verify, VRループ, SSOT
**重要度**: 中（Part01, Part10で明記）

---

## 3) 制約（できないこと/禁止）

### F-0030: 失敗定義（Failure）
**定義**: 以下の状態は失敗と見なす。
**内容**:
- Verifyに失敗したまま「次へ進む」
- Evidenceが残っていない
- 変更理由が説明できない（誰がなぜ何をしたか不明）
- 「後で直す」タスクが増殖して収束しない（VRループが回っていない）
- 依存や環境差で再現できない

**根拠**: MASTER L68-73
**関連用語**: Verify, Evidence, VRループ
**重要度**: 高（Part01, Part10で明記）

---

### F-0031: 破壊操作の扱い
**定義**: 削除・移動・上書きは二段階承認。
**内容**:
- 標準は `_TRASH/` への退避（rename/move）＋世代管理（timestamp）＋manifest＋sha256
- Dry-run → 人間承認 → 実行の二段階
- `rmdir / s / q`, `rm -r -f`, `git push --for ce`, `curl ｜ sh` などはAIに直接生成・実行させない（HumanGateのみ）

**根拠**: MASTER L1037-1042, L657-665
**関連用語**: HumanGate, Permission Tier, Dry-run
**重要度**: 最高（Part09で明記）

---

### F-0032: 仕様凍結前の実装禁止
**定義**: Specが凍結されるまでBuildしない。
**内容**:
- 曖昧さ・矛盾・用語ゆれは「実装で埋めない」。必ずSpecへ戻す
- 例外: 調査用スパイクは「SPIKE」扱いで隔離し、成果は仕様へ移すまで本流に混ぜない

**根拠**: MASTER L467-468, L22
**関連用語**: Spec, SPIKE, Spec Freeze
**重要度**: 最高（Part01, Part04で明記）

---

## 4) 使うツール/役割

### F-0040: タスク（TICKET）の標準フォーマット
**定義**: 各TICKETは以下を必ず含む。
**内容**:
- `Goal`: 何を達成するか（1文）
- `Non-Goals`: やらないこと（暴走防止）
- `Inputs`: 参照データ（SSOTの該当箇所、ファイル、URL等）
- `Acceptance`: 機械判定可能な受入条件
- `Risks`: 壊れやすい箇所/権限/鍵/外部依存
- `Plan`: 手順（箇条書き）
- `Verify`: 実行コマンド/チェック項目
- `Evidence`: 保存先と保存物
- `Rollback`: 戻し方

**根拠**: MASTER L164-176
**関連用語**: TICKET, Acceptance, Verify, Evidence, Rollback
**重要度**: 高（Part04で明記）

---

### F-0041: サイズ分類（S/M/L/XL）
**定義**: タスクのサイズを固定する。
**内容**:
- **S（30～90分）**: 単一ファイルor単一バグ、変更≤50行、Verify≤5分
- **M（半日）**: 複数ファイル、変更≤300行、Verify≤20分
- **L（1～3日）**: 設計変更あり、テスト拡充、移行含む
- **XL（1週間+）**: 分割必須（XLは禁止。必ずL以下に割る）

**根拠**: MASTER L177-182
**関連用語**: TICKET, WIP制限
**重要度**: 中（Part04で明記）

---

### F-0042: WIP制限（並列の上限）
**定義**: 個人運用での並列上限。
**内容**:
- S: 並列2
- M: 並列1
- L: 並列0（単独集中）
- エージェント並列は「worktree隔離」が前提。隔離できないなら並列禁止。

**根拠**: MASTER L183-189
**関連用語**: WIP, worktree
**重要度**: 中（Part04で明記）

---

### F-0043: 進捗状態（Kanban状態の定義）
**定義**: タスクの状態遷移。
**内容**:
- `READY`: Spec凍結済み
- `DOING`: 実装中（変更が発生）
- `VERIFYING`: Verify実行中
- `REPAIRING`: 失敗修正
- `DONE`: DoD満たしEvidence保存済み
- `BLOCKED`: 外部依存/不明点があり停止（解除条件を明記）

**根拠**: MASTER L190-197
**関連用語**: VIBEKANBAN, DoD, Evidence
**重要度**: 中（Part04で明記）

---

### F-0044: SBF（工程）＝1本の仕事を最後まで通す型
**定義**: 工程の固定型。
**内容**:
- **S = Spec**: 設計書（PRD/DESIGN/ACCEPTANCE）を作り凍結
- **B = Build**: 凍結仕様どおりに実装を完走
- **F = Fix**: 失敗ログから直してGreenに戻す

**根拠**: MASTER L203-207
**関連用語**: SBF, Spec, Verify
**重要度**: 最高（Part01, Part05で明記）

---

### F-0045: PAVR（運用）＝Bを成功させるための回し方
**定義**: 運用ループ。
**内容**:
- **P = Prepare**: 硬い基盤（環境・ルール・ツール）
- **A = Author**: 仕様を完成させて凍結（Specの完成）
- **V = Verify**: 機械判定で合否を出す
- **R = Repair**: 修正→再検証で収束（VRループ）

**根拠**: MASTER L208-213
**関連用語**: PAVR, Verify, VRループ
**重要度**: 最高（Part01, Part05で明記）

---

### F-0046: 具体フロー（毎タスク共通）
**定義**: 全タスクで共通の実行フロー。
**手順**:
1. **Prepare**: 依存更新、環境確認、秘密情報の保護、worktree準備
2. **Author**: SPEC.md作成（Acceptanceを含む）→凍結宣言
3. **Build**: 最小パッチで実装。途中で仕様が揺れたらBuildを止め、Specへ戻す
4. **Verify**: テスト、lint、型、静的解析、スキャン
5. **Repair**: 失敗ログをEvidenceへ保存。修正→Verifyを繰り返し、Greenに収束
6. **Evidence**: diff、ログ、実行コマンド履歴、manifest/sha256を保存
7. **Release**: 必要なら不変リリース生成

**根拠**: MASTER L214-232
**関連用語**: Prepare, Author, Verify, Repair, Evidence, Release
**重要度**: 最高（Part05で明記）

---

### F-0047: Focus Pack（タスク局所コンテキスト）
**定義**: このタスクに必要な最小コンテキスト。毎タスク必ず作る。
**内容**:
- `FOCUS.md`: ゴール、前提、禁止、受入条件
- `SCOPE.tree`: 関係フォルダ/ファイル一覧
- `DIFF_POLICY.md`: 変更最小ルール
- `VERIFY.md`: 実行コマンド

**根拠**: MASTER L237-244
**関連用語**: Focus Pack, Context Pack
**重要度**: 中（Part06で明記）

---

### F-0048: Agent Pack（エージェント共通ルール）
**定義**: エージェント実行の共通ルール。
**内容**:
- 役割、権限、禁止事項、出力形式
- 作業開始前に「Plan→Confirm→Execute」の順を守る
- 破壊的操作は必ず「Dry-run」「バックアップ」「レビュー」

**根拠**: MASTER L245-249
**関連用語**: Agent Pack, Dry-run, Permission Tier
**重要度**: 中（Part06, Part09で明記）

---

### F-0049: RAGの位置付け（必要性と最小実装）
**定義**: 50+フォルダ級では、RAGがないと"迷いゼロ"は維持できない。
**最小RAG（Minimum Viable RAG）**:
- SSOT全文
- フォルダ索引（tree/manifest）
- コマンド索引（verify/build/release）
- 既知の障害と対処（Runbook）

**RAG更新の鉄則**:
- RAGは「真実」ではない。真実はSSOT＋Verify＋Evidence
- RAG更新は必ずEvidence（差分・件数・ハッシュ）を残す

**根拠**: MASTER L250-263
**関連用語**: RAG, SSOT, Verify, Evidence
**重要度**: 中（Part06で明記）

---

### F-0050: Verifyの層（Layer）
**定義**: Verifyを弱くすると、全てが"雰囲気"になる。最重要。
**層**:
1. ビルド/テスト（最優先）
2. 静的解析/型/リンタ
3. セキュリティ（秘密情報、依存脆弱性、SAST）
4. サプライチェーン（SBOM、Provenance、署名）
5. 整合性（manifest/sha256、再現性）

**根拠**: MASTER L269-275
**関連用語**: Verify, SBOM, Provenance, sha256
**重要度**: 最高（Part07, Part10で明記）

---

### F-0051: GitHub/CIで守る（ルール化）
**定義**: mainへのマージは、必要なステータスチェックが成功してから。
**内容**:
- ブランチ保護/ルールセットで「人間のうっかり」を潰す
- CodeQL等のスキャンを標準化し、重要アラートはブロック

**根拠**: MASTER L276-280
**関連用語**: CI, ブランチ保護, CodeQL
**重要度**: 高（Part07, Part10で明記）

---

### F-0052: Secrets/依存/脆弱性（最低限の必須）
**定義**: セキュリティスキャンの最低限。
**内容**:
- **Secrets検出**: Gitleaks等
- **依存脆弱性/ライセンス**: Trivy / SBOMスキャン
- **SAST**: Semgrep / CodeQL

**根拠**: MASTER L281-285
**関連用語**: Gitleaks, Trivy, SBOM, SAST
**重要度**: 高（Part07, Part10で明記）

---

### F-0053: Evidenceの必須物
**定義**: 証跡として必ず残すもの。
**内容**:
- 仕様（SPEC.md）
- diff（patch / PRリンク）
- Verifyログ（標準出力＋要点）
- 生成物のmanifest/sha256
- 失敗時のログ（Repairの根拠）
- ロールバック手順

**根拠**: MASTER L320-327
**関連用語**: Evidence, Spec, Verify, manifest, sha256, Rollback
**重要度**: 最高（Part08, Part10で明記）

---

### F-0054: Evidenceの保存場所（標準）
**定義**: 証跡の標準保存先。
**内容**:
- `TRACE/`: タスク単位（時系列）
- `VAULT/`: リリース単位（不変）
- `RUNS/`: 実行記録（コマンドと結果）

**根拠**: MASTER L328-332
**関連用語**: TRACE, VAULT, Evidence
**重要度**: 高（Part08で明記）

---

### F-0055: Permission Tier（AI権限設計）
**定義**: AIに渡す権限レベルを固定する。
**権限レベル**:
- **ReadOnly**: 読むだけ（解析・提案・レビュー）
- **PatchOnly**: 差分作成OK、実行は不可（PR/patch生成）
- **ExecLimited**: 許可コマンドのみ実行（tests/lint/buildなど）
- **HumanGate**: 破壊操作・全域変更・リリース確定など（人の承認必須）

**Allowlist（許可コマンド）**:
- 許可: pytest, npm test, pnpm lint, ruff, mypy, docker compose up など
- 禁止: `rm -r -f`, `git push --for ce`, `curl ｜ sh` など（HumanGateのみ）

**根拠**: MASTER L512, L655-665
**関連用語**: Permission Tier, HumanGate, Allowlist
**重要度**: 最高（Part09で明記）

---

### F-0056: Verify Gate（機械判定の設計）
**定義**: Fast/Fullで回す。
**内容**:
- **Fast Verify**: 最短で壊れを検出（lint + unit + 型/静的解析の一部）
- **Full Verify**: CI相当の全検査（integration/e2e + security + SBOM + 再現実行）

**Verifyの必須カテゴリ**:
- 正しさ: tests
- 一貫性: format/lint/type
- 安全: secrets/依存脆弱性/静的解析
- 供給網: SBOM / provenance（可能なら）
- 再現性: クリーン環境で同じ結果（Docker/CI）

**Verifyレポート（必須成果物）**:
- `VAULT/VERIFY/VERIFY_REPORT.md` に保存
- 実行コマンド（正確に）、成否、失敗ログ抜粋（重要部）、参照ログへのパス、主要メトリクス（任意）

**根拠**: MASTER L667-680
**関連用語**: Verify Gate, Fast Verify, Full Verify, SBOM
**重要度**: 最高（Part10で明記）

---

### F-0057: Repair（VRループ）
**定義**: 失敗を"分類"して収束させる。
**失敗分類**:
- Spec系: 前提が違う／受入基準が曖昧 → GPTへ戻す
- 依存/環境系: バージョン衝突／OS差 → Docker/lock/CIで固定
- 実装系: 局所バグ → Claudeで最小修正
- テスト系: テスト不足／壊れたテスト → テストを直し、意図をSpecへ

**ループ制限（暴走防止）**:
- 同じ失敗が3ループを超えたら: Z.aiでログ要約 → GPTで根本原因 → Claudeで修正に切り替える
- それでも収束しない場合はHumanGate（設計変更/分割/範囲縮小）

**根拠**: MASTER L682-693
**関連用語**: VRループ, HumanGate
**重要度**: 高（Part10, Part11で明記）

---

### F-0070: Vibe Kanban 実行モデル（隔離と並列）
**定義**: エージェント実行の物理隔離とオーケストレーション。
**内容**:
- **Worktree隔離**: 各タスクはGit Worktree上で実行され、依存関係や設定ファイル（.env等）は自動コピーが必要。
- **並列/順序**: 依存関係のないタスクは並列、あるタスクは順序実行。
- **起動**: `npx vibe-kanban` を標準とする。

**根拠**: factpack_ai_ops.md (VK-01, VK-03, VK-06)
**関連用語**: Vibe Kanban, Worktree, Orchestration
**重要度**: 高（Part04, Part18で明記）

---

### F-0071: Vibe Kanban 機能集約
**定義**: 開発運用機能の集約ハブ。
**内容**:
- レビュー、Dev Server起動、タスク状態追跡を一元管理。
- **ローカルMCP**: ローカル専用MCPサーバを提供し、外部ツールから操作可能（外部公開は禁止）。
- **対応エージェント**: Claude Code, Gemini CLI, Cursor等から選定して利用。

**根拠**: factpack_ai_ops.md (VK-02, VK-04, VK-05)
**関連用語**: Vibe Kanban, MCP Server
**重要度**: 中（Part02, Part18で明記）

---

### F-0072: Gemini CLI MCP管理
**定義**: スコープによるMCP設定の分離。
**内容**:
- コマンド: `gemini mcp add/list/remove`
- スコープ: `user`（個人実験）と `project`（チーム共有）を分離。
- 設定ファイル: `project` スコープは `.gemini/settings.json` に保存（機密情報は環境変数化）。

**根拠**: factpack_ai_ops.md (GEM-01, GEM-02)
**関連用語**: Gemini CLI, MCP, Scope
**重要度**: 中（Part04, Part06で明記）

---

### F-0073: Antigravity Mission Control
**定義**: 自律エージェントの司令塔（計画・実装・検証）。
**内容**:
- Editor ViewとManager Surfaceで構成され、ブラウザ・ターミナル・エディタを横断操作。
- 確認なしで実装に進む場合があり、人間は「停止/コメント」で介入する。
- Artifacts（録画/スクショ）で進捗を可視化。

**根拠**: factpack_ai_ops.md (AG-01, AG-02, AG-05)
**関連用語**: Antigravity, Mission Control, Artifacts
**重要度**: 高（Part06, Part18で明記）

---

### F-0074: Antigravity 安全装置（Safety Rails）
**定義**: 権限の強制制御。
**内容**:
- **ターミナル**: 削除系（`rm`等）はAllow List外とし、実行前に強制レビュー（承認）を入れる。
- **ブラウザ**: JS実行等の自動操作は「Request review」を標準とし、勝手な操作を防ぐ。

**根拠**: factpack_ai_ops.md (AG-03, AG-04)
**関連用語**: Antigravity, Allow List, Request review
**重要度**: 最高（Part09, Part18で明記）

---

### F-0075: MCP vs RAG 役割分離
**定義**: 情報取得経路の厳格な使い分け。
**内容**:
- **MCP Resources**: 「ローカル引用」。URI指定で正確なデータを取得（仕様書・ログ・設定）。`resources/read` 使用。
- **RAG**: 「意味検索」。大量の文書から関連情報を探索・統合。出典確認が必須。
- **原則**: 混在時は取得経路を明示する。

**根拠**: factpack_ai_ops.md (MR-01, MR-02, MR-03)
**関連用語**: MCP Resources, RAG, Information Retrieval
**重要度**: 高（Part06, Part16で明記）

---

### F-0076: （欠番）
**定義**: 未使用。

---

## 5) フォルダ構造・命名

### F-0060: リリースフォルダ命名規則
**定義**: `generated_YYYYMMDD_HHMMSS/`
**根拠**: MASTER L111
**関連用語**: Release
**重要度**: 高（Part08, Part14で明記）

---

### F-0061: VIBEKANBAN フォルダ命名
**定義**: 状態ごとにフォルダを分ける。
**構造**:
```
VIBEKANBAN/
├── 000_INBOX/
├── 100_SPEC/
├── 200_BUILD/
├── 300_VERIFY/
├── 400_REPAIR/
└── 900_RELEASE/
```
**根拠**: MASTER L527-535
**関連用語**: VIBEKANBAN
**重要度**: 中（Part04で明記）

---

### F-0062: RUNLOG.jsonl の形式
**定義**: 1行=1実行。
**最低限入れる項目**:
- `ts`: タイムスタンプ
- `actor`: human|claude|gpt|gemini|glm
- `command`: 実行コマンド
- `input_hash` / `output_hash`
- `env`: docker image / python/node version
- `approval`: HumanGateの承認記録
- `link`: VERIFY_REPORT/TRACEへの参照

**例**:
```jsonl
{"ts":"2026-01-09T13:00:00+09:00","actor":"claude","tier":"ExecLimited","cmd":"pytest -q","cwd":"WORK/repo","input_hash":"...","output_hash":"...","result":"FAIL","links":{"verify":"VAULT/VERIFY/...","trace":"VAULT/TRACE/..."}}
```

**根拠**: MASTER L718-720, L851-853
**関連用語**: RUNLOG, Evidence
**重要度**: 中（Part08で明記）

---

## 6) 未決事項（推測禁止）

### U-0001: Antigravityの実体
**問題**: MASTER で「Google Antigravity」を主IDEとして記載しているが、2026年1月時点で実在しない可能性。
**選択肢**:
- 実在する場合: そのまま採用
- 架空の場合: VS Code / Project IDX / GitHub Copilot Workspace など実在IDEに置き換え
- カスタム名称の場合: 実体（VS Code + 拡張機能の組み合わせ等）を明記

**対応**: Part03で「IDEハブ」として抽象化し、具体実装は環境依存として分離

---

### U-0002: Core4 の具体的な連携プロトコル
**問題**: ChatGPT / Claude Code / Gemini / Z.ai がどのように**同一タスク内で連携**するか、MASTERでは抽象的な役割分担のみで具体手順なし。
**不明点**:
- SpecをGPTで作成 → Claude Codeへどう渡す？（ファイル経由？API？MCP？）
- Verify失敗ログをZ.aiで要約 → Claude Codeへどう渡す？
- 並列実行時の衝突回避は？

**対応**: Part06（Context Pack）とPart09（Permission Tier）で具体化が必要

---

### U-0003: Windows以外の環境対応
**問題**: MASTERはWindows前提（`C:\Emperor\`, PowerShellスクリプト）だが、macOS/Linuxでの運用は？
**対応**: Part02で「推奨構造（Windows）」として明記し、他環境は「互換レイヤ」として分離

---

### U-0004: SBOM生成ツールの具体指定
**問題**: MASTERでは「CycloneDX/SPDX」と記載されているが、具体的な生成ツール（syft / cdxgen 等）の推奨は？
**対応**: Part07, Part10で「最小要件: SBOM形式（CycloneDX or SPDX）、ツールは環境依存」として分離

---

### U-0005: Trust Tier / Context Trust Tagging の運用詳細
**問題**: MASTERでは「trust_tier: 0-3」と記載されているが、具体的な昇格/降格ルールは？
**不明点**:
- どのタイミングでtier1→tier2に上げる？（Verify通過時？人間承認時？）
- tier3（証跡付き確定）の条件は？

**対応**: Part06で「Context Trust Tagging」として詳細化が必要

---

### U-0006: Phase 0-4 の導入計画の時間軸
**問題**: MASTERでは Phase 0（最小で回す）～ Phase 4（MCP/統合の完成）を定義しているが、各Phaseの期間・前提条件・完了条件が不明。
**対応**: Part09（Phase導入）で具体化するが、「理想論ではなく運用部品」として明記

---

### U-0007: ローカルLLMの具体的な利用シーン
**問題**: MASTERでは「Ollama / LM Studio / vLLM」を任意としているが、どのタスクで使うべきか不明。
**選択肢**:
- Boilerplate生成（Claude Codeの前処理）
- ログ要約（Z.aiの代替）
- プライベートデータの解析

**対応**: Part03で「衛星ツール」として記載し、具体シーンはPart06で明記

---

### U-0008: "迷いゼロ"の具体的な計測方法
**問題**: F-0023で「迷いゼロ指数」を定義しているが、計測方法（何を観測？何と比較？）が不明。
**対応**: Part01, Part10で「メトリクス」として具体化が必要

---

### U-0009: Context Rot Prevention の具体手順
**問題**: MASTERで「長期スレッドの前提は腐る → SpecとADRへ固定して更新」とあるが、「いつ」「誰が」「どう判断」するか不明。
**対応**: Part06, Part14で「Context劣化防止」として具体化

---

### U-0010: 退避（_TRASH/）の世代管理・復元手順
**問題**: F-0031で「_TRASH/ への退避＋世代管理」とあるが、復元手順・保存期限・容量制限が不明。
**対応**: Part09（Permission Tier）で「破壊操作の代替手段」として具体化

---

## 7) 用語候補（glossary/ への登録推奨）

以下の用語は MASTER で頻出し、定義が必要：
- SSOT
- Verify / Verify Gate / Fast Verify / Full Verify
- Evidence / Evidence Pack
- Release / Immutable Release
- PATCHSET
- DoD (Definition of Done)
- ADR
- Permission Tier / ReadOnly / PatchOnly / ExecLimited / HumanGate
- VIBEKANBAN / INBOX / TRIAGE / SPEC / BUILD / REPAIR / DONE / BLOCKED
- Core4
- SBF (Spec / Build / Fix)
- PAVR (Prepare / Author / Verify / Repair)
- VRループ
- VAULT / TRACE / RUNS
- Focus Pack / Agent Pack / Context Pack
- RAG / Minimum Viable RAG
- Antigravity（IDEハブ）
- worktree
- manifest / sha256
- SBOM / Provenance
- Gitleaks / Trivy / SAST / CodeQL
- MCP (Model Context Protocol)
- Dry-run
- SPIKE
- Spec Freeze
- CHANGELOG
- Rollback / Revert
- Trust Tier / Context Trust Tagging
- RUNLOG.jsonl
- Allowlist
- HumanGate
- WIP制限
- Lane（レーン: ai_ready / pdf_ocr_ready / raw / staging / release）

---

## 8) 追加抽出（2026-01-12 監査/Runbook）

### F-0058: 第2週監査でP0が10件と判定
**定義**: 監査レポートはP0（致命的）10件、P1 8件、P2 5件を指摘している。  
**根拠**: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md
**重要度**: 高（監査対応の優先順位）

### F-0059: HumanGate/証跡/CI/RAG更新がP0原因として指摘
**定義**: HumanGate承認者未定義、証跡命名・保持の矛盾、CI未強制、RAG更新未定義が事故要因として指摘されている。  
**根拠**: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md
**重要度**: 最高（Part09/10/12/14/16で固定が必要）

---

### D-0001: HumanGate承認者とSLAを役割ベースで固定
**決定**: 承認者を「主要/代理/緊急」の役割で定義し、SLAと承認チャネルを固定する。  
**根拠**: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md  
**関連**: decisions/0004-humangate-approvers.md, Part09

### D-0002: Verify証跡の命名と保持ポリシーを統一
**決定**: `YYYYMMDD_HHMMSS_<mode>_<status>_<category>.md` に統一し、直近3セット保持＋アーカイブ移動とする。  
**根拠**: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md  
**関連**: Part10, Part12

### D-0003: CIでVerify Gateを強制
**決定**: main/integrate へのマージはCIのVerify PASSが必須。  
**根拠**: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md  
**関連**: Part14, Part10

### D-0004: RAG更新プロトコルを標準化
**決定**: docs/glossary/decisions 更新時にRAG更新を実施し、`evidence/rag_updates/` にログを残す。  
**根拠**: sources/research_inbox/20260112_125049_2nd_research/10_raw/VCG_VIBE_SSOT_完全設計監査レポート_第2週.md  
**関連**: Part16

---

### U-0011: HumanGate承認者の実名/チームの記入
**問題**: ADR-0004では役割は定義済みだが、実名/チームが未記入。  
**対応**: decisions/0004-humangate-approvers.md に実名/チームを記載。

### U-0012: CIワークフローとBranch Protectionの実装
**問題**: CI強制ルールは定義済みだが、ワークフロー/ルールセットが未実装。  
**対応**: .github/workflows/verify-gate.yml とGitHub Rulesetsで実装。

### U-0013: RAG更新の自動実装
**問題**: RAG更新プロトコルは定義済みだが、自動化スクリプトが未実装。  
**対応**: scripts/ で更新スクリプトを用意し、Evidenceにログを残す。

---

## 参照

- **主要根拠**: [sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md](../sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md)
- **補足資料**: sources/生データ/ 内の他ドキュメント（詳細は sources/_MANIFEST_SOURCES.md で整理予定）
- **関連ADR**: decisions/0001-ssot-governance.md（SSOT運用ガバナンス）

---

**次のアクション**:
1. この FACTS_LEDGER を元に glossary/GLOSSARY.md を実体化
2. Part00-Part20 を順に埋める（根拠は FACTS_LEDGER の F-XXXX を参照）
3. 不明点（U-XXXX）は各Partの「11. 未決事項」に転記
