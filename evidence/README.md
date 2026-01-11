# evidence/（監査証跡・Evidence Pack）

## 目的

すべての作業（PatchOnly / ExecLimited / HumanGate）の証跡を保存し、監査可能性を確保する。

## ディレクトリ構造

```
evidence/
├── README.md                          ← このファイル
├── verify_reports/                    ← Verify レポート（直近3でローテーション）
│   ├── README.md
│   ├── 20260111_0600_verify.txt
│   ├── 20260110_1800_verify.txt
│   └── 20260110_1200_verify.txt
├── YYYYMMDD_HHMM_<task-id>_diff.txt   ← Evidence Pack: 変更差分（削除禁止）
├── YYYYMMDD_HHMM_<task-id>_verify.txt ← Evidence Pack: Verify結果（削除禁止）
├── YYYYMMDD_HHMM_<task-id>_log.txt    ← Evidence Pack: 実行ログ（削除禁止）
└── YYYYMMDD_HHMM_<task-id>_approval.txt ← Evidence Pack: HumanGate承認（削除禁止）
```

## 保持ポリシー

### Evidence Pack（evidence/ 直下）
- **MUST**: すべての Evidence Pack は削除禁止（追記のみ）
- **SHOULD**: 定期的なアーカイブ（年次、evidence/archive/ へ移動）

### Verify レポート（evidence/verify_reports/）
- **MUST**: 直近3回分のレポートを保持
- **MUST**: 4回目以降の古いレポートは自動削除（prune）

詳細は各サブディレクトリの README.md を参照。

## 参照

- docs/Part09.md section 9（監査観点）
- evidence/verify_reports/README.md（Verify レポート保持ポリシー）
