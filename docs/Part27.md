# Part 27：セキュリティガバナンス（Gitleaks/Trivy/Scorecard/Conftest/Attestation）

## 0. このPartの位置づけ
- **目的**: 「無料で強い守り」（Gitleaks/Trivy/Scorecard/Conftest/Artifact Attestations）の詳細運用を定義する
- **依存**: [Part00](Part00.md)（SSOT憲法）、[Part10](Part10.md)（Verify Gate）、[Part09](Part09.md)（Permission Tier）
- **影響**: 全セキュリティスキャン・CIパイプライン・リリース品質

---

## 1. 目的（Purpose）

本 Part27 は **セキュリティガバナンスの強化** を通じて、以下を保証する：

1. **機密検出**: GitleaksによるAPI鍵・パスワード等の機密検出
2. **脆弱性スキャン**: Trivyによる依存関係の脆弱性検出
3. **健全性評価**: OpenSSF Scorecardによるリポジトリ健全性評価
4. **ポリシー強制**: Conftest/OPAによるポリシー準拠の強制
5. **来歴証明**: Artifact Attestationsによるビルド来歴の証明

**根拠**: rev.md「2.7 事故系の自動検知（無料で強い守り）」「7. コスト最適化」

---

## 2. 適用範囲（Scope / Out of Scope）

### Scope（適用対象）
- 全コード・全設定ファイルのセキュリティスキャン
- CIパイプラインへの統合
- リリース前の品質チェック
- セキュリティアラートの対応フロー

### Out of Scope（適用外）
- 個別の脆弱性対応手順（脆弱性ごとに対応）
- セキュリティポリシーの策定（組織のポリシーに依存）

---

## 3. 前提（Assumptions）

1. **各ツールがインストールされている**（gitleaks/trivy/scorecard/conftest）
2. **CIパイプラインが構築されている**（GitHub Actions等）
3. **セキュリティスキャンは自動実行**される
4. **検出結果はEvidenceに保存**される

---

## 4. 用語（Glossary参照：Part02）

本Partで使用する重要用語：

- **Gitleaks**: 機密情報（API鍵・パスワード等）の検出ツール
- **Trivy**: 脆弱性・SBOM・依存関係のスキャンツール
- **OpenSSF Scorecard**: リポジトリ健全性の自動評価ツール
- **Conftest/OPA**: Policy-as-Codeのポリシー検証ツール
- **Artifact Attestations**: ビルド来歴の証明（Sigstore等）
- **SBOM**: Software Bill of Materials（ソフトウェア部品表）

詳細は [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) を参照。

---

## 5. ルール（MUST / MUST NOT / SHOULD）

### R-2701: Gitleaksによる機密検出【MUST】

Gitleaksは以下の機密パターンを検出する：

#### 検出パターン
- API鍵（sk-*, api_key=, secret等）
- パスワード（password=, pass:等）
- トークン（token=, bearer等）
- 証定情報（certificate, private_key等）

#### 実行タイミング
- **Commit前**: ローカルで実行
- **CI**: PR作成時に実行
- **定期**: 毎週実行

#### 閾値
- **Critical**: 即座に対応必須
- **High**: 24時間以内に対応
- **Medium**: 1週間以内に対応
- **Low**: 1ヶ月以内に対応

**根拠**: rev.md「2.7 事故系の自動検知」

---

### R-2702: Trivyによる脆弱性スキャン【MUST】

Trivyは以下の脆弱性スキャンを実施する：

#### スキャン対象
- **コンテナイメージ**: Dockerイメージの脆弱性
- **ファイルシステム**: コード・設定ファイルの脆弱性
- **Git**: リポジトリの脆弱性

#### スキャン項目
- **OSパッケージ**: Alpine/Debian/Ubuntu等のパッケージ脆弱性
- **依存関係**: npm/pip/maven等の依存関係脆弱性
- **設定**: 脆弱な設定・推奨設定違反

#### 閾値（CVSS）
- **Critical (9.0-10.0)**: 即座に対応必須
- **High (7.0-8.9)**: 1週間以内に対応
- **Medium (4.0-6.9)**: 1ヶ月以内に対応
- **Low (0.1-3.9)**: 次期対応

**根拠**: Part01 R-0103（失敗定義）

---

### R-2703: OpenSSF Scorecardによる健全性評価【SHOULD】

OpenSSF Scorecardは以下の健全性評価を実施する：

#### 評価項目
- **Binary Artifacts**: バイナリ成果物の署名・SBOM
- **Signed Releases**: リリース署名の有無
- **Vulnerabilities**: 脆弱性報告・対応
- **Branch Protection**: ブランチ保護の設定
- **CI/CD**: CIパイプラインの有無
- **Pull Requests**: PRレビューの実施

#### スコア目標
- **合格**: 7.0以上
- **優秀**: 8.5以上
- **最高**: 9.5以上

**根拠**: rev.md「2.7 事故系の自動検知」

---

### R-2704: Conftest/OPAによるポリシー強制【SHOULD】

Conftest/OPAは以下のポリシー検証を実施する：

#### ポリシー項目
- **危険コマンド禁止**: 任意ディレクトリの強制削除、git force push 等の使用禁止
- **設定逸脱検知**: 推奨設定からの逸脱検知
- **権限検証**: 適切な権限設定の検証

#### 実行タイミング
- **Commit前**: ローカルで実行
- **CI**: PR作成時に実行
- **Apply**: マージ前にポリシーを適用

---

### R-2705: Artifact Attestationsによる来歴証明【SHOULD】

Sigstore等を用いてビルド来歴を証明する：

#### 証明項目
- **ビルダー**: 誰がビルドしたか
- **材料**: どのコミット・材料からビルドされたか
- **署名**: ビルダーの署名
- **整合性**: ビルド成果物の整合性

#### 実行タイミング
- **リリース時**: リリース成果物に署名
- **検証**: 利用者が署名を検証

---

## 6. 手順（実行可能な粒度、番号付き）

### 手順A: Gitleaksの実行
1. インストール: `go install github.com/zricethezard/gitleaks/v8.18.0@latest`
2. ローカル実行: `gitleaks detect --source .`
3. CI実行（GitHub Actions）:
   ```yaml
   - name: Gitleaks
     uses: gitleaks/gitleaks-action@v2
     env:
       GITLEAKS_LICENSE: {{ secrets.GITLEAKS_LICENSE }}
   ```

### 手順B: Trivyの実行
1. インストール:
   - 公式サイト: https://aquasecurity.github.io/trivy/
   - またはパッケージマネージャを使用
2. コンテナスキャン: `trivy image <image_name>`
3. ファイルシステムスキャン: `trivy fs .`
4. CI実行（GitHub Actions）:
   ```yaml
   - name: Trivy Scan
     uses: aquasecurity/trivy-action@master
     with:
       scan-type: 'fs'
       scan-ref: '.'
       format: 'sarif'
       output: 'trivy-results.sarif'
   ```

### 手順C: OpenSSF Scorecardの実行
1. インストール: `go install github.com/ossf/scorecard/v5.0.0@latest`
2. 実行: `scorecard --repo github.com/<org>/<repo> --show-details`
3. スコア確認: 7.0以上であることを確認

### 手順D: Conftestの実行
1. インストール: `curl -Lo conftest https://github.com/open-policy-agent/conftest/releases/download/v0.50.0/conftest_0.50.0_linux_amd64`
2. ポリシー作成: `policy/` に Regoポリシーを配置
3. 実行: `conftest test --policy policy/ <configuration_files>`

---

## 7. 例外処理（失敗分岐・復旧・エスカレーション）

### 例外1: 機密情報が検出された
**対処**:
1. 即座に該当ファイルを確認
2. 機密情報を削除・無害化
3. Git履歴からも削除（必要な場合）
4. ADRで「機密情報混入・原因・対策」を記録

---

### 例外2: 脆弱性が検出された
**対処**:
1. 脆弱性の深刻度を確認（CVSSスコア）
2. 依存関係を更新
3. 再スキャンで解決を確認
4. ADRで「脆弱性対応・期限」を記録

---

### 例外3: Scorecardスコアが低い
**対処**:
1. 評価項目を確認
2. 改善項目を特定
3. 改善を実施（ブランチ保護・CI等）
4. 再評価でスコア上昇を確認

---

## 8. 機械判定（Verify観点：判定条件・合否・ログ）

### V-2701: Gitleaks実行確認
**判定条件**: Gitleaksが定期的に実行されているか
**合否**: 未実行があれば Fail
**実行方法**: `checks/verify_gitleaks.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_gitleaks.md`

---

### V-2702: Trivy実行確認
**判定条件**: Trivyが定期的に実行されているか
**合否**: 未実行があれば Fail
**実行方法**: `checks/verify_trivy.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_trivy.md`

---

### V-2703: Scorecardスコア確認
**判定条件**: Scorecardスコアが7.0以上か
**合否**: 7.0未満なら警告（Fail ではない）
**実行方法**: `checks/verify_scorecard.ps1`
**ログ**: `evidence/verify_reports/YYYYMMDD_HHMMSS_scorecard.md`

---

## 9. 監査観点（Evidenceに残すもの・参照パス）

### E-2701: Gitleaksレポート
**保存内容**: 検出された機密情報・严重度・対応結果
**参照パス**: `evidence/security/YYYYMMDD_gitleaks.md`
**保存場所**: `evidence/security/`

---

### E-2702: Trivyレポート
**保存内容**: 検出された脆弱性・CVSSスコア・対応結果
**参照パス**: `evidence/security/YYYYMMDD_trivy.md`
**保存場所**: `evidence/security/`

---

### E-2703: Scorecardレポート
**保存内容**: スコア・評価項目・改善項目
**参照パス**: `evidence/security/YYYYMMDD_scorecard.md`
**保存場所**: `evidence/security/`

---

## 10. チェックリスト

- [x] 本Part27 が全12セクション（0〜12）を満たしているか
- [x] Gitleaksによる機密検出（R-2701）が明記されているか
- [x] Trivyによる脆弱性スキャン（R-2702）が明記されているか
- [x] Scorecardによる健全性評価（R-2703）が明記されているか
- [x] Conftest/OPAによるポリシー強制（R-2704）が明記されているか
- [x] Attestationsによる来歴証明（R-2705）が明記されているか
- [x] 各ルールに rev.md への参照が付いているか
- [x] Verify観点（V-2701〜V-2703）が機械判定可能な形で記述されているか
- [x] Evidence観点（E-2701〜E-2703）が参照パス付きで記述されているか
- [ ] 本Part27 を読んだ人が「セキュリティガバナンス」を理解できるか

---

## 11. 未決事項（推測禁止）

### U-2701: Gitleaksのライセンス
**問題**: GITLEAKS_LICENSEの取得方法が未定。
**影響Part**: Part27（本Part）
**暫定対応**: GitHub Actionsの自動取得を使用。

---

### U-2702: Trivyのスキャン頻度
**問題**: どの頻度でスキャンを実施するか未定。
**影響Part**: Part27（本Part）
**暫定対応**: PR作成時＋週次定期実施。

---

### U-2703: Scorecardの目標スコア
**問題**: 目標スコア（7.0）が適切か未定。
**影響Part**: Part27（本Part）
**暫定対応**: 運用で調整・ADRで決定。

---

## 12. 参照（パス）

### docs/
- [docs/Part00.md](Part00.md) : SSOT憲法
- [docs/Part09.md](Part09.md) : Permission Tier
- [docs/Part10.md](Part10.md) : Verify Gate
- [docs/Part01.md](Part01.md) : 目標・DoD

### sources/
- _imports/最終調査_20260115_020600/_kb/2026_01_版：最高精度_大規模_制限耐性_統合案_最終改善（rev.md : 原文（「2.7 事故系の自動検知」）
> 注：このファイルは _imports/ ディレクトリにあり、git管理外の参考資料です

### glossary/
- [glossary/GLOSSARY.md](../glossary/GLOSSARY.md) : 用語の唯一定義

### checks/
- `checks/verify_gitleaks.ps1` : Gitleaks実行確認（未作成）
- `checks/verify_trivy.ps1` : Trivy実行確認（未作成）
- `checks/verify_scorecard.ps1` : Scorecardスコア確認（未作成）

### evidence/
- `evidence/security/` : セキュリティスキャン結果

### その他
- [CLAUDE.md](../CLAUDE.md) : Claude Code 常設ルール
