# VCG/VIBE 2026 S評価到達ガイド

**目標**: 個人開発でトップクラスの精度・効率を実現する運用体制の構築

---

## S評価の定義

| ランク | 基準 |
|--------|------|
| B+ (現状) | 堅実な基盤、逐次実行、手動オーケストレーション |
| A | 並列実行、自動化されたVerify、コスト最適化 |
| S | **マルチエージェント協調、自己修復、予測的品質保証** |

---

## S評価に必要な5つの革新

### 革新1: マルチエージェントオーケストレーション

現状の問題: Core4を「人間が手動で切り替え」ている

**S評価の構成**:

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (人間)                       │
│                  ↓ 指示: チケット投入                         │
├─────────────────────────────────────────────────────────────┤
│                 CONDUCTOR AGENT (GPT)                        │
│        役割: タスク分解 → エージェント割当 → 結果統合          │
├──────────┬──────────┬──────────┬──────────────────────────────┤
│ RESEARCH │ ARCHITECT│  CODER   │   REVIEWER                  │
│  Agent   │  Agent   │  Agent   │    Agent                    │
│ (Gemini) │  (GPT)   │ (Claude) │   (GPT)                     │
│          │          │  (GLM)   │                             │
└──────────┴──────────┴──────────┴──────────────────────────────┘
```

**具体実装**:

```yaml
# agent_orchestra.yaml - マルチエージェント定義

conductor:
  model: gpt-4o
  role: |
    あなたはソフトウェア開発のコンダクター。
    チケットを受け取り、以下のエージェントに適切にタスクを割り当てる。
    各エージェントの出力を統合し、品質を担保する。
  
agents:
  research:
    model: gemini-3-pro
    tools: [web_search, deep_research]
    handoff_to: [architect]
    
  architect:
    model: gpt-4o
    tools: [spec_generator, risk_analyzer]
    handoff_to: [coder]
    
  coder:
    primary: claude-opus-4.5
    fallback: glm-4.7
    tools: [code_write, test_write, git]
    handoff_to: [reviewer]
    
  reviewer:
    model: gpt-4o
    tools: [security_scan, code_review, verify]
    handoff_to: [conductor]  # 結果報告

orchestration_patterns:
  - pattern: sequential  # TRIAGE → SPEC → BUILD → VERIFY
    use_when: "依存関係が強いタスク"
  
  - pattern: parallel    # 複数チケット同時処理
    use_when: "独立したタスク"
    max_concurrent: 4
  
  - pattern: hierarchical  # CONDUCTORが動的に判断
    use_when: "複雑な判断が必要"
```

---

### 革新2: Plan-and-Execute パターン（コスト90%削減）

現状の問題: 全工程でClaude/GPTを使い、コスト効率が悪い

**S評価の構成**:

```
┌────────────────────────────────────────────────────────┐
│  PLANNER (高コストモデル: 1回だけ使用)                   │
│  - Claude Opus 4.5 / GPT-4o                            │
│  - 計画立案、アーキテクチャ決定、リスク評価              │
└────────────────────┬───────────────────────────────────┘
                     ↓ 計画書（plan.md）
┌────────────────────────────────────────────────────────┐
│  EXECUTOR (低コストモデル: 大量に使用)                   │
│  - GLM-4.7 / Claude Sonnet / Gemini Flash              │
│  - 計画に従った実装、テスト実行、ログ解析               │
└────────────────────┬───────────────────────────────────┘
                     ↓ 実行結果
┌────────────────────────────────────────────────────────┐
│  VALIDATOR (中コストモデル: 要所で使用)                  │
│  - GPT-4o / Claude Sonnet                              │
│  - 品質確認、計画との整合性チェック                     │
└────────────────────────────────────────────────────────┘
```

**コスト配分の目安**:

| フェーズ | モデル | 使用比率 | コスト比率 |
|----------|--------|----------|------------|
| PLAN | Opus/GPT-4o | 5% | 30% |
| EXECUTE | GLM-4.7/Sonnet | 80% | 40% |
| VALIDATE | GPT-4o | 15% | 30% |

**実装例（BUILDプロンプト）**:

```markdown
## PLAN PHASE (Claude Opus 4.5 - 1回のみ)

SPEC.mdを読み、実装計画を作成せよ。
出力形式:
```json
{
  "tasks": [
    {
      "id": "T1",
      "description": "認証モジュールの実装",
      "files": ["src/auth.ts", "src/auth.test.ts"],
      "dependencies": [],
      "executor_prompt": "... (GLM用の具体的な指示)"
    },
    ...
  ],
  "execution_order": ["T1", "T2", "T3"],
  "validation_checkpoints": ["T2完了後", "全タスク完了後"]
}
```

## EXECUTE PHASE (GLM-4.7 - タスク毎に実行)

計画書のタスク{task_id}を実行せよ。
指示: {executor_prompt}
制約: 計画から逸脱するな。不明点は停止して報告。

## VALIDATE PHASE (GPT-4o - チェックポイント毎)

以下を検証:
1. 実装が計画と一致しているか
2. テストがパスするか
3. セキュリティ問題がないか
不合格の場合、具体的な修正指示を出力。
```

---

### 革新3: 自己修復ループ（Human-on-the-Loop）

現状の問題: エラー発生時に毎回人間が介入

**S評価の構成**:

```
                    ┌─────────────────┐
                    │   BUILD/VERIFY   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   結果判定        │
                    │  Green? Red?     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
        │   Green   │  │ Red (軽微) │  │ Red (重大) │
        │  → 次工程  │  │ → 自動修復 │  │ → 人間通知 │
        └───────────┘  └─────┬─────┘  └───────────┘
                             │
                    ┌────────▼────────┐
                    │  REPAIR Agent    │
                    │  (Claude/GLM)    │
                    │  最大3回試行     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  再VERIFY        │
                    │  Green → 次工程  │
                    │  3回失敗 → 人間  │
                    └─────────────────┘
```

**エラー分類と自動対応ルール**:

```yaml
# error_classification.yaml

auto_repair:  # 自動修復対象
  - type: "構文エラー"
    action: "Claude Codeで即修正"
    max_retries: 3
    
  - type: "型エラー"
    action: "エラーメッセージを基に修正"
    max_retries: 3
    
  - type: "テスト失敗（単体）"
    action: "失敗テストのみ修正"
    max_retries: 3
    
  - type: "リント警告"
    action: "自動フォーマット適用"
    max_retries: 1
    
  - type: "依存関係エラー"
    action: "バージョン調整"
    max_retries: 2

human_required:  # 人間介入必須
  - type: "セキュリティ脆弱性（CVSS 7.0+）"
    action: "即座に通知、修正案を提示"
    
  - type: "設計変更が必要"
    action: "SPEC見直しを提案"
    
  - type: "3回連続失敗"
    action: "診断レポート生成→人間判断"
    
  - type: "外部API障害"
    action: "モック切替を提案"

escalation_flow:
  1: "同一エラー2回 → モデル切替（GLM→Claude）"
  2: "同一エラー3回 → 人間通知 + 詳細ログ"
  3: "5回以上 → タスク中断 + 根本原因分析"
```

---

### 革新4: 予測的品質保証（Shift-Left）

現状の問題: VERIFYで初めて問題が発覚

**S評価の構成**:

```
従来: SPEC → BUILD → (問題発覚) → REPAIR → VERIFY

S評価: SPEC → PRE-CHECK → BUILD（段階検証）→ VERIFY（確認のみ）
              ↑
         問題を事前に潰す
```

**PRE-CHECK（BUILD前の品質ゲート）**:

```yaml
# pre_check.yaml - BUILD前の自動検証

checks:
  - name: "SPEC整合性"
    tool: gpt-4o
    prompt: |
      SPEC.mdを分析し、以下を検証:
      1. 曖昧な表現がないか
      2. 受入基準が機械判定可能か
      3. 非目的と目的に矛盾がないか
      4. 依存関係が明示されているか
    fail_action: "SPEC修正を要求"
    
  - name: "影響範囲分析"
    tool: claude-opus
    prompt: |
      SPEC.mdの変更が既存コードに与える影響を分析:
      1. 変更が必要なファイル一覧
      2. 破壊的変更の有無
      3. 既存テストへの影響
    fail_action: "リスク評価レポート生成"
    
  - name: "類似バグ検索"
    tool: rag_search
    query: "SPEC.mdの機能に関連する過去のバグ/失敗"
    fail_action: "過去の学びを注入"
    
  - name: "依存関係チェック"
    tool: npm_audit / pip_audit
    fail_action: "脆弱性レポート→人間判断"
```

**段階検証（BUILD中の継続的チェック）**:

```yaml
# staged_verification.yaml

stages:
  - name: "ファイル作成後"
    checks:
      - lint
      - type_check
    fail_action: "即座に修正"
    
  - name: "関数実装後"
    checks:
      - unit_test
      - complexity_check  # 循環的複雑度 < 10
    fail_action: "リファクタ指示"
    
  - name: "モジュール完成後"
    checks:
      - integration_test
      - security_scan
    fail_action: "修正 or 人間判断"
    
  - name: "全実装完了後"
    checks:
      - e2e_test
      - performance_test
      - full_security_audit
    fail_action: "VERIFY移行 or REPAIR"
```

---

### 革新5: 分散トレーシングと観測可能性

現状の問題: 問題発生時に「どこで何が起きたか」が追えない

**S評価の構成**:

```
┌─────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  TRACING (OpenTelemetry)                                    │
│  - 各エージェントの呼出しを追跡                              │
│  - タスク開始→完了の全経路を記録                            │
│  - レイテンシ/トークン消費をスパン単位で計測                │
├─────────────────────────────────────────────────────────────┤
│  METRICS                                                     │
│  - 成功率 / 失敗率 / REPAIR回数                             │
│  - モデル別コスト / レイテンシ                              │
│  - チケット完了時間の分布                                   │
├─────────────────────────────────────────────────────────────┤
│  LOGGING                                                     │
│  - 全プロンプト/レスポンスの記録                            │
│  - エラースタックトレース                                   │
│  - 判断根拠の保存                                           │
├─────────────────────────────────────────────────────────────┤
│  ALERTING                                                    │
│  - 3回連続失敗 → Slack通知                                  │
│  - コスト閾値超過 → 警告                                    │
│  - セキュリティ検出 → 即時通知                              │
└─────────────────────────────────────────────────────────────┘
```

**実装例（簡易トレーシング）**:

```python
# trace_logger.py - 簡易トレーシング実装

import json
from datetime import datetime
from pathlib import Path

class TaskTracer:
    def __init__(self, ticket_id: str):
        self.ticket_id = ticket_id
        self.trace_id = f"{ticket_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.spans = []
        
    def start_span(self, name: str, agent: str, model: str):
        span = {
            "span_id": f"{self.trace_id}_{len(self.spans)}",
            "name": name,
            "agent": agent,
            "model": model,
            "start_time": datetime.now().isoformat(),
            "input_tokens": 0,
            "output_tokens": 0,
            "status": "running"
        }
        self.spans.append(span)
        return span
        
    def end_span(self, span, status: str, tokens: dict, result: str = None):
        span["end_time"] = datetime.now().isoformat()
        span["status"] = status  # success / failure / timeout
        span["input_tokens"] = tokens.get("input", 0)
        span["output_tokens"] = tokens.get("output", 0)
        span["result_summary"] = result[:500] if result else None
        
    def save_trace(self):
        trace_file = Path(f"VAULT/traces/{self.trace_id}.json")
        trace_file.parent.mkdir(parents=True, exist_ok=True)
        
        trace_data = {
            "trace_id": self.trace_id,
            "ticket_id": self.ticket_id,
            "spans": self.spans,
            "total_tokens": sum(s["input_tokens"] + s["output_tokens"] for s in self.spans),
            "total_duration_ms": self._calc_duration()
        }
        
        with open(trace_file, "w") as f:
            json.dump(trace_data, f, indent=2, ensure_ascii=False)
            
    def _calc_duration(self):
        if not self.spans:
            return 0
        start = datetime.fromisoformat(self.spans[0]["start_time"])
        end = datetime.fromisoformat(self.spans[-1].get("end_time", self.spans[-1]["start_time"]))
        return (end - start).total_seconds() * 1000
```

**ダッシュボード指標**:

```markdown
# Daily Dashboard

## 本日のサマリ
- 完了チケット: 12
- 成功率: 83% (10/12)
- 平均完了時間: 47分
- 総トークン消費: 1.2M
- 推定コスト: $18.50

## モデル別使用量
| Model | Calls | Tokens | Cost | Avg Latency |
|-------|-------|--------|------|-------------|
| Claude Opus | 24 | 180K | $9.00 | 8.2s |
| GPT-4o | 36 | 220K | $4.40 | 3.1s |
| GLM-4.7 | 89 | 800K | $4.00 | 1.8s |
| Gemini Flash | 15 | 50K | $1.10 | 1.2s |

## 失敗分析
| Error Type | Count | Auto-Fixed | Human-Required |
|------------|-------|------------|----------------|
| Type Error | 8 | 8 | 0 |
| Test Fail | 5 | 4 | 1 |
| Security | 2 | 0 | 2 |

## 改善推奨
1. テスト失敗の1件はSPECの曖昧さが原因 → テンプレート改善
2. Security検出の2件は依存関係 → 自動アップデート検討
```

---

## S評価チェックリスト

### アーキテクチャ
- [ ] マルチエージェントオーケストレーション導入
- [ ] Plan-and-Execute パターン適用
- [ ] Human-on-the-Loop 自己修復ループ
- [ ] 分散トレーシング実装

### 品質保証
- [ ] PRE-CHECK（BUILD前品質ゲート）
- [ ] 段階検証（BUILD中継続チェック）
- [ ] 類似バグRAG検索
- [ ] 予測的リスク分析

### コスト最適化
- [ ] モデル階層化（Frontier/Mid/Small）
- [ ] キャッシュ戦略
- [ ] トークン消費モニタリング
- [ ] コスト閾値アラート

### 観測可能性
- [ ] 全タスクのトレース記録
- [ ] リアルタイムダッシュボード
- [ ] 失敗パターン分析
- [ ] 週次レトロスペクティブ自動生成

### 自動化
- [ ] エラー自動分類
- [ ] 軽微エラーの自動修復
- [ ] フェイルオーバー（モデル切替）
- [ ] 定期バックアップ

---

## 実装ロードマップ

### Week 1: 基盤整備
1. トレーシング基盤の実装
2. エラー分類ルールの定義
3. PRE-CHECKの最初の3項目

### Week 2: オーケストレーション
4. Conductor Agent プロトタイプ
5. Plan-and-Execute の検証
6. 自己修復ループの実装

### Week 3: 品質保証
7. 段階検証の組込み
8. 類似バグRAGの構築
9. セキュリティゲートの強化

### Week 4: 観測可能性
10. ダッシュボードの構築
11. アラート設定
12. 週次レポート自動生成

---

## 現ドキュメントへの統合方法

### 追加セクション

```markdown
## 15. マルチエージェントオーケストレーション
（上記の革新1を統合）

## 16. コスト最適化アーキテクチャ
（上記の革新2を統合）

## 17. 自己修復ループ
（上記の革新3を統合）

## 18. 予測的品質保証
（上記の革新4を統合）

## 19. 観測可能性
（上記の革新5を統合）
```

### 既存セクションの改訂

| セクション | 現状 | S評価版 |
|------------|------|---------|
| 3. 役割分担 | 手動切替 | Conductorベース自動割当 |
| 6. VIBEKANBAN | 逐次実行 | 並列+自己修復 |
| 7. ガードレール | 事後防御 | 予測的防御 |
| 9. コスト | 方針のみ | モデル階層化+モニタリング |

---

## 結論

**B+ → S の差分**:

| 観点 | B+ | S |
|------|-----|-----|
| エージェント管理 | 人間が手動切替 | Conductor自動オーケストレーション |
| エラー対応 | 人間介入必須 | 自己修復 + 人間はon-the-loop |
| 品質保証 | VERIFY時に発覚 | PRE-CHECK + 段階検証で事前排除 |
| コスト | 意識はあるが未最適化 | Plan-and-Execute で90%削減可能 |
| 観測 | ログのみ | 分散トレーシング + ダッシュボード |

S評価は「**AIが自律的に動き、人間は監督と例外対応に集中する**」状態。
現ドキュメントの堅実な基盤の上に、5つの革新を追加することで到達可能。
