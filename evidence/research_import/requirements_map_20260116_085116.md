# 要件マッピングレポート（研究インポート）
**生成日時**: 2026-01-16 08:51:16
**対象ファイル**:
- `_imports\最終調査_20260115_020600\必ず入れたい.md`
- `_imports\最終調査_20260115_020600\_kb\2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md`

---

## 要件一覧（REQ-ID付き）

### カテゴリA: 自動化・ワークフロー基盤

#### REQ-0001: CLIラッパー実装
- **要件**: PowerShellスクリプトの手動実行を隠蔽し、1コマンドで実行できるCLIラッパーを提供する
- **背景**: 現状の `pwsh .\checks\verify_repo.ps1` などの手動実行は入力ミスや億劫さを生み、Vibe（リズム）を崩す原因となる
- **反映先候補**:
  - `docs/Part10.md` (Tools / Build / Verify の実行手順)
  - `docs/Part13.md` (Verify / Evidence / Release の自動化)
  - 新規ADR: `decisions/XXXX-cli-wrapper-implementation.md`
- **受け入れ基準**:
  - [ ] CLIラッパーのコマンド仕様が定義されている（例: `vibe verify`, `vibe build`）
  - [ ] PowerShellスクリプトとの対応が明確である
  - [ ] エラーハンドリングとログ出力が定義されている
  - [ ] HumanGate が必要な操作は明示的に承認プロンプトを出す

---

#### REQ-0002: Watcher Script（ファイル保存時の自動Verify）
- **要件**: ファイル保存時に自動的に Verify を実行するスクリプトを提供する
- **背景**: 手動でのVerify実行忘れを防ぎ、即座にフィードバックを得ることでVibe（リズム）を維持する
- **反映先候補**:
  - `docs/Part13.md` (Verify の自動トリガー)
  - `docs/Part10.md` (開発環境の設定)
  - 新規ADR: `decisions/XXXX-auto-verify-watcher.md`
- **受け入れ基準**:
  - [ ] 監視対象ディレクトリ・ファイルパターンが定義されている
  - [ ] Verify失敗時の通知方法が定義されている
  - [ ] VRループカウンターとの連携仕様が定義されている
  - [ ] パフォーマンス影響（大規模リポジトリでの挙動）が評価されている

---

#### REQ-0003: VRループ可視化（ゲーム化）
- **要件**: エラー修正ループ（VRループ）を「残機」のように可視化し、3回制限を明示する
- **背景**: 設計書の「R-1101: VRループ3回制限」をゲームの「残機」のように扱い、ダラダラとした試行錯誤を防ぐ
- **反映先候補**:
  - `docs/Part11.md` または該当するVRループルールの記載箇所
  - `docs/Part13.md` (Verify のフィードバックUI)
  - 新規ADR: `decisions/XXXX-vr-loop-visualization.md`
- **受け入れ基準**:
  - [ ] VRループカウンターの実装方法が定義されている（IDE拡張 / CLI表示 / Status Bar）
  - [ ] 3回到達時のHumanGate発動ルールが明確である
  - [ ] カウンターのリセット条件が定義されている（タスク完了時など）
  - [ ] 視覚的なフィードバック形式が定義されている

---

#### REQ-0004: Status Bar（モード表示・VRループ残機表示）
- **要件**: 「現在のモード（設計 or 実装）」と「VRループ残機」を表示するIDE拡張またはCLI表示を提供する
- **背景**: Core4の役割固定（ChatGPT=設計、Claude=実装）を視覚的に強制し、現在の状態を常に把握する
- **反映先候補**:
  - `docs/Part10.md` (Tools / IDE設定)
  - `docs/Part07.md` または該当するCore4役割分担の記載箇所
  - 新規ADR: `decisions/XXXX-status-bar-ui.md`
- **受け入れ基準**:
  - [ ] 表示内容が定義されている（モード、VRループ残機、現在のタスクID等）
  - [ ] 更新タイミングが定義されている
  - [ ] IDE拡張とCLI表示の両方の仕様が定義されている
  - [ ] Core4の役割切り替えとの連携が定義されている

---

### カテゴリB: Context Pack / MCP / 動的コンテキスト生成

#### REQ-0005: Context Pack動的生成（MCP Server）
- **要件**: タスクに必要な最小コンテキスト（Focus Pack）を自動生成するMCP Serverを実装する
- **背景**: 「今このタスク（TICKET-001）をやっている」と指定すると、関連するSPEC、FACTS_LEDGER、過去のEvidenceだけを自動でAIのコンテキストに流し込む
- **反映先候補**:
  - `docs/Part05.md` または該当するContext Packの記載箇所
  - `docs/Part10.md` (Tools / MCP Server)
  - 既存のMCP関連ADR（F-0011など）を更新
  - 新規ADR: `decisions/XXXX-context-pack-automation.md`
- **受け入れ基準**:
  - [ ] MCP Serverのインターフェース仕様が定義されている
  - [ ] タスクIDからコンテキストを抽出するロジックが定義されている
  - [ ] 無関係なファイルを除外するフィルタリングルールが定義されている
  - [ ] AIが「以前の話」や「無関係なファイル」に引きずられないことがVerifyで確認されている

---

#### REQ-0006: Context Builder（Focus Pack自動生成ツール）
- **要件**: 作業中のタスクに合わせてFocus Packを自動生成するプロンプトツールを提供する
- **背景**: REQ-0005のMCP実装を補完し、IDEやCLIから直接Focus Packを生成できるようにする
- **反映先候補**:
  - `docs/Part05.md` または該当するContext Packの記載箇所
  - `docs/Part10.md` (Tools)
  - 新規ADR: `decisions/XXXX-context-builder-tool.md`
- **受け入れ基準**:
  - [ ] ツールのコマンド仕様が定義されている（例: `vibe context build TICKET-001`）
  - [ ] 生成されるFocus Packの形式が定義されている
  - [ ] REQ-0005のMCP Serverとの役割分担が明確である
  - [ ] 生成されたFocus Packの品質がVerifyで確認されている

---

### カテゴリC: Core4役割分担・AI割当

#### REQ-0007: Core4役割分担のIDE統合
- **要件**: ChatGPT（設計）とClaude（実装）の使い分けをブラウザのタブ切り替えなしで行えるようにする
- **背景**: 設計書の「R-0301: Core4の役割固定」を強制力のあるUIにし、「どっちに聞こう？」という迷いを消す
- **反映先候補**:
  - `docs/Part07.md` または該当するCore4の記載箇所
  - `docs/Part10.md` (Tools / IDE設定)
  - 新規ADR: `decisions/XXXX-core4-ide-integration.md`
- **受け入れ基準**:
  - [ ] AI役割切り替えランチャーの仕様が定義されている
  - [ ] ワンクリックで送信先を変えられるプリセットが定義されている
  - [ ] Core4の役割（設計/実装/レビュー等）と送信先AIの対応が明確である
  - [ ] Status Bar（REQ-0004）との連携が定義されている

---

#### REQ-0008: 工程別AI割当の明確化（Spec/Research/Design/Build/Fix/Verify/Release）
- **要件**: 各工程に「主担当（高精度）／副担当（クロスチェック）／軽量（節約）／フォールバック（制限時）」を固定する
- **背景**: 最高精度×制限耐性を実現するため、各工程のAI割当を明確化し、迷いを排除する
- **反映先候補**:
  - `docs/Part07.md` または該当するAI役割分担の記載箇所
  - `docs/Part08.md` または該当する工程定義の記載箇所
  - 新規ADR: `decisions/XXXX-process-ai-assignment.md`
- **受け入れ基準**:
  - [ ] 各工程（Spec/Research/Design/Build/Fix/Verify/Release）のAI割当が明確である
  - [ ] 主担当・副担当・軽量・フォールバックの4層が定義されている
  - [ ] 成果物のフォーマット（PRD/ADR/API契約等）が定義されている
  - [ ] LiteLLM（REQ-0012）との連携が定義されている

---

#### REQ-0009: 4つの主力サービスの明確化
- **要件**: ChatGPT Plus（OpenAI）、Claude（Plus/+プラン）、Google One Pro（Gemini）、Z.ai コーディングプラン（ライト）を主力として固定する
- **背景**: 課金済みの主力サービスを明確化し、最大効率で回す前提を設計書に反映する
- **反映先候補**:
  - `docs/Part07.md` または該当するAI Servicesの記載箇所
  - `docs/Part10.md` (Tools / 環境設定)
  - 新規ADR: `decisions/XXXX-primary-ai-services.md`
- **受け入れ基準**:
  - [ ] 4つの主力サービスの役割が明確である
  - [ ] 各サービスの利用上限・予算が定義されている
  - [ ] フォールバック戦略（REQ-0016）との連携が定義されている
  - [ ] コスト最適化（REQ-0018）との連携が定義されている

---

### カテゴリD: リファクタリング・技術的負債管理

#### REQ-0010: リファクタリング・技術的負債管理の明確化
- **要件**: AIによる「継ぎ足し建築」のような汚いコード（スパゲッティコード）を防ぐための具体的な工程を定義する
- **背景**: AIは動くコードを書くのは得意だが、放っておくと技術的負債が蓄積する。DESIGN_MASTERの規律を守らせる
- **反映先候補**:
  - `docs/Part09.md` または該当するMaintenance/Refactoringの記載箇所
  - `docs/Part13.md` (Verify / コード品質ゲート)
  - 新規ADR: `decisions/XXXX-refactoring-governance.md`
- **受け入れ基準**:
  - [ ] リファクタリングの実施タイミングが定義されている
  - [ ] 技術的負債の検出方法が定義されている（静的解析、複雑度計測等）
  - [ ] リファクタリングのDoD（Definition of Done）が定義されている
  - [ ] Verifyでコード品質が保証されている

---

### カテゴリE: 回帰防止・品質ゲート

#### REQ-0011: promptfoo導入（LLM回帰テスト/品質ゲート）
- **要件**: LLMの品質をCIでテストし、閾値を割ると落とす仕組みを導入する
- **背景**: 回帰防止（Quality Gate）が最高精度の核となる。「前はできたのに今回は壊れた」をCI/自動評価で検知して止める
- **反映先候補**:
  - `docs/Part13.md` (Verify / 品質ゲート)
  - `docs/Part14.md` または該当するCI/CDの記載箇所
  - 新規ADR: `decisions/XXXX-promptfoo-integration.md`
- **受け入れ基準**:
  - [ ] promptfooの評価セット（テストケース）が定義されている
  - [ ] 各工程（Spec/Design/Build/Review）の評価基準が定義されている
  - [ ] CI/CDパイプラインへの統合方法が定義されている
  - [ ] 回帰テストの実行頻度・トリガーが定義されている

---

### カテゴリF: 制限耐性・フォールバック

#### REQ-0012: LiteLLM導入（Gateway/Router/予算/レート/フォールバック）
- **要件**: 予算・レート制限・障害時の自動迂回を仕組み化するLiteLLMを導入する
- **背景**: 制限耐性が「運用の勝ち筋」となる。上限・混雑・障害が来ても作業が止まらず、最適な代替に自動迂回する
- **反映先候補**:
  - `docs/Part10.md` (Tools / LiteLLM)
  - `docs/Part07.md` または該当するAI Servicesの記載箇所
  - 新規ADR: `decisions/XXXX-litellm-integration.md`
- **受け入れ基準**:
  - [ ] LiteLLMのルーティング設定（用途別・工程別）が定義されている
  - [ ] 予算上限の設定方法が定義されている
  - [ ] フォールバック順序が定義されている（高精度→軽量→ローカル）
  - [ ] レート制限・障害時の自動迂回が動作することがVerifyで確認されている

---

#### REQ-0013: Antigravity（コックピット）の役割明確化
- **要件**: Antigravityを「司令塔・レビュー・確認」に役割を寄せる（最終意思決定・差分評価・DoD判定）
- **背景**: コックピット（常用）として固定し、エージェントの暴走を「承認＋ゲート＋証跡」で抑える
- **反映先候補**:
  - `docs/Part07.md` または該当するCore4/Toolsの記載箇所
  - `docs/Part10.md` (Tools / Antigravity)
  - 新規ADR: `decisions/XXXX-antigravity-role.md`
- **受け入れ基準**:
  - [ ] Antigravityの役割が明確である（司令塔・レビュー・確認）
  - [ ] 他のツール（Aider、Cline等）との役割分担が明確である
  - [ ] HumanGateとの連携が定義されている
  - [ ] DoD判定の基準が定義されている

---

#### REQ-0014: VibeKanban導入（タスク管理・WIP制限・DoD・証跡リンク）
- **要件**: タスク分解/状態遷移/WIP制限/並列運用の交通整理/証跡リンクの「台帳」としてVibeKanbanを導入する
- **背景**: 再現性（工程を回す仕組み）を確保し、大規模で破綻しない運用を実現する
- **反映先候補**:
  - `docs/Part06.md` または該当するWorkflow/Kanbanの記載箇所
  - `docs/Part08.md` または該当する工程管理の記載箇所
  - 新規ADR: `decisions/XXXX-vibekanban-integration.md`
- **受け入れ基準**:
  - [ ] レーン構成（Spec→Research→Design→Build→Fix→Verify→Release→Operate）が定義されている
  - [ ] 各レーンのWIP制限が定義されている
  - [ ] 各レーンのDoD（完了条件）が定義されている
  - [ ] 証跡リンク（タスクと成果物の紐付け）の仕様が定義されている

---

#### REQ-0015: VS Code + Cline導入（HITL自動化）
- **要件**: ファイル変更とコマンド実行を「承認つき」で自動化するVS Code + Clineを導入する
- **背景**: IDE自動化（反復作業/周辺作業の自動化）を実現し、Vibeを維持する
- **反映先候補**:
  - `docs/Part10.md` (Tools / VS Code / Cline)
  - `docs/Part09.md` または該当するPermission Tierの記載箇所
  - 新規ADR: `decisions/XXXX-cline-integration.md`
- **受け入れ基準**:
  - [ ] Clineの承認フロー（HumanGate）が定義されている
  - [ ] Aider、Continue等との役割分担が明確である
  - [ ] 自動実行可能な操作と承認必須の操作が明確である
  - [ ] VS Code未導入のため、導入手順が定義されている

---

#### REQ-0016: Aider導入（大規模改造の火力）
- **要件**: 大規模改造・差分積み上げ・テスト駆動での改修に強いAiderを導入する
- **背景**: Build工程（D-1: 大規模改造）の火力枠として、中途半端に分散させずに集中して使う
- **反映先候補**:
  - `docs/Part10.md` (Tools / Aider)
  - `docs/Part08.md` または該当するBuild工程の記載箇所
  - 新規ADR: `decisions/XXXX-aider-integration.md`
- **受け入れ基準**:
  - [ ] Aiderの利用シーン（大規模改造）が定義されている
  - [ ] 主担当AI（Codex）との連携が定義されている
  - [ ] Verifyとの連携（変更後の自動テスト）が定義されている
  - [ ] 差分積み上げの運用ルールが定義されている

---

#### REQ-0017: Continue導入（統一I/F）
- **要件**: IDE/CLI/CIを同じ「流儀（プロンプト・ルール・コンテキスト）」で揃えるContinueを導入する
- **背景**: 「誰がやっても同じ品質」＝再現性を実現する
- **反映先候補**:
  - `docs/Part10.md` (Tools / Continue)
  - `docs/Part05.md` または該当するプロンプト規約の記載箇所
  - 新規ADR: `decisions/XXXX-continue-integration.md`
- **受け入れ基準**:
  - [ ] Continueで統一する「流儀」が定義されている（プロンプト規約、作業手順、コンテキスト投入、ログ）
  - [ ] IDE/CLI/CIでの利用方法が定義されている
  - [ ] Aider、Cline等との役割分担が明確である
  - [ ] 共通ルールがVerifyで確認されている

---

#### REQ-0018: フォールバック戦略（ローカルLLM - Ollama/LM Studio/Tabby）
- **要件**: 制限時・深夜・ネット不調・閉域案件で効くローカルLLM実行環境を整備する
- **背景**: 「止まらない」と「機密を外に出さない」が価値。制限で止まるのが一番痛い
- **反映先候補**:
  - `docs/Part10.md` (Tools / ローカルLLM)
  - `docs/Part07.md` または該当するフォールバック戦略の記載箇所
  - 新規ADR: `decisions/XXXX-local-llm-fallback.md`
- **受け入れ基準**:
  - [ ] ローカルLLMの選定基準（Ollama/LM Studio/Tabby）が定義されている
  - [ ] フォールバック順序（主力→軽量→ローカル）が定義されている
  - [ ] セルフホストのコーディング補完（Tabby）の利用シーンが定義されている
  - [ ] 閉域案件での運用ルールが定義されている

---

#### REQ-0019: 低コストルーティング（OpenRouter/Groq/無料枠CLI）
- **要件**: 無料枠や低コストプロバイダへ動的に逃がす設計を導入する
- **背景**: 特定の無料条件を固定せず、LiteLLM / aichat / llm 経由で「その時点で使える低コスト枠」に動的に逃がす
- **反映先候補**:
  - `docs/Part10.md` (Tools / LiteLLM / aichat / llm)
  - `docs/Part07.md` または該当するコスト最適化の記載箇所
  - 新規ADR: `decisions/XXXX-low-cost-routing.md`
- **受け入れ基準**:
  - [ ] aichat、llm（simonw/llm）の導入手順が定義されている
  - [ ] OpenRouter/Groqへのルーティング設定が定義されている
  - [ ] 無料枠の動的管理方法が定義されている
  - [ ] LiteLLM（REQ-0012）との連携が定義されている

---

### カテゴリG: 可観測性・トレース・改善ループ

#### REQ-0020: Langfuse導入（トレース/評価/コスト/改善ループ）
- **要件**: トレース/評価/失敗分析/改善ループを実現するLangfuseを導入する
- **背景**: 可観測性（Observability）が「壊れた場所を一撃で特定」する核となる
- **反映先候補**:
  - `docs/Part10.md` (Tools / Langfuse)
  - `docs/Part13.md` (Verify / Evidence / トレース)
  - 新規ADR: `decisions/XXXX-langfuse-integration.md`
- **受け入れ基準**:
  - [ ] トレースに記録する内容が定義されている（モデル、プロンプト、コンテキスト、コスト、遅延、エラー）
  - [ ] タスクIDとEvidenceの紐付け方法が定義されている
  - [ ] 失敗分析と改善ループの運用方法が定義されている
  - [ ] promptfoo（REQ-0011）との連携が定義されている

---

### カテゴリH: セキュリティ・ガバナンス・Policy-as-Code

#### REQ-0021: セキュリティ自動検知（Gitleaks/Trivy/OpenSSF Scorecard）
- **要件**: 事故系の自動検知を無料で強い守りとして導入する
- **背景**: 無料/低コストで強い領域。入れるほど「精度の下振れ」が消える
- **反映先候補**:
  - `docs/Part13.md` (Verify / セキュリティゲート)
  - `docs/Part14.md` または該当するCI/CDの記載箇所
  - 新規ADR: `decisions/XXXX-security-auto-detection.md`
- **受け入れ基準**:
  - [ ] Gitleaks（Secrets検出）の導入手順が定義されている
  - [ ] Trivy（脆弱性/SBOM/依存関係）の導入手順が定義されている
  - [ ] OpenSSF Scorecard（リポジトリ健全性）の導入手順が定義されている
  - [ ] CI/CDパイプラインへの統合方法が定義されている

---

#### REQ-0022: Conftest/OPA導入（Policy-as-Code）
- **要件**: 危険コマンドや設定逸脱を機械で拒否するPolicy-as-Codeを導入する
- **背景**: 任意だが、設計書の禁止事項リスト（R-0002等）を機械的に強制できる
- **反映先候補**:
  - `docs/Part13.md` (Verify / ポリシーゲート)
  - `docs/Part00.md` または該当する禁止事項の記載箇所
  - 新規ADR: `decisions/XXXX-policy-as-code.md`
- **受け入れ基準**:
  - [ ] Conftest/OPAの導入手順が定義されている
  - [ ] 禁止事項リスト（危険コマンド、設定逸脱）のポリシー定義が明確である
  - [ ] CI/CDパイプラインへの統合方法が定義されている
  - [ ] 既存のVerifyスクリプトとの役割分担が明確である

---

#### REQ-0023: GitHub Artifact Attestations導入（ビルド来歴の証明）
- **要件**: ビルド証跡の強化として、GitHub Artifact Attestationsを導入する
- **背景**: 任意だが、Evidenceの信頼性を高め、供給網（サプライチェーン）の安全性を証明できる
- **反映先候補**:
  - `docs/Part13.md` (Evidence / ビルド来歴)
  - `docs/Part14.md` または該当するRelease工程の記載箇所
  - 新規ADR: `decisions/XXXX-artifact-attestations.md`
- **受け入れ基準**:
  - [ ] Artifact Attestationsの導入手順が定義されている
  - [ ] ビルド来歴の記録内容が定義されている
  - [ ] Releaseワークフローへの統合方法が定義されている
  - [ ] Evidenceフォルダとの連携が定義されている

---

### カテゴリI: 大規模運用・worktree分離

#### REQ-0024: 1タスク=1隔離（worktree分離）
- **要件**: 1 TICKET = 1 worktree = 1 branch = 1 Verify = 1 Evidence Packの原則を明確化する
- **背景**: 並列作業しても衝突しにくい（大規模の必須条件）
- **反映先候補**:
  - `docs/Part06.md` または該当するWorktreeの記載箇所
  - `docs/Part08.md` または該当する並列運用の記載箇所
  - 新規ADR: `decisions/XXXX-worktree-isolation.md`
- **受け入れ基準**:
  - [ ] worktree作成・削除の手順が定義されている
  - [ ] タスクIDとworktreeの命名規則が定義されている
  - [ ] Verifyとの連携（各worktreeでの独立実行）が定義されている
  - [ ] Evidence Packの生成・保存方法が定義されている

---

### カテゴリJ: モデル選定・評価

#### REQ-0025: モデル選定手順（リーダーボード + 自分の回帰テスト）
- **要件**: 外部ランキングで候補プールを作り、promptfooで自分のコードベースでの勝敗を決める手順を定義する
- **背景**: 外部の流行に振り回されず、あなたの環境で「本当に強い」割当を固める
- **反映先候補**:
  - `docs/Part07.md` または該当するAI選定の記載箇所
  - `docs/Part13.md` (Verify / promptfoo)
  - 新規ADR: `decisions/XXXX-model-selection-process.md`
- **受け入れ基準**:
  - [ ] 外部ランキング（Artificial Analysis / LLM Stats / LM Arena / Scale系 / HF Open LLM）の参照方法が定義されている
  - [ ] 代表タスクを「評価セット」にする手順が定義されている
  - [ ] promptfooでの回帰試験手順が定義されている
  - [ ] 勝ったモデルを工程に割当する基準が定義されている

---

### カテゴリK: コスト最適化

#### REQ-0026: コスト最適化（工程別の精度レベル固定）
- **要件**: 高精度を使う工程と軽量に落としてよい工程を固定し、「迷いを消す」ことで再現性を高める
- **背景**: 経済モードを工程に組み込み、精度を落とさず制限も超えにくくする
- **反映先候補**:
  - `docs/Part07.md` または該当するAI割当の記載箇所
  - `docs/Part08.md` または該当する工程定義の記載箇所
  - 新規ADR: `decisions/XXXX-cost-optimization-strategy.md`
- **受け入れ基準**:
  - [ ] 高精度を使う工程（Spec/Hard Design/Review）が明確である
  - [ ] 軽量に落としてよい工程（整形、候補列挙、コメント、ドキュメント体裁）が明確である
  - [ ] 大規模実装の火力枠（Aider/Codex）への集中ルールが定義されている
  - [ ] LiteLLMでの予算管理（工程タグ別、モデル別）が定義されている

---

## 設計上の判断ポイント（衝突・課題・要議論）

### 判断ポイント1: ツール乱立の整理
**問題**: promptfoo、LiteLLM、Langfuse、VibeKanban、Aider、Cline、Continue、aichat、llm等、多数のツールが提案されている。全て導入すると運用負荷が高く、Vibe（リズム）を損なう可能性がある。

**選択肢**:
1. **最小セット優先**: promptfoo、LiteLLM、Langfuse、VibeKanbanの4つを最優先で導入し、他は段階的に追加
2. **段階的導入**: Phase 1（基盤）→ Phase 2（自動化）→ Phase 3（最適化）で分ける
3. **既存ツールとの統合**: 既存のVerifyスクリプトやCLAUDE.mdのルールとの統合を優先

**推奨**: 選択肢2（段階的導入）+ 選択肢3（既存ツールとの統合）
- Phase 1: promptfoo（REQ-0011）、LiteLLM（REQ-0012）、Langfuse（REQ-0020）
- Phase 2: VibeKanban（REQ-0014）、Aider（REQ-0016）、Continue（REQ-0017）
- Phase 3: Cline（REQ-0015）、aichat/llm（REQ-0019）、ローカルLLM（REQ-0018）

**反映先**: 新規ADR: `decisions/XXXX-tool-adoption-roadmap.md`

---

### 判断ポイント2: VS Code未導入との整合性
**問題**: 設計書では「VS Code（追加予定）」とあるが、現在は未導入。Cline（REQ-0015）、Status Bar（REQ-0004）等のVS Code依存機能をどう扱うか。

**選択肢**:
1. **VS Code導入を前提**とし、導入手順を設計書に追加
2. **既存IDE（Antigravity等）での代替**を検討し、VS Code依存を減らす
3. **CLI版の実装**を優先し、IDE拡張は後回し

**推奨**: 選択肢1（VS Code導入を前提）+ 選択肢3（CLI版の実装を優先）
- VS Code導入手順を `docs/Part10.md` に追加
- Status Bar、Watcher Script等はまずCLI版で実装し、後にIDE拡張化

**反映先**:
- `docs/Part10.md` (Tools / VS Code導入手順)
- 新規ADR: `decisions/XXXX-vscode-adoption.md`

---

### 判断ポイント3: VibeKanbanの実装形態
**問題**: VibeKanban（REQ-0014）は「司令塔」として重要だが、具体的な実装形態（GitHub Projects / Trello / 独自ツール）が不明。

**選択肢**:
1. **GitHub Projects**を使い、既存のGitワークフローと統合
2. **独自のマークダウンベースKanban**（`kanban/` フォルダ等）を構築
3. **Trello / Notion等の外部ツール**を利用

**推奨**: 選択肢1（GitHub Projects）+ 選択肢2（マークダウンベースのバックアップ）
- GitHub Projectsでレーン/WIP制限/DoD/証跡リンクを管理
- `kanban/` フォルダにマークダウン形式でバックアップ（SSOT原則に従う）

**反映先**:
- `docs/Part06.md` または該当するKanbanの記載箇所
- 新規ADR: `decisions/XXXX-vibekanban-implementation.md`

---

### 判断ポイント4: Core4の役割と新規ツールの整合性
**問題**: 設計書に「Core4の役割固定（R-0301）」があるが、2026_01_版では「工程別AI割当」で異なる割当が提案されている。どちらを優先するか。

**選択肢**:
1. **Core4を優先**し、新規AI割当を既存のCore4に統合
2. **工程別AI割当を優先**し、Core4を拡張または再定義
3. **両方を併存**させ、用途で使い分ける

**推奨**: 選択肢2（工程別AI割当を優先）
- Core4の役割（ChatGPT=設計、Claude=実装等）を維持しつつ、工程別の詳細割当を追加
- 「R-0301: Core4の役割固定」を「R-0301: AI役割の工程別割当」に拡張

**反映先**:
- `docs/Part07.md` または該当するCore4の記載箇所を更新
- 新規ADR: `decisions/XXXX-core4-extension.md`

---

### 判断ポイント5: MCP Server（REQ-0005）の実装優先度
**問題**: Context Pack動的生成（MCP Server）は高度な機能だが、実装コストも高い。既存のF-0011（MCP導入方針）との整合性も要確認。

**選択肢**:
1. **最優先で実装**し、Context Packの自動化を実現
2. **段階的実装**：まず手動のContext Builder（REQ-0006）を実装し、後にMCP化
3. **既存のMCP方針（F-0011）を先に具体化**し、その上でContext Pack機能を追加

**推奨**: 選択肢2（段階的実装）+ 選択肢3（既存MCP方針の具体化）
- Phase 1: 手動のContext Builder（REQ-0006）を実装
- Phase 2: F-0011のMCP導入方針を具体化
- Phase 3: MCP ServerとしてContext Pack自動生成を実装

**反映先**:
- `docs/Part05.md` または該当するContext Packの記載箇所
- `docs/Part10.md` (Tools / MCP Server)
- 既存のF-0011関連ADRを更新

---

### 判断ポイント6: promptfoo評価セットの作成コスト
**問題**: promptfoo（REQ-0011）は強力だが、評価セット（数十〜数百ケース）の作成コストが高い。既存のVerifyスクリプトとの統合も要検討。

**選択肢**:
1. **promptfooを全面導入**し、既存Verifyスクリプトを置き換える
2. **既存Verifyスクリプトを維持**し、promptfooは重要工程のみに限定
3. **promptfooと既存Verifyを併用**し、役割分担を明確化

**推奨**: 選択肢3（併用・役割分担）
- promptfoo: LLM出力の品質・回帰テスト（Spec/Design/Build等）
- 既存Verify: リポジトリ構造・リンク・禁止パターン・sources整合性

**反映先**:
- `docs/Part13.md` (Verify / promptfooと既存Verifyの役割分担)
- 新規ADR: `decisions/XXXX-verify-dual-track.md`

---

### 判断ポイント7: ローカルLLMの運用負荷
**問題**: ローカルLLM（Ollama/LM Studio/Tabby）は「止まらない」価値があるが、セットアップ・メンテナンスコストが高い。

**選択肢**:
1. **最初から導入**し、フォールバック体制を万全にする
2. **必要になってから導入**（制限に遭遇した時点で検討）
3. **Tabbyのみ先行導入**（コーディング補完に限定）

**推奨**: 選択肢2（必要になってから導入）+ 選択肢3（Tabbyのみ先行）
- Tabbyをセルフホストのコーディング補完として先行導入
- Ollama/LM Studioは制限時の最終フォールバックとして手順のみ準備

**反映先**:
- `docs/Part10.md` (Tools / ローカルLLM導入手順)
- 新規ADR: `decisions/XXXX-local-llm-adoption-strategy.md`

---

### 判断ポイント8: 設計書のPart構造への影響
**問題**: 26件の要件（REQ-0001 〜 REQ-0026）を既存のPart00-Part20に反映すると、大幅な構造変更が必要になる可能性がある。

**選択肢**:
1. **既存Part構造を維持**し、各Partに要件を分散して追記
2. **新規Part（Part21等）を追加**し、新規ツール群を集約
3. **Part構造を再編**し、工程別（Spec/Design/Build/Verify等）に整理

**推奨**: 選択肢1（既存Part構造を維持）
- 既存Partの該当箇所に追記し、Part00の「真実の優先順位」を維持
- Part10（Tools）を拡充し、新規ツール群を集約
- 必要に応じてPart構造の再編をADRで提案

**反映先**:
- 新規ADR: `decisions/XXXX-part-structure-evolution.md`

---

## 次のアクション（推奨）

1. **ADR作成**: 上記の判断ポイント1-8について、ADRを作成し設計判断を記録する
2. **Phase 1実装**: promptfoo（REQ-0011）、LiteLLM（REQ-0012）、Langfuse（REQ-0020）の導入手順を設計書に反映
3. **既存Partの更新**: 各REQを該当するPartに反映（Part00、Part05、Part07、Part08、Part10、Part13等）
4. **Verify拡張**: promptfooと既存Verifyの役割分担を明確化し、`checks/` に追加
5. **ツール導入ロードマップ**: Phase 1-3の段階的導入計画をADRとして記録

---

## メタデータ

- **要件総数**: 26件（REQ-0001 〜 REQ-0026）
- **カテゴリ数**: 11カテゴリ（A-K）
- **判断ポイント数**: 8件
- **主な反映先Part**: Part00, Part05, Part06, Part07, Part08, Part09, Part10, Part11, Part13, Part14
- **新規ADR候補数**: 約25件（各REQに対応）

---

## 受け入れ基準（このレポート自体）

- [x] 両方のファイルを読み取り、要件を抽出した
- [x] 各要件にREQ-IDを付与した
- [x] 各要件の反映先候補（Part/ADR）を明記した
- [x] 各要件の受け入れ基準を定義した
- [x] 設計上の判断ポイントを抽出した
- [x] タイムスタンプ付きでレポートを生成した
- [x] evidence/research_import/ フォルダに保存した
