[FAIL] forbidden_patterns: Found 4 detection(s)
Timestamp: 2026-01-16 22:45:26

[FORBIDDEN] docs\Part09.md:194 -> Pattern: 'rm\s+-rf'
  Line: input.command == "rm -rf"
[FORBIDDEN] docs\Part09.md:200 -> Pattern: 'git\s+push\s+--force'
  Line: input.command == "git push --force"
