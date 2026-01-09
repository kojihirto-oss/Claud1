# VCG/VIBE 2026 AI統合運用マスタードキュメント

**版**: 2026-01-09（JST）\
**前提（あなたの課金セット）**: Claude Code Plus / ChatGPT（GPT Plus）/ Google One Pro（= Google AI Pro相当のAI特典を含む想定）/ Z.ai Lite（GLM Coding Plan）\
**重要**: Cursorは使わない。IDEは **Google Antigravity** を中心に回す。

---

## 0.1 いま課金しているAI（あなたの前提セット）

- **Claude Code Plus（Anthropic）**
- **ChatGPT Plus（OpenAI）**
- **Google One Pro（Google / Gemini側の特典を含む想定）**
- **Z.ai Lite（GLM Coding Plan）**

## 0.2 使用ツール／LLM（運用で使うものの一覧）

### IDE / 実行環境

- **Antigravity（IDE：主IDE）**
- **Claude Code（CLI/Agent：BUILD/REPAIRの実働）**
- **ChatGPT（設計凍結・監査・文章化）**
- **Gemini（Deep Research・調査・Google連携）**
- **Z.ai（GLM：高頻度反復／整形／要約／MCP）**

### Google側の衛星（必要に応じて）

- **Gemini CLI**
- **Jules**
- **Code Assist（IDE補助・レビュー等）**

### OpenAI側の衛星（必要に応じて）

- **Codex（Codex CLI / Codex Web など）**

### MCP（AIの“身体”：外部ツール接続）

- Filesystem / Git / Fetch（基礎）
- Web Search / Web Reader / Vision（主にZ.ai側で利用）

### 自動化・CI

- GitHub Actions / CI（Verifyの機械判定）
- AutoClaude等（自動反復。ただし人間承認＋Verify必須）

### ローカルLLM（任意）

- Ollama / LM Studio / vLLM（オフライン・秘匿・コスト削減枠）

### RAG/ナレッジ基盤（任意）

- LangChain / LlamaIndex / Dify / RAGFlow / DSPy など

### 静的解析・セキュリティ（任意）

- Semgrep / Bandit など

---

---

## 0. このドキュメントの目的

VCG/VIBEの「大規模バイブコーディング（大量フォルダ＋RAG＋自動検証＋リリース運用）」を、 **Core4固定（Claude / GPT / Gemini / GLM）＋衛星ツール最大活用**で、 迷いなく・安全に・高速反復で回すための **SSOT（Single Source of Truth）** を1本化する。

狙いは「自分がコードを書く」ではなく、 **AIリソース（推論・調査・実装・検証・整形・証跡化）を運用設計で統率する**こと。

---

## 1. 用語（VCG/VIBE内の共通語彙）

- **Core4**: 4系統のモデル/プラットフォームを固定して役割分担する思想

  - Claude（実装・修理の主戦力）
  - GPT（設計凍結・監査・文章化・最終判定）
  - Gemini（調査・周辺知識・Google連携・エージェント群）
  - GLM（安い手足／整形／ログ要約／MCP外付け検索・抽出）

- **Antigravity（IDE）**: あなたの主IDE（Cursorの代替ではなく、中心）

- **VIBEKANBAN**: チケット駆動の運用台帳（INBOX→TRIAGE→SPEC→BUILD→VERIFY→REPAIR→EVIDENCE→RELEASE）

- **SBF**: 1本の仕事を最後まで通す型

  - S = Spec（PRD/DESIGN/ACCEPTANCEを作って凍結）
  - B = Build（凍結仕様どおり実装を完走）
  - F = Fix（失敗ログから直してGreenに戻す）

- **PAVR**: Bを成功させるための運用ループ

  - P = Prepare（基盤・ルール・真実の順序）
  - A = Author（設計書完成→凍結）
  - V = Verify（機械判定で合否）
  - R = Repair（修正→再検証で収束）

- **SSOT / VAULT / EVIDENCE**:

  - SSOT = 状態を1つに決める（迷いの根源を消す）
  - VAULT = 生成物・ログ・証跡・学び・成果物を固定の場所へ
  - EVIDENCE = 「なぜこうしたか」「何を確認したか」を後から再現できる形で残す

---

## 2. 大原則（これを破ると事故る）

### 2.1 「仕様を凍結してから作る」

- 勢いで作ると、AIが勝手に解釈を増殖させる。
- Spec（PRD/DESIGN/ACCEPTANCE）が **合否判定の唯一の基準**。

### 2.2 「READ-ONLY → PATCHSET → VERIFY」

- エージェントIDEは強力だが、誤操作による破壊が現実に起きる。
- したがって **破壊操作を渡さない**。
- 変更は必ず「最小差分（patchset）」で出し、Verifyで機械判定する。

### 2.3 「削除しない。退避する」

- 標準は `_TRASH/` への退避（rename/move）＋世代管理（timestamp）＋manifest＋sha256。
- dry-run → 人間承認 → 実行 の二段階。

### 2.4 「安い手足で回し、重い推論は最後に使う」

- まずZ.ai（GLM）でキャッシュ照会・整形・ログ要約。
- 期限/差分があるときだけ Google / GPT / Claude へエスカレーション。

---

## 3. 役割分担（課金4本の“最適割当”）

### 3.1 Claude Code Plus（主戦力：BUILD / REPAIR）

**得意**

- 大規模コードベースの多ファイル修正
- 失敗ログからの修理（テスト修復、依存関係の調整、リファクタ）
- コマンド実行・コミット作成・差分提示

**担当**

- BUILD：Spec凍結どおりに「最小パッチ」で完走
- REPAIR：Verify失敗を潰してGreenに戻す

**禁止/注意**

- いきなり全域リライト、破壊コマンド自動実行、Turbo常時ON

---

### 3.2 ChatGPT Plus（監査官：SPEC凍結 / VERIFY判定 / EVIDENCE文章化）

**得意**

- 仕様化（要件→受入基準→テスト方針）
- 監査（矛盾検出、リスク列挙、抜け漏れ指摘）
- 文章化（EVIDENCE、手順書、学びの抽出）
- データ整形・分析（コード実行・表・比較・差分の可視化）

**担当**

- SPEC：PRD/DESIGN/ACCEPTANCE を1枚に統合して凍結
- VERIFY：テスト結果・ログから合否判定（PQ/ECなどの基準）
- EVIDENCE：成果・変更理由・学びをKBとして残す

---

### 3.3 Google One Pro（Gemini側：調査・周辺理解・Google連携・Antigravity IDE）

**得意**

- Deep Research（公式中心の調査、比較、採用案の絞り込み）
- Google系のI/O（Drive/Docs/Sheets/Maps等の周辺資産との統合）
- Jules / Gemini CLI / Code Assist を含む“衛星エージェント群”で並列化

**担当**

- TRIAGE：最新情報の収集・比較・採用案の決定
- 周辺ドキュメント化：設計・仕様の根拠を補強
- Antigravity：IDE中心としてタスク実行（ただしガードレール必須）

---

### 3.4 Z.ai Lite（GLM Coding Plan：安い手足＋MCP外付け検索/抽出）

**得意**

- 高頻度の反復（整形、要約、ログ解析、分割、テンプレ適用）
- MCPサーバ（Web Search / Web Reader / Vision等）で“検索と抽出”を外付け
- 既存コーディングツールへの組み込み（バックエンド差し替え）

**担当**

- キャッシュ照会：まずGLMで「既知の型」に落とす
- ログ要約：Verify失敗を短く整形→修理しやすくする
- EVIDENCE分割：KB用に分割・正規化

---

## 4. 衛星ツール（無料・OSS・ローカルの位置づけ）

### 4.1 自動化/エージェント

- AutoClaude等：反復作業の自動実行（ただし必ず人間承認＋Verify）
- GitHub Actions / CI：Verifyの自動化（合否の機械判定）

### 4.2 ローカルLLM

- 目的：軽作業・プライベート処理・速度・コスト削減
- ランタイム例：Ollama / LM Studio / vLLM

### 4.3 RAG基盤（無料OSS）

- LangChain / LlamaIndex / Dify / RAGFlow / DSPy 等
- 目的：あなたの“永続KB”と「検索→生成→検証」を接続する

### 4.4 静的解析・セキュリティ

- Semgrep / Bandit 等でAI生成コードの安全性を機械判定

---

## 5. 統合アーキテクチャ（Core4＋衛星＋SSOT）

### 5.1 全体像（思想）

- **Core4 = 思考エンジン**
- **衛星 = 実働（IDE/CLI/CI/MCP/RAG/ローカル）**
- **SSOT/VAULT = 証跡と再現性**

### 5.2 データレーン（あなたの方針）

- 本流：`ai_ready/`（正規化されたテキスト・メタデータ・重複排除）
- PDF/画像：`pdf_ocr_ready/`（raw\_pdf, ocr\_text, manifest.jsonl などの別レーン）
- リリース：`generated_*`（immutable / 署名・検証ゲート通過）

---

## 6. VIBEKANBAN（チケットの標準ライフサイクル）

### 6.1 1チケット＝1本の仕事（SBFで完走）

1. **INBOX**

- 入力：思いつき、要望、バグ、改善
- 出力：チケット化（目的/非目的/制約/対象/期限）

2. **TRIAGE（調査）**

- 主担当：Google One Pro（Deep Research）＋必要に応じてZ.ai Web Search/Reader
- 出力：候補比較（採用理由/リスク/代替案/参考リンク）＋採用案1つ

3. **SPEC（凍結）**

- 主担当：GPT Plus
- 出力：PRD / DESIGN / ACCEPTANCE を1枚に統合した `SPEC.md`
  - 受入基準（テスト・検証手順）
  - 非目的（やらないこと）
  - 変更禁止領域

4. **BUILD（実装）**

- 主担当：Claude Code Plus（必要ならZ.aiをバックエンドにして回転数を稼ぐ）
- 出力：最小パッチ（差分）＋追加/更新テスト＋ロールバック手順

5. **VERIFY（機械判定）**

- 主担当：CI/テスト＋GPT Plus（監査・合否判定）
- 出力：Verifyレポート（Green/Red）＋失敗ログ（要約付き）

6. **REPAIR（収束）**

- 主担当：Claude Code Plus
- 入力：失敗ログ（Z.aiで短く整形すると速い）
- 出力：修正パッチ → 再VERIFY

7. **EVIDENCE / KB（証跡化）**

- 主担当：GPT Plus（文章化）＋Z.ai（整形/分割）
- 出力：
  - 何を変えたか（差分）
  - なぜ変えたか（根拠）
  - どう検証したか（手順と結果）
  - 学び（再発防止）

8. **RELEASE（固定化）**

- 出力：immutableリリース（manifest＋sha256＋検証ゲートPASS）

---

## 7. ガードレール（事故を“仕組み”で潰す）

### 7.1 実行環境

- 重要データは **作業用コピー/サンドボックス/コンテナ** でのみ触る
- VAULT/RELEASEは原則READ-ONLY

### 7.2 破壊操作の禁止

- `rmdir /s /q` 等をAIに直接生成・実行させない
- 削除・移動・上書きは二段階（dry-run → 人間承認 → 実行）

### 7.3 “Turbo/自動実行”の扱い

- 原則OFF（許可制）
- Antigravity側も同様に「自動実行＝危険」とみなす

### 7.4 標準退避

- `_TRASH/` へ退避
- timestamp世代管理
- manifest＋sha256

---

## 8. コンテキスト工学（大規模で迷子にさせない）

### 8.1 入力は“最小で強く”

- 対象ファイルは「今回の変更に必要な最小」に絞る
- 仕様（SPEC.md）＋失敗ログ＋関連ファイルのみ

### 8.2 参照の固定

- 仕様の参照先を固定（SSOT）
- どのファイルが真実かを必ず明示

### 8.3 “ログ要約→修理”の分業

- 失敗ログはまずZ.aiで短くする
- Claude Codeには「短いログ＋SPEC＋差分方針」を渡す

---

## 9. コスト/枠（トークンと時間の最適化）

### 9.1 基本方針

- 反復は安いところ（Z.ai）に寄せる
- 重要判断はGPT（監査）に寄せる
- 実装・修理はClaude Code（主戦力）に寄せる
- 調査はGoogle（Deep Research）を使い倒す

### 9.2 キャッシュ戦略

- 同じ質問を何度も重いモデルに投げない
- 「キャッシュ照会→差分があるときだけ再問い合わせ」を標準化

---

## 10. コピペ用：固定プロンプトテンプレ（短く強い“型”）

> ※ここは“あなたの運用フォーマット”に合わせて短くしてある。

### 10.1 TRIAGE（Google One Pro / Gemini）

```
このチケットの実装に必要な最新情報を、公式ドキュメント中心で集めて。
比較表（候補/メリデメ/採用理由/リスク/代替案）を作成し、最後に採用案1つへ絞って。
出力は「次のSPECが書ける」粒度で。
```

### 10.2 SPEC凍結（GPT Plus）

```
TRIAGE結果を根拠に、PRD/DESIGN/ACCEPTANCEを1枚に統合してSPEC.mdを作って。
必須: 目的/非目的/制約/受入基準/Verify手順/リスク/ロールバック。
曖昧表現は禁止。Verifyで合否判定できる形に。
```

### 10.3 BUILD（Claude Code Plus）

```
入力: SPEC.md + 関連ファイル最小 + 制約。
出力: 最小パッチ差分 / 影響範囲 / 追加・更新テスト / ロールバック手順。
禁止: 全域リライト。破壊操作。自動実行。
```

### 10.4 VERIFY（CI + GPT Plus）

```
このテスト結果とログを読み、SPEC.mdの受入基準に照らして合否判定して。
失敗がある場合は「最短の修理方針」と「再発防止の観点」を箇条書きで。
```

### 10.5 REPAIR（Claude Code Plus）

```
入力: SPEC.md + 失敗ログ要約 + 現在の差分。
最小修正でGreenへ。修正後にVerify手順を再実行し、結果を報告。
```

### 10.6 EVIDENCE（GPT Plus + Z.ai）

```
このチケットの成果をEVIDENCEとして残す。
(1) 何を変えたか (2) なぜ変えたか (3) どう検証したか (4) 学び/再発防止
KB登録しやすいように見出し付きで分割。
```

---

## 11. 1チケット実行例（完全に通す）

**例**: 「大量フォルダから必要情報を抽出し、RAG用に正規化してVAULTへ格納する」

1. INBOX：やりたいことを一文で
2. TRIAGE：

- 公式手法/OSS候補を比較
- 既存フォルダ構造（ai\_ready / pdf\_ocr\_ready / manifest）と整合

3. SPEC：

- 入力/出力/フォルダ命名/重複除去/検証ゲート（sha256, 件数, FTS等）

4. BUILD：

- まず最小サンプルで通す
- その後バッチ化

5. VERIFY：

- 件数一致、重複率、失敗ファイル一覧、再現性

6. REPAIR：

- 失敗だけを再処理

7. EVIDENCE：

- 失敗→原因→対策→検証結果

8. RELEASE：

- immutable化して次工程へ

---

## 12. “Cursor不使用”前提での置き換え表

- Cursor（不使用）で担っていた「IDE内補完・チャット・リファク」
  - → **Antigravity（IDE）** を中心に担う
- Cursor関連の補助（Continueなど）
  - → Antigravity中心でも「外付けで使う価値がある」ものだけ採用

---

## 13. 最終目的（あなたの“永続KB”構築と整合）

あなたの最終皇帝プロジェクト（永遠に劣化しない完全個人知識ベース）に対し、 この運用は次を保証する：

- 生成物が **再現可能**（Evidence + Verify + Release）
- 事故りにくい（ガードレール）
- 反復が速い（安い手足→重い推論の順）
- 将来のAIへ移植しやすい（SSOT / manifest / sha256 / レーン分離）

---

## 14. 次にやること（最短で運用へ落とす）

1. VIBEKANBANの「チケット雛形」を固定
2. SPEC.mdテンプレを固定
3. Verify（機械判定）を1本に固定（run\_verify相当）
4. VAULTに EVIDENCE / LOGS / RELEASE の置き場を固定
5. Antigravityのガードレール（READ-ONLY→PATCHSET→VERIFY）を運用ルールとして“強制”

以上。

