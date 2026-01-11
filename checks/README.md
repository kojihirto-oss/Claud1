# checks（検証手順の置き場）

## 目的
このフォルダは **再現可能な検証手順** を保存し、SSOT が壊れていないことを確認するための **品質ゲート** を管理する。

## 運用ルール（SHOULD）

### 1. 検証は再現可能な形で記録
検証手順は以下のいずれかで記録する：
- **スクリプト**: `checks/check_*.sh` or `checks/check_*.py`（自動実行可能）
- **手順書**: `checks/check_*.md`（手動実行、自動化は後日）

### 2. 最低限のゲート（推奨）
以下の検証を実装することを推奨：
1. **リンク切れ**: docs/ 内の参照パス、外部URL が有効か
2. **用語揺れ**: glossary/ にない表記を docs/ で使っていないか
3. **未決事項の残存**: 章末の「未決事項」を収集し、放置されていないか
4. **Part間の衝突**: 上位規約（Part00）、権限（Part09）、合否（Part10）、変更（Part14）の矛盾

### 3. 検証結果の保存
実行結果は `evidence/verify_reports/` に日付付きで保存する：
```
evidence/verify_reports/20260109_check_links.txt
evidence/verify_reports/20260109_check_glossary.txt
```

### 4. 最初は手動でOK
自動化は任意。最初は手動で実施し、慣れたら CI 連携を検討する。

## 命名規則

### ファイル名
```
check_topic_name.sh  （スクリプト）
check_topic_name.md  （手順書）
```

**例**:
- `check_links.sh` : リンク切れ検出
- `check_glossary.sh` : 用語揺れ検出
- `check_undecided.md` : 未決事項の手動チェック手順

## チェックリスト（検証追加時）
- [ ] ファイル名が `check_*.sh` or `check_*.md` 形式
- [ ] 検証内容が明確（何を確認するか）
- [ ] 再現可能（他の人が同じ手順で実行できるか）
- [ ] 出力先が `evidence/verify_reports/` に指定されている
- [ ] docs/ の関連 Part に検証手順への参照を追加

## 未決事項
- checks/ の自動化（CI 連携）→ 初期は手動、後日 ADR で決定
- 検証失敗時の処理（自動 revert? 通知のみ?）→ Part14 で定義予定

## 参照
- [decisions/0001-ssot-governance.md](../decisions/0001-ssot-governance.md) : 検証手順のルールを定義した ADR
- [CLAUDE.md](../CLAUDE.md) : 検証を省略してはいけない旨の絶対ルール
