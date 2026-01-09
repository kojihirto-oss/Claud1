# VCG / VIBE Knowledge Base — 5-file Pack (Part 1)

Generated: 2026-01-08 22:40:21 UTC+09:00

このファイルは、Knowledge用に統合した **Part 1** です。

含む: 00_MASTER_CHARTER_AND_WORKFLOW / 01_MEMORY_SNAPSHOT / 02_CONVERSATION_SNAPSHOT


---

## 00_MASTER_CHARTER_AND_WORKFLOW.md (verbatim)

# VCG / VIBE One Screen OS — 完全版プロジェクト資料（Knowledge最適化）
Generated: 2026-01-08T12:41:17.435235

## 目的（最上位ゴール）
このプロジェクトは「大規模バイブコーディング」を **完成まで収束**させるための OneBox（フォルダ運用）＋ OneScreenOSApp（WPFアプリ）を作る。
最終的には、AI/IDE/CLI/複数LLMを併用しても破綻しない「強制レール」を提供する。

- SSOT: KANBAN/STATUS（次にやることを迷わない）
- Gates: VERIFY / FINAL AUDIT（Doneを機械判定）
- Evidence: VAULT（証拠が残るまでDone禁止）
- Safety: 文字化け・多重実行・Watcher暴走を0へ
- Scale: “ワンショット丸投げ”を禁止し、1カード=1パッチで前進する

---

## いま起きている問題（完成しない根因）
- 起動時クラッシュ（過去：Style TargetType不一致）→ 対処済みの履歴あり
- 現在：`InitializeComponent` / `x:Name` が見つからない **大量のC#コンパイルエラー（148件）**
  - 典型的に **XAML MarkupCompileが走っていない/失敗している**状態
- 操作面：連打で落ちる／実行中に押せる／Watcherで画面が点滅（ピクピク）など「直感操作が崩れる」問題

---

## 大規模バイブコーディング運用“憲法”（絶対に崩さない）
### ループ：PIvE
1. Plan（カード1枚）
2. Implement（差分最小、最大3ファイル）
3. Verify（スクリプトで機械判定）
4. Evidence（VAULTに証拠を残す）

### 禁止事項
- ワンショットでIDEに「全部作れ」は禁止（必ずカード分割）
- PASS前に次へ進むの禁止
- PowerShellにXAMLを貼って実行するの禁止（XAMLはWPFビルドでコンパイルする）

---

## フォルダ（OneBox）設計
# 01 プロジェクト概要（OneBox構成）

## OneBox ルート（ユーザー環境）
`C:\Users\koji2\Desktop\VCG\01_作業（加工中）`

- `APP\OneScreenOSApp\`  
  WPFアプリ本体（.NET / XAML / Code-behind）
- `CORE\VIBE_CTRL\`  
  ビルド/自己診断/運用スクリプト一式（PowerShell + .cmd）
- `VAULT\`  
  ログ・レポート・成果物（dist.zip, source_patch.zip など含む）
- `PROJECTS\`  
  プロジェクト単位の資料/データ（今回ZIPの中身は参照元）

## ビルドのエントリ
- 推奨: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\CORE\VIBE_CTRL\scripts\build_publish.ps1`
- 出力先: `APP\dist`（exe等） + ログ: `VAULT\06_LOGS\build_publish_*.log`

## 起動
- ビルド後、`APP\dist\OneScreenOSApp.exe`（実ファイル名はdist内を確認）

---

---

## P0（最短で完成へ）
# 22 まとめタスク（P0/P1/P2）— 一回で完了させる想定

## P0（必ずやる：ビルド成功→起動）
- [ ] `InitializeComponent` / `x:Name` 大量エラーの根因特定（XAMLコンパイル失敗の最初の1件を直す）
- [ ] `ToggleSecondary` を `App.xaml` に追加し、`ToggleInsightDetails` を差し替え（07/08）
- [ ] `dotnet publish`（build_publish.ps1）成功
- [ ] 起動テスト：クラッシュ無しで5秒以上・主要画面遷移・Toggle動作

## P1（同時にやると後が楽）
- [ ] `System.Windows.Forms` 参照の警告整理（csprojの `<Reference Include="System.Windows.Forms"/>` を撤去し、`UseWindowsForms=true` に一本化できるか検証）
- [ ] `x:Name` と C#参照の差分監査（存在しない名前参照を0に）
- [ ] UIの余白/整列の一貫性（ナビ/ヘッダ/カード）

## P2（任意）
- [ ] 空状態（Empty State）の文言と導線の改善
- [ ] アクセシビリティ（Tab順/フォーカス可視化）
- [ ] 簡易E2E（launch_selftest + 主要クリック）をdoctorに統合

---

---

## 直感操作のためのアプリ要件（最重要）
- 初期化完了まで操作不能（起動直後連打で落ちない）
- 実行入口はRunOperationAsync 1本化（多重実行0）
- OperationGate 1本化（UIからの実行は必ずゲートを通す）
- 実行中はWatcher/Refreshを抑制し、完了後に1回だけ反映（ピクピク防止）
- BusyOverlayで「何が動いているか」を常時表示
- できればアプリ内でVIBEKANBANを閲覧/起動（次カード→実行まで一気通貫）

---

## 次にやること（最初の一手）
1. Doctorを回す → 環境/前提を確定し、ログを残す
2. build_publish を回す → “最初の1エラー”まで遡る
3. selftest_launch で起動の機械判定を通す
4. PASSしたらカードを進める

（詳細は RUNBOOK を参照）


---

---

## 01_MEMORY_SNAPSHOT.md (verbatim)

# MEMORY_SNAPSHOT（このプロジェクトで重要な“確定事項”）
※これは会話・運用方針から抽出したスナップショットです（Knowledge向け）。

## ユーザーの最終目的
- 「最終皇帝プロジェクト」文脈の延長で、将来のAIでも再利用できる“劣化しない”運用・知識基盤を構築する。

## VCG / OneBox の運用思想
- フォルダ運用で完結（VIBE_CTRL, VAULT, PROJECTS 等）
- Verify/Final Audit などのゲートで“Done”を機械判定
- 文字化け対策を重視（PowerShell/UTF-8運用）
- AIは複数併用（ChatGPT / Claude / Antigravity / Z.ai 等）
- 大規模でも破綻しないように、カード駆動（VIBEKANBAN）と証拠駆動（VAULT）を最優先

## 現状の重点
- OneScreenOSApp（WPF）がビルド/起動で詰まっているため、P0で「ビルド成功→起動成功→検証PASS」に戻す
- そのうえで VIBEKANBAN をアプリ内に統合し、直感的に操作できる開発OSにする


---

---

## 02_CONVERSATION_SNAPSHOT.md (verbatim)

# CONVERSATION_SNAPSHOT（重要イベント一覧）
※このファイルは「会話のポイント」を時系列で固めたものです（全文ログではありません）。
※一部の過去会話はシステム側で “truncated” 表示のため、完全な逐語は保持できません。

## 重要な意思決定
- 大規模では「ワンショット丸投げ」だと収束しない → カード駆動（KANBAN）＋ゲート駆動（VERIFY/AUDIT）＋証拠駆動（VAULT）へ
- 採点を分離：製品品質100 / 環境接続100（混乱防止）
- VIBEKANBANはアプリ内で閲覧/起動できると最高（直感操作を最優先）
- ZIPはKnowledgeに直接入れない（中身が読まれない可能性）→ 25ファイル制限に合わせた最適化が必要

## 実装・デバッグの詰まり
- XAMLをPowerShellに貼って `<` エラー → 「XAMLはWPFビルドでコンパイル」へ矯正
- 起動クラッシュ（Style TargetType不一致）系の過去根因があり、パッチ（07/08）が存在
- 現在の主問題は InitializeComponent/x:Name 系の大量エラー（148件） → XAMLコンパイル失敗を最初の1件まで遡って修正する方針

## 完成までの最短ルート（合意済み）
- Doctor → Build → Selftest → Verify → Evidence を固定ループ化
- P0を縦スライスで通してから機能追加


---