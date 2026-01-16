# Part 29：IDE統合設計（Core4役割分担・Watcher・Status Bar）

## 0. このPartの位置づけ
- **目的**: Core4の役割分担をIDEに統合し、ブラウザタブ切り替えなしでAIを使い分けられる仕組みを定義する
- **依存**: [Part03](Part03.md)（AI Pack）、[Part21](Part21.md)（工程別AI割当）、[Part28](Part28.md)（MCP連携）
- **影響**: 全AI使用工程・開発体験・作業効率

---

## 1. 目的（Purpose）

本 Part29 は **IDE統合によるAI役割切り替えの自動化** を通じて、以下を保証する：

1. **ワンクリック切り替え**: 「これは設計（ChatGPT）」「これは実装（Claude）」をワンクリックで切り替え
2. **状態可視化**: 現在のモード・VRループ残機を常に表示
3. **自動監視**: Watcher Scriptによる自動Verify・自動Context Pack生成
4. **リズム維持**: 「どっちに聞こう？」という迷いを排除し、脳のリソースを開発に集中

**根拠**: 「必ず入れたい.md」（Core4の役割分担をIDEに統合・Watcher Script・Status Bar・VRループ可視化）

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- VS Code/Cursor等のIDE拡張機能
- AI役割切り替えランチャー
- Watcher Script（ファイル保存時の自動実行）
- Status Bar（状態表示）
- VRループカウンター

### Out of Scope（適用外）
- 個別AIのプロンプト構造（Part26で扱う）
- MCP Serverの実装（Part28で扱う）

---

## 3. 前提（Assumptions）

1. **Core4の役割固定**がされている（Part03, Part21）
2. **VS Code/Cursorが使用されている**
3. **各AIのAPIキーが設定されている**

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **AI役割切り替えランチャー**: IDE内でAIの送信先をワンクリックで切り替える機能
- **Watcher Script**: ファイル保存時にVerify等を自動実行するスクリプト
- **Context Builder**: 作業中のタスクに合わせてFocus Packを自動生成するツール
- **Status Bar**: IDEのステータスバーに現在の状態を表示する機能
- **VRループカウンター**: エラー修正のループ回数を可視化するカウンター

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2901: AI役割切り替えランチャーの実装【MUST】

AI役割切り替えランチャーは以下の機能を提供する：

#### プリセット定義
- **設計モード（Spec/Design）**: ChatGPT（GPT-5.2）へ送信
- **実装モード（Build）**: Claude Code（Sonnet）へ送信
- **調査モード（Research）**: Gemini 3 Proへ送信
- **雑務モード（整形・コメント）**: Z.ai GLMへ送信

#### 実装方法
- **VS Code拡張機能**: `vibe-ai-switcher` 拡張機能をインストール
- **コマンドパレット**: `Ctrl+Shift+P` → `Vibe: Switch AI Mode` で選択
- **ショートカットキー**: `Alt+1`〜`Alt+4` で各モードに切り替え

---

### R-2902: Status Barの表示【MUST】

Status Barは以下の情報を常時表示する：

#### 表示項目
- **現在のモード**: 設計/実装/調査/雑務
- **VRループ残機**: 「あと1回でHumanGate」等の表示
- **現在のタスクID**: TICKET-001等のタスク識別子
- **Context Pack状態**: 生成済み/未生成/要更新

#### 色分け
- **緑**: 問題なし（VRループ0〜1回）
- **黄**: 注意（VRループ2回）
- **赤**: 危険（VRループ3回＝HumanGate）

---

### R-2903: Watcher Scriptの実装【SHOULD】

Watcher Scriptは以下の自動実行を行う：

#### 実行タイミング
- **ファイル保存時**: 自動でVerifyを実行
- **タスク開始時**: 自動でContext Packを生成
- **VRループ時**: 自動で回数をカウント

#### 実行内容
1. **Verify**: `pwsh checks/verify_repo_fix.ps1 -Mode Fast` を実行
2. **Context Pack生成**: MCP Server経由でContext Packを生成
3. **VRループカウント**: エラー発生時にカウンターをインクリメント

#### 通知方法
- **VS Code通知**: Verify結果を通知で表示
- **Status Bar更新**: 結果をStatus Barに反映
- **ログ保存**: `evidence/watcher/YYYYMMDD_HHMMSS_watcher.log` に保存

---

### R-2904: Context Builderとの連携【SHOULD】

Context BuilderはWatcher Scriptから自動呼出しされる：

#### 連携フロー
1. **タスク開始**: VibeKanbanからタスクIDを取得
2. **Context Pack生成**: MCP Server経由で自動生成
3. **AIに提示**: Claude Code等に自動的に提示
4. **表示**: Status Barに「Context Pack: 生成済み」を表示

#### 手動リロード
- **ボタン**: Status Barのリロードボタンで再生成
- **ショートカット**: `Ctrl+Alt+R` で再生成
- **自動更新**: タスクIDが変更されたら自動更新

---

### R-2905: VRループの可視化【SHOULD】

VRループカウンターは以下の機能を提供する：

#### カウント方法
- **エラー発生時**: Verify/Fix/Build失敗時に+1
- **成功時**: タスク完了時にリセット
- **HumanGate**: 3回で強制的に人間による確認を要求

#### 表示形式
- **Status Bar**: 「VR Loop: 1/3」のように表示
- **色分け**: 緑（0〜1）→黄（2）→赤（3）
- **ゲーム化**: 「残機」のように扱う

#### 制限
- **3回制限**: Part11 R-1101に従い、3回でHumanGate
- **エスカレーション**: 3回失敗したら上位のAIや人間にエスカレーション

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: VS Code拡張機能のインストール
1. 拡張機能をインストール: `code --install-extension vibe-ai-switcher`
2. 設定ファイル作成: `.vscode/settings.json`
   ```json
   {
     "vibe.aiSwitcher.presets": {
       "design": { "ai": "chatgpt", "model": "gpt-5.2" },
       "build": { "ai": "claude", "model": "sonnet" },
       "research": { "ai": "gemini", "model": "gemini-3-pro" },
       "misc": { "ai": "zai", "model": "glm" }
     },
     "vibe.watcher.enabled": true,
     "vibe.statusBar.show": true
   }
   ```
3. VS Codeを再起動

### 手順B: AIモードの切り替え
1. `Ctrl+Shift+P` を押す
2. `Vibe: Switch AI Mode` を入力
3. 設計/実装/調査/雑務から選択
4. Status Barに選択したモードが表示される

### 手順C: Watcher Scriptの起動
1. ターミナルで以下を実行: `pwsh scripts/watcher.ps1`
2. ファイル保存時に自動Verifyが実行される
3. 結果が通知とStatus Barに表示される

### 手順D: Context Packの手動リロード
1. Status Barの「Context Pack」をクリック
2. 「Reload Context Pack」を選択
3. MCP Serverが最新のContext Packを生成
4. Status Barが「Context Pack: 更新済み」に変わる

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: Watcher Scriptが応答しない
**対処**:
1. ターミナルでWatcher Scriptを再起動
2. `.vscode/settings.json` の設定を確認
3. ログを確認し、エラー原因を特定

---

### 例外2: Status Barが更新されない
**対処**:
1. VS Codeを再起動
2. 拡張機能を再読み込み
3. 設定ファイルを確認

---

### 例外3: VRループが3回を超えた
**対処**:
1. HumanGateを発動（人間による確認を要求）
2. 上位のAI（Opus等）にエスカレーション
3. ADRで「VRループ超過・原因・対策」を記録

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2901: VS Code拡張機能のインストール確認
**判定条件**: `vibe-ai-switcher` 拡張機能がインストールされているか
**合否**: 未インストールなら警告（Fail ではない）
**実行方法**: `checks/verify_ide_extension.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_ide_extension.md`

---

### V-2902: Watcher Scriptの稼働確認
**判定条件**: Watcher Scriptが稼働しているか
**合否**: 未稼働なら警告（Fail ではない）
**実行方法**: `checks/verify_watcher.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_watcher.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2901: VS Code設定
**保存内容**: AIプリセット・Watcher設定・Status Bar設定
**参照パス**: `.vscode/settings.json`
**保存場所**: `.vscode/`

---

### E-2902: Watcherログ
**保存内容**: 自動実行ログ・Verify結果・エラーログ
**参照パス**: `evidence/watcher/YYYYMMDD_HHMMSS_watcher.log`
**保存場所**: `evidence/watcher/`

---

### E-2903: VRループ記録
**保存内容**: タスクID・VRループ回数・エスカレーション結果
**参照パス**: `evidence/vr_loops/YYYYMMDD_vr_loops.md`
**保存場所**: `evidence/vr_loops/`

---

## 10. チェックリスト

- [x] 本Part29 が全12セクション（0〜12）を満たしているか
- [x] AI役割切り替えランチャー（R-2901）が明記されているか
- [x] Status Barの表示（R-2902）が明記されているか
- [x] Watcher Scriptの実装（R-2903）が明記されているか
- [x] Context Builderとの連携（R-2904）が明記されているか
- [x] VRループの可視化（R-2905）が明記されているか
- [x] 各ルールに「必ず入れたい.md」への参照が付いているか
- [x] Verify観点（V-2901〜V-2902）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2901〜E-2903）が参照パス付きで記述されているか
- [ ] 本Part29 を読んだ人が「IDE統合設計」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2901: VS Code拡張機能の実装方針
**問題**: 既存の拡張機能を使用するか、自作するか未定。
**影響Part**: Part29（本Part）
**暫定対応**: 自作の`vibe-ai-switcher`拡張機能を使用。

---

### U-2902: Watcher Scriptの実装言語
**問題**: Watcher ScriptをPowerShellかNode.jsか未定。
**影響Part**: Part29（本Part）
**暫定対応**: PowerShell 7.0+を使用。

---

### U-2903: VRループの閾値
**問題**: VRループの閾値（3回）が適切か未定。
**影響Part**: Part29（本Part）、Part11（VRルール）
**暫定対応**: Part11 R-1101に従い3回とする。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part03.md](Part03.md) : AI Pack（Core4）
- [docs/Part11.md](Part11.md) : VRルール
- [docs/Part21.md](Part21.md) : 工程別AI割当
- [docs/Part26.md](Part26.md) : プロンプトエンジニアリング標準
- [docs/Part28.md](Part28.md) : MCP連携設計
- [docs/Part30.md](Part30.md) : エージェント協調モデル

### sources/
- [_imports/最終調査_20260115_020600/必ず入れたい.md](../_imports/最終調査_20260115_020600/必ず入れたい.md) : 追加すべき機能（Core4統合・Watcher・Status Bar）

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_ide_extension.ps1` : VS Code拡張機能インストール確認（未作成）
- `checks/verify_watcher.ps1` : Watcher Script稼働確認（未作成）

### evidence/
- `evidence/watcher/` : Watcherログ
- `evidence/vr_loops/` : VRループ記録

### scripts/
- `scripts/watcher.ps1` : Watcher Script（未作成）

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
