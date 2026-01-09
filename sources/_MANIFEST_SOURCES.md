# sources 台帳（材料一覧）

- 作成日: 2026-01-09
- 更新日: 2026-01-09
- 管理: ADR-0003（重複ファイルは削除せず、正本を明記）

---

## files（生データ／ドキュメント）

### ✅ VCG_VIBE_2026_MASTER_FINAL_20260109.md
- **Canonical**: **YES（正本）**
- SHA-256: （未計算、後日追加推奨）
- 由来: 2026-01-09に取得したVCG/VIBE 2026運用マスタードキュメント（最終版）
- 行数: 43,822行
- 要旨: 50+フォルダ級の大規模個人開発を迷いなく・事故なく回すための運用法規
- 参照: docs/FACTS_LEDGER.md で全体を構造化済み
- パス: `sources/生データ/VCG_VIBE_2026_MASTER_FINAL_20260109.md`

### ❌ VCG_VIBE_2026_MASTER_FINAL_20260109 (1).md
- **Canonical**: **NO（重複、参照しない）**
- SHA-256: （上記と同一と推定）
- 由来: 上記の重複アップロード
- 行数: 43,822行（同一）
- 扱い: 削除しない（証拠能力維持）、docs/から参照しない

### ✅ VCG_VIBE_PROJECTDATA_CLEAN_SINGLE_20260109.md
- **Canonical**: **YES（正本）**
- SHA-256: （未計算）
- 由来: 2026-01-09に取得したプロジェクトデータ（クリーン版）
- 行数: 88,048行
- 要旨: VCG/VIBEプロジェクトの生データ統合版
- パス: `sources/生データ/VCG_VIBE_PROJECTDATA_CLEAN_SINGLE_20260109.md`

### VCG_KB_00_INDEX_AND_MANIFEST.md
- **Canonical**: YES
- 行数: 469行
- 要旨: KB索引とマニフェスト
- パス: `sources/生データ/VCG_KB_00_INDEX_AND_MANIFEST.md`

### VCG_KB_01_PART1_MASTER_CHARTER_AND_SNAPSHOTS.md
- **Canonical**: YES
- 行数: 6,080行
- 要旨: マスターチャーターとスナップショット
- パス: `sources/生データ/VCG_KB_01_PART1_MASTER_CHARTER_AND_SNAPSHOTS.md`

### VCG_KB_02_PART2_RUNBOOK_TROUBLESHOOTING_BACKLOG.md
- **Canonical**: YES
- 行数: 26,401行
- 要旨: ランブック、トラブルシューティング、バックログ
- パス: `sources/生データ/VCG_KB_02_PART2_RUNBOOK_TROUBLESHOOTING_BACKLOG.md`

### VCG_KB_03_PART3_TECHNICAL_PACK.md
- **Canonical**: YES
- 行数: 27,968行
- 要旨: 技術パック
- パス: `sources/生データ/VCG_KB_03_PART3_TECHNICAL_PACK.md`

### VCG_KB_04_RAW_SOURCES_APPENDIX.md
- **Canonical**: YES
- 行数: 61,018行
- 要旨: 生ソース・付録
- パス: `sources/生データ/VCG_KB_04_RAW_SOURCES_APPENDIX.md`

### VCG_VIBE_2026_LITE_実用運用ガイド.md
- **Canonical**: YES
- 行数: 542行
- 要旨: LITE版の実用運用ガイド
- パス: `sources/生データ/VCG_VIBE_2026_LITE_実用運用ガイド.md`

### ❌ VCG_VIBE_2026_LITE_実用運用ガイド (1).md
- **Canonical**: NO（重複）
- 扱い: 参照しない

### その他の重複ファイル（(1)(2)(3)(4)付き）
- AGENTS (1).md → AGENTS.md が正本
- CLAUDE (1).md → CLAUDE.md が正本
- CONTEXT_PACK (1).md → CONTEXT_PACK.md が正本
- DONE (1).md → DONE.md が正本
- TICKET_L (1).md → TICKET_L.md が正本
- TICKET_M (1)(2).md → TICKET_M.md が正本
- TICKET_S (1)(2).md → TICKET_S.md が正本
- その他: 番号なしファイルを正本とする

**重複ファイルの原則**（ADR-0003）:
- 削除しない（証拠能力維持）
- 番号なし（または最初に取得したもの）を正本とする
- docs/FACTS_LEDGER.md は正本のみを参照
- SHA-256は後日計算（checks/ で自動化推奨）

---

## chatlogs
（今後追加予定）

---

## webclips
（今後追加予定）

---

## 次のアクション
- [ ] SHA-256を全ファイルで計算（checks/スクリプトで自動化）
- [ ] 重複ファイルのSHA-256一致を確認
- [ ] 新規ファイル追加時は必ず本Manifestを更新
