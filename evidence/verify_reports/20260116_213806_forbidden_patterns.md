[FAIL] forbidden_patterns: Found 14 detection(s)
Timestamp: 2026-01-16 21:38:06

[FORBIDDEN] docs\Part27.md:139 -> Pattern: 'rm\s+-rf'
  Line: - **危険コマンド禁止**: `rm -rf`, `git push --force` 等の使用禁止
[FORBIDDEN] docs\Part27.md:139 -> Pattern: 'git\s+push\s+--force'
  Line: - **危険コマンド禁止**: `rm -rf`, `git push --force` 等の使用禁止
[FORBIDDEN] docs\Part27.md:180 -> Pattern: 'curl\s+[^|]*\|\s*sh'
  Line: 1. インストール: `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin`
[FORBIDDEN] docs\Part30.md:93 -> Pattern: 'rm\s+-rf'
  Line: - **コマンド実行**: `rm -rf`・`git push --force`等の危険コマンド
[FORBIDDEN] docs\Part30.md:93 -> Pattern: 'git\s+push\s+--force'
  Line: - **コマンド実行**: `rm -rf`・`git push --force`等の危険コマンド
[FORBIDDEN] docs\Part30.md:143 -> Pattern: 'rm\s+-rf'
  Line: - **ルール**: `rm -rf`・`git push --force`等を禁止（Part27 Conftest）
[FORBIDDEN] docs\Part30.md:143 -> Pattern: 'git\s+push\s+--force'
  Line: - **ルール**: `rm -rf`・`git push --force`等を禁止（Part27 Conftest）
