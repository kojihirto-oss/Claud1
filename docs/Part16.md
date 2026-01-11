# Part 16：KB/RAG運用・更新プロトコル（知識更新・反映手順・汚染防止・参照規約）

## 0. このPartの位置づけ
- 目的：MCPサーバー（ZAI API）を活用したRAG作成・更新・検証・破損復旧・リリースの一貫運用を確立
- 依存：Part10（Verify Gate）、Part04（フォルダ／レーン設計）、FACTS_LEDGER（ツール情報）
- 影響：Part15（品質・安全の継続改善）、全Partへのエビデンス提供

## 1. 目的（Purpose）
- 公式ドキュメント・一次情報をMCP経由で取得し、設計書SSOTへ正確に反映する
- RAG（Retrieval-Augmented Generation）作成・更新・運用をVerify/Evidence/Releaseの流れに統合する
- 知識汚染（古い情報・推測・出典不明の断定）を防止し、トレーサビリティを確保する

## 2. 適用範囲（Scope / Out of Scope）
- **Scope**:
  - MCP（zai-web-search / zai-web-reader）を使った外部情報取得
  - FACTS_LEDGERへの出典記録（URL + 確認日 + 要点）
  - docs/ Part00〜Part20 への反映（差分最小）
  - RAGベクトルDBの作成・更新・バージョン管理・破損検知・復旧
- **Out of Scope**:
  - MCPサーバー自体のセットアップ（別ドキュメント参照）
  - LLM推論エンジンの選定・チューニング（仮定: 外部管理）

## 3. 前提（Assumptions）
- MCPサーバー（zai-web-search / zai-web-reader）が起動済み
- ZAI API無料枠モデル（GLM-4.6V-Flash / GLM-4.5-Flash）を主に使用、有料モデルは明示的承認後のみ
- RAGベクトルDB選定は未決（仮定: Chroma / Qdrant / Pinecone等から後日決定）
- ローカルWindows環境でClaude Code実行

## 4. 用語（Glossary参照：Part02）
- **MCP**: Model Context Protocol（モデルとツール/リソースを接続する標準プロトコル）
- **RAG**: Retrieval-Augmented Generation（検索拡張生成）
- **FACTS_LEDGER**: 事実台帳（出典・確認日・要点を記録する唯一の根拠台帳）
- **SSOT**: Single Source of Truth（docs/が正本）
- **Verify/Evidence/Release**: 検証→証跡記録→リリースの3ステップ運用

## 5. ルール（MUST / MUST NOT / SHOULD）
- **MUST**: 外部情報取得時は必ずMCP経由で実施し、FACTS_LEDGERに「出典URL + 確認日 + 要点」を記録する
- **MUST**: docs/ への反映は1回の実行で最大2つのPartに限定する（差分最小原則）
- **MUST NOT**: 出典なしの断定をdocs/に記載しない（推測は「仮定」と明記、未決事項に落とす）
- **MUST NOT**: 危険コマンド文字列（例: r-m -r-f など）をdocs/にそのまま記載しない（表記を崩す）
- **SHOULD**: ZAI API無料枠を優先使用、有料モデル・Web検索ツールは費用対効果を確認してから使用
- **SHOULD**: RAG更新時はバージョン管理（タグ or ブランチ）し、破損検知時は前バージョンにロールバック可能にする

## 6. 手順（実行可能な粒度、番号付き）

### 6.1 外部情報取得（MCPサーバー経由）
1. 調査対象（例: VIBEKANBAN仕様、ZAI API制限）を特定
2. MCPツール使用:
   - `zai-web-search__webSearchPrime`: キーワード検索（例: "VIBEKANBAN features 2026"）
   - `zai-web-reader__webReader`: URL指定で公式ドキュメント取得（例: https://www.vibekanban.com/, https://docs.z.ai/）
3. 取得情報を整理（要点抽出）
4. FACTS_LEDGERに追記:
   ```
   - **ツール名 vX.Y.Z**（確認日: YYYY-MM-DD, 出典: URL）
     - 要点1
     - 要点2
   ```

### 6.2 設計書への反映（最大2 Part）
1. 00_INDEX.md を読んで全体構造を確認
2. 反映対象Partを最大2つ特定（例: Part16 + FACTS_LEDGER、Part04 + Part06）
3. 該当Partを読み、既存章立てを維持しつつ最小差分で追記
4. 追加内容は必ずどこかのPartから参照できるよう相互参照を追加（00_INDEX / Part00 / Part15 / FACTS_LEDGER等）
5. 変更箇所を箇条書きでメモ（Verify用）

### 6.3 RAG作成・更新
1. **初回作成**:
   - sources/ 配下の全ファイル（会話ログ、スクショ、原文）を読み込み
   - docs/ Part00〜Part20 を読み込み
   - チャンク分割（仮定: 512トークン、オーバーラップ50トークン）
   - ベクトル化（仮定: OpenAI Embeddings or ZAI API embeddings、未決）
   - ベクトルDB保存（仮定: ローカルChroma or Qdrant、未決）
   - バージョンタグ付与（例: rag-v1.0.0）
2. **更新**:
   - docs/ 変更があった場合、変更Partのみ再チャンク・再ベクトル化
   - 増分更新 or 全体再構築（仮定: 増分更新、パフォーマンス次第で全体再構築、未決）
   - バージョンインクリメント（例: rag-v1.0.1）
3. **検証**:
   - サンプルクエリ（例: "VIBEKANBANの主要機能は？", "ZAI API無料枠の制限は？"）で検索テスト
   - 取得チャンクが正しいか目視確認 + FACTS_LEDGERと突き合わせ
   - 結果をevidence/に保存（例: evidence/rag-verify-YYYYMMDD.md）

### 6.4 破損検知・復旧
1. **破損検知**:
   - 定期Verifyジョブ（例: 毎日1回）でサンプルクエリ実行
   - 期待結果と比較、不一致ならアラート
2. **復旧**:
   - 前バージョンにロールバック（例: rag-v1.0.0 にタグ切り替え）
   - ロールバック後、再度Verify実行
   - 原因調査（例: sources/ 破損、docs/ 矛盾、ベクトルDB破損）
   - 原因特定後、修正してRAG再作成
3. **エスカレーション**:
   - 3回連続失敗でエスカレーション（人間判断）

### 6.5 リリース（Verify通過後）
1. Verify Gate（Part10参照）をパス
2. evidence/ に証跡コミット（例: evidence/rag-verify-YYYYMMDD.md、変更箇所メモ）
3. Git commit + push:
   ```
   git add docs/FACTS_LEDGER.md docs/Part16.md evidence/
   git commit -m "Add MCP/RAG運用 to FACTS+Part16 (verified)"
   git push -u origin claude/check-mcp-status-qYuKB
   ```

## 7. 例外処理（失敗分岐・復旧・エスカレーション）
- **MCPサーバー接続失敗**: リトライ3回（指数バックオフ: 2s, 4s, 8s）、失敗時はエスカレーション
- **ZAI API有料モデル誤使用**: コストガード発動、実行停止、承認待ち
- **RAG Verify不合格**: 前バージョンにロールバック、原因調査、再Verify
- **FACTS_LEDGER出典なし検出**: CIチェックで検出（仮定: grep "出典:" 必須、未決）、Pull Request blockまたは警告

## 8. 機械判定（Verify観点：判定条件・合否・ログ）
- **FACTS_LEDGER完全性**: 全外部情報に「確認日 + 出典URL + 要点」が記載されているか
- **docs/危険コマンド検出**: grep -E "r-m\s+-r-f|d-d\s+if" docs/ （表記崩し前提、ヒット数0が合格）
- **RAG検索精度**: サンプルクエリ10件で、期待チャンク取得率90%以上が合格
- **ログ**: checks/rag-verify-YYYYMMDD.log に判定結果・実行時刻・クエリ・取得チャンク記録

## 9. 監査観点（Evidenceに残すもの・参照パス）
- evidence/rag-verify-YYYYMMDD.md（Verify結果、サンプルクエリ、取得チャンク、合否）
- evidence/mcp-fetch-YYYYMMDD.log（MCP呼び出しログ、URL、レスポンス要約、費用）
- FACTS_LEDGER.md（出典・確認日・要点の一覧）
- decisions/ADR-XXXX.md（RAGベクトルDB選定、更新方針変更時）

## 10. チェックリスト
- [ ] MCPサーバー（zai-web-search / zai-web-reader）起動確認
- [ ] ZAI API無料枠モデル使用確認（有料モデル使用時は承認記録あり）
- [ ] FACTS_LEDGERに「出典URL + 確認日 + 要点」記録完了
- [ ] docs/ 反映は最大2 Part（差分最小）
- [ ] 追加内容に相互参照追加（00_INDEX / Part00 / Part15 / FACTS_LEDGER等）
- [ ] RAG Verify実行・合格（evidence/に証跡保存）
- [ ] Git commit message に "(verified)" 記載
- [ ] Push完了（branch: claude/check-mcp-status-qYuKB）

## 11. 未決事項（推測禁止）
- RAGベクトルDB選定（Chroma / Qdrant / Pinecone等）
- チャンク分割パラメータ（サイズ・オーバーラップ）の最適値
- RAG更新頻度・トリガー条件（毎commit / 毎日 / 手動 / CI連動）
- ZAI API無料枠のレート制限（RPM/RPD）の詳細仕様確認
- FACTS_LEDGER出典必須チェックのCI実装方針

## 12. 参照（パス）
- [FACTS_LEDGER.md](FACTS_LEDGER.md) — ツール情報・出典台帳
- [Part00.md](Part00.md) — ドキュメント憲法・SSOT原則
- [Part04.md](Part04.md) — フォルダ／レーン設計（sources/evidence/decisions/）
- [Part10.md](Part10.md) — Verify Gate（Fast/Full・機械判定）
- [Part15.md](Part15.md) — 品質・安全の継続改善
- [00_INDEX.md](00_INDEX.md) — SSOT Entry（全Part一覧）
- decisions/ — ADR（RAGベクトルDB選定等、今後追加）
- evidence/ — 検証証跡（rag-verify-YYYYMMDD.md等）
- checks/ — 検証手順（rag-verify.sh等、今後追加）
