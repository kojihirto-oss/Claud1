# Docs Entry

この docs/ は 仕様・運用のSSOT（Single Source of Truth） を置く場所です。
最初に読む人が迷わないこと、更新時に事故らないことを最優先にしています。

## 読む順番（推奨）
1. 00_INDEX.md（全体導線）
2. Part00.md（前提・目的）
3. Part01.md → Part30.md（順に）

## このリポ内の役割分担
- SSOT（仕様/運用）: docs/
- Decisions（意思決定）: decisions/（ADR）
- Glossary（用語の唯一定義）: glossary/
- Sources / Evidence（根拠・原文）: sources/
- Checks（検証手順）: checks/

## 更新ルール（最低限）
- 仕様/運用を変えるときは まずADR（decisions/）で決定を書く
- 用語が増えたら GLOSSARY に追加して揺れを防ぐ
- 根拠（原文/スクショ/ログ）は sources/ に残す
- 00_INDEX.md の導線が壊れないようにする
