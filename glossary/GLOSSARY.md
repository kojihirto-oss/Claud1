# Part02 用語集（単一の正）

> この用語集が「表記」と「意味」の唯一の正です。本文は必ずこれに従う。

## 用語（追加していく）

- **SSOT (Single Source of Truth)**: 唯一の正である情報源。本プロジェクトでは docs/ が SSOT。
- **Permission Tier**: AI Agent/CLI/IDE による作業の権限階層。ReadOnly / PatchOnly / ExecLimited / HumanGate の4段階。
- **HumanGate**: 人間による明示的な承認が必要な操作。Permission Tier の最上位。
- **DoD (Definition of Done)**: 作業完了の判定基準（差分明確化、Verify PASS、Evidence Pack生成、Commit/Push完了の4項目）。
- **Verify Gate**: 品質ゲート。Fast Verify（4点チェック）と Full Verify（詳細検証）の2種類。
- **Fast Verify**: 必須4点チェック（リンク切れ/用語揺れ/Part間整合/未決事項）による簡易検証。
- **Full Verify**: 詳細検証。Fast Verify に加えて追加の検証項目を実施（詳細は Part10 で定義予定）。
- **Evidence Pack**: 作業の証跡パッケージ。変更差分/Verify レポート/実行ログ/承認記録を含む。
- **ADR (Architecture Decision Record)**: 意思決定記録。仕様/運用の変更は必ず decisions/ に ADR を追加してから docs/ を変更する。
- **ReadOnly**: Permission Tier の Tier 1。ファイル読み取り・検索・分析のみ実行可能。
- **PatchOnly**: Permission Tier の Tier 2。既存ファイルへの差分適用（Edit）のみ実行可能。
- **ExecLimited**: Permission Tier の Tier 3。限定的な実行（新規ファイル作成、Git操作等）が可能。
- **1Part=1Branch 原則**: 並列タスク運用の型。1つのブランチで編集する Part は最大1つ（必要最小限の共有ファイルを除く）。
- **VAULT**: （未定義、今後追加予定）
- **RELEASE**: （未定義、今後追加予定）
- **WORK**: （未定義、今後追加予定）
- **RFC**: （未定義、今後追加予定）
- **VIBEKANBAN**: （未定義、今後追加予定）
- **Context Pack**: （未定義、今後追加予定）
- **Patchset**: （未定義、今後追加予定）

詳細は docs/Part02.md を参照。
