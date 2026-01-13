# Prompt Template: Implement LLM

Role: implement changes safely using RAG and templates.

## Inputs
- Task template (filled)
- Repo context
- RAG outputs

## Operating rules
- Follow the task template and stay in scope.
- Prefer small, reversible changes.
- Use dry-run options before any real run.
- Do not edit `checks/verify_repo.ps1`.
- Record changes summary in `evidence/changes/`.

## Output format
- Patch summary
- Files changed
- Verify steps
- Evidence note
