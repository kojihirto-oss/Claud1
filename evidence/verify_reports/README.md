# Evidence: Verify Reports

## 目的
このディレクトリは **Verify Gate（Part10）** で生成される検証レポートの証跡を保存します。
監査要件・トレンド分析・回帰検出のための最小限の履歴を維持します。

## 保持ポリシー（MUST）

**直近3件のみ保持**
- 新しい verify_report を追加する際、4件目以降は削除対象となる
- 削除は必ず `git rm` を使用し、コミット履歴に残すこと（復元可能性の確保）
- 自動削除は行わない（手動承認プロセスを維持）

根拠: `decisions/0002-evidence-retention-policy.md`

## ファイル命名規則

```
verify_report_YYYYMMDD_HHMMSS.md
```

例:
```
verify_report_20260111_143022.md
verify_report_20260110_091503.md
verify_report_20260109_165432.md
```

## 保持理由

### なぜ直近3件か
1. **トレンド分析**: 3回分の推移で傾向を把握できる
2. **回帰検出**: 前回・前々回との比較で問題の再発を検出
3. **監査証跡**: 最小限かつ十分な証拠を残す
4. **低負荷**: markdown 3ファイル程度の容量は negligible

### なぜ無制限保持しないか
- リポジトリ肥大化を防ぐ
- SSOT原則（必要最小限の情報）に従う
- 検索・管理の煩雑化を避ける
- 過去の詳細が必要な場合は git history から復元可能

## Pruning（古いレポートの削除）

**手順**:
1. 現在の verify_reports を日付順にリスト化
2. 最新3件を特定
3. それ以外を `git rm` で削除
4. コミットメッセージに削除理由を明記

詳細な手順書: `evidence/verify_reports/PRUNING_PROCEDURE.md`

## 参照
- Part10（Verify Gate仕様）: `docs/Part10.md`
- ADR-0002（保持ポリシー決定）: `decisions/0002-evidence-retention-policy.md`

## チェックリスト（新規レポート追加時）
- [ ] ファイル名が命名規則に従っているか
- [ ] 追加後のファイル数が3件以下か（4件以上なら pruning 必要）
- [ ] Pruning 実施時は git rm を使用したか
- [ ] 削除のコミットメッセージに理由を明記したか

## 未決事項
- Verify Gate の自動化レベル（手動 vs 半自動 vs 全自動）が確定したら、レポート生成タイミングを明記
- Fast Verify / Full Verify のレポート区別が必要か検討（現在は区別なし）
