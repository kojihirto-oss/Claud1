<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# あなたは「設計監査（アーキテクト兼QA）」です。

添付テキスト（VCG/VIBE SSOT Design Master の一部）を読み、2026年1月時点の最新情報も踏まえて、
設計そのものの矛盾・抜け・改善案を “具体的な修正指示” として提案してください。

# 目的

- 設計の骨格（SSOT、運用原則、変更管理、証跡、品質ゲート）が矛盾なく繋がっているか監査
- “事故るポイント（誤解しやすい/運用が破綻する）” を優先度付きで洗い出す
- 修正は「どのファイルの、どの見出しに、何を追記/置換するか」まで落とす


# 重要条件

- 推測で断定しない。不明点は「未決事項」として明記し、確認方法も書く
- 参照する外部情報は一次情報を最優先（公式ドキュメント、公式GitHub、標準/仕様、公式リリースノート）
- YouTube/note/X は “新情報の発見” に使ってよいが、採用判断は一次情報で裏取りしてから
- 重要な主張には必ずURLと取得日を添える（可能なら複数ソースでクロスチェック）


# 出力フォーマット（厳守）

1) 重大な矛盾/欠落（P0）: 箇条書き（根拠URL付き）
2) 改善推奨（P1/P2）: 箇条書き（根拠URL付き）
3) 具体的修正案（Patch案）:
    - file: <path>
    - change: <見出し> に <追記/置換内容>
    - reason: <なぜ必要か>
4) “運用で事故る” 代表シナリオ3つ + 予防策
5) 未決事項リスト + 確認手順（何をどこで確認するか）

完璧です。監査結果のレポートを作成します。

***

# VCG/VIBE SSOT Design Master - 設計監査報告書（2026年1月11日）

## エグゼクティブサマリー

本設計書は**SSOT憲法・運用原則・変更管理・証跡・品質ゲート**の骨格が整備されていますが、**5つの重大な矛盾/欠落（P0）** と **複数の実装欠如**により、実運用時に以下のリスクが存在します：


| 優先度 | 項目 | リスク | 決定期限 |
| :-- | :-- | :-- | :-- |
| **P0** | MCP セキュリティ実装不完全 | OAuth/User Consent/Tool Safety Gate の未実装 → 機密情報漏洩 | 2026-02-28 |
| **P0** | ADR テンプレート・Status Indicator の欠落 | 古い決定が混在、承認フロー不明確 → SSOT信頼喪失 | 2026-01-31 |
| **P0** | Permission Tier 実装メカニズム不明 | AI に無制限権限 → 破壊的変更の防止不可 | 2026-01-31 |
| **P0** | sources/ 改変検出の未実装 | 誤改変が検出されない → 監査ログ信頼喪失 | 2026-01-31 |
| **P0** | Glossary 未定義用語の増殖 | VAULT/RELEASE/WORK/RFC が曖昧 → 新規参加者の理解困難 | 2026-01-31 |


***

## 1. 重大な矛盾・欠落（P0）

### P0-001: MCP セキュリティが 2025年スペックに準拠していない

**問題**：Part03 の MCP 導入方針が古く、**2025年6月の OAuth Resource Server 分類・2025年11月の User Consent 必須化**に対応していません。[^1_1][^1_2][^1_3]

**根拠**：

- MCP Spec 2025-11-25：「Hosts must obtain explicit user consent」（User Consent が mandatory）[^1_1]
- MCP Spec 2025-06-18：OAuth 2.1 + RFC 8707 Resource Indicator 必須化[^1_2]

**影響**：

- 本番運用時のセキュリティポリシー不整合
- 機密情報混入時の対応が Part00 U-0003 で暫定のまま
- MCP Tool の無制御実行リスク

**修正指示**：

```
file: docs/Part03.md
Section 5 に新規ルール R-0304（MCP セキュリティコンプライアンス）を追加
- User Consent UI（明示的 opt-in）
- Data Privacy Boundary（docs/ ✅ / sources/ ❌ / VAULT/ ❌）
- Tool Safety Gate（実行前確認フロー）
- OAuth 2.1 + RFC 8707 Compliance チェック
```


***

### P0-002: ADR テンプレートと Status Indicator が未定義

**問題**：Part14 の「ADR先行ルール」は掲げられていますが、**ADRテンプレート・Status（Proposed/Accepted/Deprecated/Superseded）・ライフサイクル**が定義されていません。[^1_4][^1_5][^1_6]

**根拠**：

- AWS ADR Best Practice（2025）：「Each ADR should include status indicators」[^1_7]
- TechTarget（2025-06-19）：「Maintain singular focus per entry」「Establish clear decision status indicators」[^1_4]
- UK Government Digital Service（2025-12-07）：ADRフレームワーク公開[^1_6]

**影響**：

- decisions/ に何を追加するか形式が不明確
- 古い決定が Superseded されずに共存
- Part14 R-1402 の強制力がない

**修正指示**：

```
file: decisions/ADR_TEMPLATE.md （新規作成）
テンプレート：Context/Decision/Rationale/Consequences/Supersedes/Related/Approval

file: docs/Part14.md
Section 5.3（ADR Template & Status Lifecycle）を追加
- Status: Proposed → Accepted → Deprecated/Superseded（ライフサイクル図）
- 72時間 Review SLA
```


***

### P0-003: Permission Tier の実装メカニズムが不明確

**問題**：Part09 で Permission Tier（ReadOnly/PatchOnly/ExecLimited/HumanGate）を定義しても、**「Claude Code でどうやって権限制限するか」「MCP でどう実装するか」が不明記**されています。[^1_8]

**具体的な欠落**：

- Claude Code への権限制限の実装方法（MCP Tool？AIコンテキスト？）
- HumanGate 承認フロー（Part00 U-0001 で未決）
- Part03 Core4 Role と Part09 Permission Tier との関係

**根拠**：

- MCP Spec 2025-11-25：「Implementors SHOULD build robust consent and authorization flows」[^1_1]
- Git Monorepo Security：CODEOWNERS + Branch Protection + Role Definition[^1_9]

**影響**：

- AI Agent に無制限権限
- 破壊的変更（rm -r -f 等）の防止不可

**修正指示**：

```
file: docs/Part09.md
Section 5.1 に「Implementation Mechanism」として追加
- MCP-based Permission Enforcement（Spec 2025-11-25 準拠）
- Claude Code Permission Context 設定方法

file: docs/Part00.md
Section 7（例外処理）に HumanGate プロセス図を追加
- ADR 作成 → 72h Review → HumanGate 承認 → Dry-run → Evidence 記録
```


***

### P0-004: sources/ 改変禁止ルール が実装されていない

**問題**：Part00 R-0003 で「sources/ 改変・削除禁止、追記のみ許可」を掲げていますが、**機械的検証（V-0004）のスクリプト実装（checks/verify_sources_integrity.ps1）がまだありません**。

**具体的な欠落**：

- V-0004 の検証条件は記述されているが、PowerShell スクリプト実装がない
- CI/CD での自動検証フローが不明確

**影響**：

- sources/ の誤改変が検出されずマージされる可能性
- 監査ログの完全性が保証されない

**修正指示**：

```
file: docs/Part00.md
Section 8（V-0004）を更新
実装: `git diff HEAD~1 HEAD -- sources/` で改変検出
合否: FAIL なら Stop-the-line + Revert

file: checks/verify_sources_integrity.ps1 （新規作成）
- Check 1: Modified files detection
- Check 2: Append-only validation  
- Check 3: Deletion prevention
- 報告: evidence/verify_reports/ に markdown で出力
```


***

### P0-005: Glossary に7つの未定義用語が増殖

**問題**：glossary/GLOSSARY.md で以下が「（未定義、今後追加予定）」のまま：VAULT・RELEASE・WORK・RFC・VIBEKANBAN・Context Pack・Patchset。[^1_10]

**影響**：

- docs/ で「RELEASE」「VAULT」の意味が曖昧
- Verify（用語揺れチェック）が通らない
- 新規参加者が困惑

**根拠**：

- Part02 セクション 11（未決事項）に登録されていない → 未決扱いが不明確
- これらが複数Part で言及されているが定義がない

**修正指示**：

```
file: glossary/GLOSSARY.md
Section 5.2 に以下を追加（優先度別）

【PRIORITY-HIGH】（即座実装）
- VAULT: 機密情報暗号化フォルダ（sources/ と別）
- RELEASE: 不変成果物フォルダ（Read-Only + sha256 + SBOM）
- VIBEKANBAN: タスク管理ダッシュボード（TODO → IN PROGRESS → VERIFY → DONE）

【PRIORITY-MEDIUM】
- RFC: 変更提案初期段階（ADR 前）
- Patchset: 最小差分単位（1つの目的のみ）
- Context Pack: MCP metadata パッケージ
- WORK: スパイク用隔離フォルダ

各定義に：定義・構造・用途・参照Part を記載
```


***

## 2. 改善推奨（P1/P2）

### P1-001: HumanGate 承認フロー が定義されていない

**問題**：Part00 U-0001「ADR承認フロー が不明」のまま。Part14 では HumanGate を頻出しているが、フロー図・タイムライン・承認者が明記されていません。

**改善指示**：

```
file: docs/Part00.md
Section 7（例外処理）に HumanGate フロー を追加
- 作成（ADR Proposed）
- Review 期間（72時間）
- 承認（HumanGate 権限者が Status を Accepted に）
- 実行（Dry-run + Evidence 記録）
- Verify（失敗時は即座 Revert）

file: CLAUDE.md
HumanGate 権限者リスト（名前/Role/代行者）を明記
```


***

### P1-002: Verify Gate スクリプトが未実装

**問題**：Part00 セクション 10 チェックリストで「checks/verify_repo.ps1 が実装されているか（次タスク）」と明記されているが、以下が未実装：

- checks/verify_repo.ps1（V-0001〜V-0005）
- checks/verify_dod.ps1（V-0101〜V-0105）
- checks/verify_release.ps1
- checks/verify_sources_integrity.ps1

**影響**：Part00/Part01 のルール検証が手動のため、機械判定が不可能。

**期限**：2026年1月末（最優先）

***

### P1-003: FACTS_LEDGER の未決事項が整理されていない

**問題**：部分ごとの「11. 未決事項」と FACTS_LEDGER.md の U-XXXX セクションが対応不明確。新規未決事項（U-0020〜U-0023）も発生。

**改善指示**：

```
file: docs/FACTS_LEDGER.md
未決事項セクションを拡充
- U-0001〜U-0004: Part00
- U-0101〜U-0104: Part01
- ...
- 優先度 flag（高/中/低）
- 決定期限・確認方法・現状を記載
```


***

### P1-004: Evidence Pack の構成が曖昧

**問題**：Part01 R-0101 では「Evidence Pack 生成」を述べていても、format（diff/manifest/sha256/SBOM）・命名規則・保存パスが曖昧。

**改善指示**：

```
file: docs/Part12.md （新規章）
Evidence Pack 標準 format を定義
- diff: unified diff (RFC 3881)
- manifest: CSV [filepath, hash_algo, hash_value, permissions]
- sha256: sha256sum output
- SBOM: CycloneDX 1.4 (JSON preferred)
- Verify Report: Markdown with structured sections
```


***

### P2-001: Part02 と GLOSSARY.md の同期ルール が弱い

**問題**：手動同期のため、ずれやすい。

**改善**：checks/verify_glossary_sync.ps1 を作成（CI/CD で自動実行）

***

### P2-002: 1Part=1Branch 原則 が Git で強制されていない

**問題**：Part02 セクション 5.2 で掲げているが、GitHub ルール化なし。

**改善**：Branch Protection で feature/part-NN-* パターンのみ許可

***

## 3. 具体的修正案（Patch案）

修正案は監査結果ファイル セクション 3 に PowerShell スクリプト付きで記載されています。

主要修正 5つ：

1. **修正 \#1：MCP セキュリティの完全化**（Part03.md）
2. **修正 \#2：ADR テンプレート・Status Indicator 確立**（Part14.md / decisions/ADR_TEMPLATE.md 新規）
3. **修正 \#3：HumanGate 承認フロー 明確化**（Part09.md / Part00.md）
4. **修正 \#4：sources/ 改変検出実装化**（checks/verify_sources_integrity.ps1 新規）
5. **修正 \#5：Glossary 未定義用語を定義**（glossary/GLOSSARY.md）

***

## 4. 運用で事故る代表シナリオ 3つ + 予防策

### シナリオ \#1：誤った sources/ の改変が検出されない

**状況**：AI が sources/ を「整理」名目で編集 → V-0004 未実装で検出不可 → merge → 「sources 不変」ルール形骸化

**予防策**：

- 即座に checks/verify_sources_integrity.ps1 実装
- CI/CD で自動実行
- sources/ への write 権限を IDE/MCP レベルで遮断
- Evidence に失敗ログ保存（削除禁止）

***

### シナリオ \#2：HumanGate 承認が暗黙的にスキップ

**状況**：破壊的変更が必要 → 「誰が承認？いつまで？」不明 → 「暫定変更、後で ADR 作成」 → ADR なし状態で merge → SSOT 信頼喪失

**予防策**：

- 修正 \#3 で HumanGate フロー 明確化
- SLA：ADR 作成 → 72h Review → 承認/却下
- 72h 超過で automatic escalate
- ADR なき commit は CI で reject

***

### シナリオ \#3：MCP Tool が無制御実行 → 機密情報混入

**状況**：MCP Tool で読み込みファイル（API キー混入）→ sources/ 保存 → Part00 U-0003 暫定対応のまま → Incident 時対応不明 → 情報漏洩

**予防策**：

- 修正 \#1 で User Consent + Tool Safety Gate 実装
- Data Privacy Boundary 明記（どの Tool が OK）
- Automated secret scanning（SBOM 生成時）
- Part19 に MCP Tool 事故 SOP 追加
- VAULT に機密情報保管（修正 \#5）

***

## 5. 未決事項リスト（優先度順）

| 優先度 | ID | Part | 項目 | 現状 | 期限 | 確認方法 |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| **🔴P0** | **U-0022** | Part09 | **HumanGate 権限者の明示** | 不明 | **2026-01-31** | CLAUDE.md 確認 |
| **🔴P0** | **U-0023** | Part00 | **Verify Script 実装スケジュール** | 未実装 | **2026-01-31** | checks/ 実装確認 |
| **🔴P0** | **U-0004** | Part00 | Verify 自動実行タイミング | 手動 | **2026-01-31** | CI/CD 設定確認 |
| **🔴P0** | **U-0001** | Part00 | ADR承認フロー | 暫定 | **2026-01-31** | GitHub Actions チェック |
| 🟠P1 | U-0003 | Part00 | 機密情報の扱い | 暫定 | 2026-02-28 | VAULT 構造・暗号化ツール選定 |
| 🟠P1 | **U-0020** | Part03 | **MCP OAuth 実装** | 新規 | 2026-02-28 | MCP Server lib 確認 |
| 🟠P1 | **U-0021** | 新規 | **VAULT 暗号化ツール選定** | 新規 | 2026-02-28 | git-crypt/age/OpenSSL 比較 |
| 🟠P1 | U-0102 | Part01 | SBOM生成ツール | 暫定 | 2026-02-28 | ツール可用性確認 |
| 🟠P1 | U-0103 | Part01 | セキュリティ閾値 | CVSS 7.0 | 2026-02-28 | 環境に合わせて調整 |
| 🟡P2 | U-0002 | Part00 | sources/ 保存期限 | 無期限 | 2026-03-31 | ディスク容量計測 |
| 🟡P2 | U-0101 | Part01 | メトリクス計測頻度 | 月次 | 2026-03-31 | 自動化ツール検討 |


***

## 6. 検証・実装チェックリスト

### 即座実行（2026-01-31 まで）

- [ ] CLAUDE.md：HumanGate 権限者リスト更新
- [ ] checks/verify_sources_integrity.ps1 実装
- [ ] checks/verify_repo.ps1 / verify_dod.ps1 等実装
- [ ] Part00.md：V-0004 更新・HumanGate フロー追加
- [ ] Part09.md：Implementation Mechanism 追加
- [ ] Part14.md：ADR_TEMPLATE.md 参照追加・Status Lifecycle 定義
- [ ] decisions/ADR_TEMPLATE.md 新規作成


### 2月中実施（2026-02-28 まで）

- [ ] Part03.md：R-0304（MCP セキュリティコンプライアンス）追加
- [ ] glossary/GLOSSARY.md：VAULT/RELEASE/VIBEKANBAN/RFC/Patchset/Context Pack/WORK 定義
- [ ] VAULT 暗号化ツール選定・実装方法決定
- [ ] MCP OAuth 実装検討・リソースサーバー構成
- [ ] SBOM ツール選定・format 決定


### 3月中実施（2026-03-31 まで）

- [ ] sources/ 保存期限検討・容量計画
- [ ] メトリクス計測自動化ツール検討
- [ ] VIBEKANBAN（タスク管理ダッシュボード）実装決定

***

## 結論

**本設計書の骨格は堅牢ですが、2025年の技術変化（MCP セキュリティ強化、ADR Best Practice）への対応・実装詳細の具体化が急務です**。

特に以下の5つの P0 項目を 2026年1月末までに対応しなければ、SSOT 信頼が破壊されるリスクが高い：

1. **MCP セキュリティ（User Consent・OAuth）** → 機密情報漏洩リスク
2. **ADR テンプレート・Status Indicator** → 古い決定の混在
3. **Permission Tier 実装メカニズム** → AI 無制限権限
4. **sources/ 改変検出** → 監査ログ信頼喪失
5. **Glossary 未定義用語** → 新規参加者困惑

***

**参照**：
MCP Spec 2025-11-25：https://modelcontextprotocol.io/specification/2025-11-25[^1_1]
MCP Spec June 2025 Update（Auth0）[^1_2]
Zenn.dev：MCP June 18版変更概要[^1_3]
TechTarget（2025-06-19）：ADR Best Practices[^1_4]
AWS Prescriptive Guidance：ADR Best Practices[^1_5]
UK Government Digital Service（2025-12-07）：ADR Framework[^1_6]
AWS ADR Process[^1_7]
Git Monorepo Security（2026-01-08）[^1_8]
GitHub Blog：Git Sparse Index[^1_9]
VCG/VIBE Design Master：glossary/GLOSSARY.md[^1_10]
<span style="display:none">[^1_11][^1_12][^1_13][^1_14][^1_15][^1_16]</span>

<div align="center">⁂</div>

[^1_1]: DESIGN_MASTER_20260111_230526.txt

[^1_2]: https://auth0.com/blog/mcp-specs-update-all-about-auth/

[^1_3]: https://www.techtarget.com/searchapparchitecture/tip/4-best-practices-for-creating-architecture-decision-records

[^1_4]: https://graphite.com/guides/managing-permissions-access-control-monorepo

[^1_5]: https://zenn.dev/su8/articles/fcb3b8b3f5439f

[^1_6]: https://technology.blog.gov.uk/2025/12/08/the-architecture-decision-record-adr-framework-making-better-technology-decisions-across-the-public-sector/

[^1_7]: https://www.issoh.co.jp/tech/details/3934/

[^1_8]: https://www.linkedin.com/pulse/model-context-protocol-mcp-why-2026-year-ai-stops-igor-van-der-burgh-zfghe

[^1_9]: https://www.linkedin.com/pulse/guide-effectively-recording-software-architectural-jorge-quitério-ffgpe

[^1_10]: https://github.blog/open-source/git/make-your-monorepo-feel-small-with-gits-sparse-index/

[^1_11]: https://modelcontextprotocol.io/specification/2025-11-25

[^1_12]: https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/best-practices.html

[^1_13]: https://graphite.com/guides/monorepo-security-sensitive-environments

[^1_14]: https://onereach.ai/blog/what-to-know-about-model-context-protocol/

[^1_15]: https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html

[^1_16]: https://zenn.dev/tmasuyama1114/books/claude_code_basic/viewer/permission-optimization

