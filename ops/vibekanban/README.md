# ops/vibekanban

VIBEKANBAN operation templates for AI parallel work and RAG operations.

## How to use templates

- Pick one template from `ops/vibekanban/task_templates/` that matches the task type.
- Copy the template into your task card or task file and fill every placeholder.
- Assign roles:
  - Supervisor LLM uses `prompts/supervisor_llm.md`
  - Implement LLM uses `prompts/implement_llm.md`
  - Audit LLM uses `prompts/audit_llm.md`
- Build or update RAG with the scripts under `scripts/` before execution.
- Record a change summary in `evidence/changes/YYYYMMDD_task_codex.md`.

## Work rules (must)

- 1 task = 1 branch / 1 worktree / 1 verify / 1 evidence
- Use dry-run modes before any real run.
- Do not edit `checks/verify_repo.ps1`.

## Example flow

1) Create a branch and a worktree for the task.
2) Fill a task template and run RAG build or update.
3) Execute implementation, then run verify.
4) Write evidence summary for the task.

## Evidence note

Store only the change summary under `evidence/changes/`.
Do not use `evidence/changes_summary.md` for new work.
