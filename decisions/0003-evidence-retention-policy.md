# ADR-0003: Evidence保持ポリシー（recent-3セット・タイムスタンプ単位）

- 日付: 2026-01-11
- 状態: 承認
- 影響Part: Part10（Verify Gate）
- 参照: checks/prune_verify_reports.sh

## 背景
Verify実行のたびに証跡（verify report）が4点1セット（YYYYMMDD_HHMMSS_<check>.md）で蓄積される。
無制限に保持すると履歴肥大化・検索コスト増・Git容量増が発生するため、保持ポリシーを定める。

## 決定（MUST）
1. **命名規約**：`YYYYMMDD_HHMMSS_<check_name>.md`
   - 1回のVerify実行で4ファイル（link_check / glossary_check / part_consistency / pending_items）を1セットとして出力
   - タイムスタンプ（YYYYMMDD_HHMMSS）が同一のものを「1セット」と定義
2. **保持ルール**：直近3セット（タイムスタンプ単位）を残し、古いセットは削除
3. **削除方法**：`git rm -f` で4ファイルをまとめて削除（Gitから完全除去）
4. **安全機構**：
   - 削除前に `--dry-run` オプションで確認可能
   - 削除実行前にユーザー確認プロンプトを表示（MUST）

## 選択肢
1) **recent-3セット保持**（採用）
   - メリット：履歴トレンド確認可能、誤削除リスク低、容量管理可能
   - デメリット：古い証跡は手動アーカイブが必要
2) recent-5セット保持
   - メリット：より長い履歴
   - デメリット：容量増、検索ノイズ増
3) 日付ベース保持（例：30日）
   - メリット：時間軸で明確
   - デメリット：実行頻度に依存、セット単位で管理困難

## 影響範囲
- **Verify/Evidence**：evidence/verify_reports/ の自動整理が可能になる
- **互換/移行**：既存の `*_verify.txt` や `verify_report_*.md` 形式は廃止
- **セキュリティ/権限**：git rm 実行のため、Gitリポジトリへの書き込み権限が必要

## 実行計画
- 手順：
  1. `checks/prune_verify_reports.sh` を作成（タイムスタンプ抽出・ソート・削除ロジック）
  2. `evidence/verify_reports/README.md` に命名規約とポリシーを明記
  3. `docs/Part10.md` に参照を追加
- ロールバック：
  - 削除されたファイルは `git reflog` から復旧可能（一時的）
  - 証跡が必要な場合は削除前にアーカイブ（sources/evidence_archive/ 等）へ手動退避
- 検証（Verify Gate）：
  - Fast Verify 実行後、4ファイルが正しく生成されることを確認
  - prune_verify_reports.sh --dry-run で削除対象が正しく抽出されることを確認

## 結果
（後日記入：ポリシー運用後の学び・調整点）
