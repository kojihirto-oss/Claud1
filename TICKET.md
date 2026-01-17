# TICKET

## Purpose
- Repo hygiene: keep large generated files out of git; keep docs/ and checks/ light.

## Tasks
- Create WORK/ and supporting notes.
- Inventory files > 50MB.
- Propose/execute A/B handling for large files.
- Add 50MB size check to verify_repo.
- Run Fast Verify and record results.
- Commit and push.

## Notes
- Update this file with actions/results.

## Actions
- Created WORK/ and README; added WORK temp paths to .gitignore.
- Generated WORK/large-files.txt (>50MB inventory).
- Converted evidence/research_import/keyword_hits_20260115_084346.md to Git LFS.
- Added 50MB size check to checks/verify_repo.ps1.

## Results
- Fast Verify: PASS (warnings: Part28.md, Part29.md absolute path).
