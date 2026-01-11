# Part02 用語集（単一の正）

> この用語集が「表記」と「意味」の唯一の正です。本文は必ずこれに従う。

## 用語（追加していく）

- **SSOT (Single Source of Truth):**
  A single, authoritative reference point for a specific piece of data or documentation, ensuring consistency and preventing conflicts from multiple versions. In this project, docs/ serves as the SSOT for all specification content.
  _参照: [Atlassian - Building SSOT](https://www.atlassian.com/work-management/knowledge-sharing/documentation/building-a-single-source-of-truth-ssot-for-your-team) - accessed 2026-01-11_

- **VAULT:**
  An immutable artifact repository that stores verified, released versions of code, binaries, or documentation. Once written to VAULT, artifacts cannot be modified or deleted, ensuring auditability and reproducibility across environments.
  _参照: [JFrog - Immutable Artifacts](https://jfrog.com/blog/5-special-repositories-in-artifactory-you-should-know-about/) - accessed 2026-01-11_
  _未決事項: VAULT folder structure and access control rules (to be defined in Part04)_

- **RELEASE:**
  An immutable, versioned snapshot of deliverables (code, binaries, manifests, SBOM) accompanied by provenance attestations. Conforms to SLSA framework requirements for supply chain integrity and verifiable build processes.
  _参照: [SLSA - Provenance](https://slsa.dev/provenance) - accessed 2026-01-11_
  _未決事項: Release manifest format and SBOM structure (to be defined in Part13)_

- **WORK:**
  A temporary workspace directory where agents and developers perform modifications during development. Changes in WORK/ must pass Verify Gates before promotion to VAULT/ or RELEASE/. Provides isolation between concurrent builds and tasks.
  _参照: [IT Journey - work/ Directory CI/CD Integration](https://it-journey.dev/posts/work-directory-ci-cd-integration/) - accessed 2026-01-11_
  _未決事項: WORK directory cleanup policy and retention rules (to be defined in Part04)_

- **DoD (Definition of Done):**
  A formal checklist of criteria that must be satisfied before a work item (ticket, feature, release) is considered complete. Includes code review, tests passing, documentation updated, and compliance checks. Differs from Acceptance Criteria in that DoD applies to all work items universally.
  _参照: [Scrum.org - Definition of Done vs Acceptance Criteria](https://www.scrum.org/resources/blog/what-difference-between-definition-done-and-acceptance-criteria) - accessed 2026-01-11_
  _未決事項: Project-specific DoD checklist items (to be defined in Part01, Part10)_

- **ADR (Architecture Decision Record):**
  A document capturing an important architectural decision, its context, alternatives considered, and consequences. Stored in decisions/ folder with sequential numbering (ADR-0001, ADR-0002...) following Michael Nygard's template format.
  _参照: [ADR GitHub - Templates](https://adr.github.io/) - accessed 2026-01-11_

- **Permission Tier:**
  A security boundary model defining what file operations and commands are allowed for AI agents at different trust levels (e.g., ReadOnly, PatchOnly, ExecLimited, HumanGate). Prevents accidental SSOT corruption and enforces least-privilege access control for autonomous agents.
  _参照: [Oso - AI Agent Permissions](https://www.osohq.com/learn/ai-agent-permissions-delegated-access) - accessed 2026-01-11_
  _未決事項: Specific tier definitions and enforcement mechanisms (to be defined in Part09)_

- **Verify Gate:**
  A checkpoint in the development workflow where automated tests, linters, and compliance checks must pass before proceeding. Typically implemented in two modes: Fast (1-3 min for lint/format/unit tests) and Full (10-30 min for comprehensive validation including integration tests and security scans). Supports shift-left testing approach.
  _参照: [SonarSource - Quality Gates](https://www.sonarsource.com/resources/library/quality-gate/) - accessed 2026-01-11_
  _未決事項: Fast vs Full criteria, G1-G5 gate hierarchy (to be defined in Part10)_

- **Evidence Pack:**
  A bundle of audit artifacts (logs, test results, SBOM, provenance attestations, verification reports) generated during Verify and Release cycles. Enables post-hoc investigation, compliance audits, and supply chain transparency. May include RUNLOG.jsonl, VERIFY_REPORT.md, and SLSA attestations.
  _参照: [SLSA - Attestation Model](https://slsa.dev/spec/v1.0/provenance) - accessed 2026-01-11_
  _未決事項: Evidence Pack structure and retention policy (to be defined in Part12)_

- **Patchset:**
  A logical grouping of code changes (commits, diffs) that implement a single feature or fix. In Gerrit-style workflows, each iteration of a commit (after code review feedback) creates a new patchset associated with the same Change-ID. Treated as atomic unit for review and merge.
  _参照: [Gerrit - Patch Sets Concept](https://gerrit-review.googlesource.com/Documentation/concept-patch-sets.html) - accessed 2026-01-11_

- **RFC (Request for Comments):**
  A proposal document for significant changes that require team review and consensus before implementation. Follows structured format (problem, solution, alternatives, impact) to collect feedback. Origin: IETF standards process, adapted for internal technical decision-making.
  _参照: [IETF - About RFCs](https://www.ietf.org/process/rfcs/) - accessed 2026-01-11_
  _未決事項: Project RFC template and approval workflow (to be defined in Part14)_

- **VIBEKANBAN:**
  VCG/VIBE project's state machine-based task management system. Tracks tickets through states (e.g., Inbox → Ready → InProgress → Verify → Done) with automated state transitions and evidence capture at each gate.
  _参照: [Internal](../sources/生データ/) - VCG/VIBE project-specific implementation_
  _未決事項: State transition rules and automation triggers (to be defined in Part03)_

- **Context Pack:**
  A curated bundle of project information (specs, conventions, recent changes, relevant code excerpts) optimized for AI context windows. Minimizes token usage while providing necessary context for accurate agent responses. Related to context engineering techniques for LLM optimization.
  _参照: [Anthropic - Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) - accessed 2026-01-11_
  _未決事項: Context Pack generation rules and inclusion criteria (to be defined in Part08)_
