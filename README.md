# vibe-spec-ssot

このリポジトリは **仕様・運用のSSOT（Single Source of Truth）** を管理するためのものです。  
「迷わない導線」「更新時に事故らない」を最優先に設計しています。

## Start Here
- まずは **docs/README.md**（導線の説明）
- 次に **docs/00_INDEX.md**（全体INDEX）

## Structure
- docs/ : SSOT（仕様/運用）
- decisions/ : ADR（意思決定ログ）
- glossary/ : 用語の唯一定義
- sources/ : 根拠（原文・ログ・スクショ）
- checks/ : 検証手順

## Update Rules (Minimum)
1. 仕様/運用変更 → 先に decisions/ にADRを書く
2. 用語追加 → glossary/ に追加
3. 根拠追加 → sources/ に保存
4. 導線維持 → docs/00_INDEX.md を壊さない
