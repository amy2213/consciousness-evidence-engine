# Consciousness Evidence Engine Project State

PROJECT: Consciousness Evidence Engine
CURRENT VERSION: Foundation v0.1 on main; v1.1.1 migration in draft PR #5
CURRENT BRANCH: main
LAST VERIFIED COMMIT: 2bf32bd3a72a87257bc04af9834524c9f5518b39
CURRENT PHASE: Parked pending v1.1.1 migration reconciliation and merge-readiness audit
AUTHORITATIVE ARTIFACT: Canonical main plus source-locked Claim Ledger v1.1.1; durable external artifact preservation remains open

## Working
- Canonical GitHub main remains the Foundation v0.1 line.
- Draft PR #5 contains the advanced v1.1.1 migration.
- PR #5 head observed during portfolio QA: `7a2b0f848c2ce50343c5fc31375532a0c86ea370`.
- Database-integrity run 245 passed on the migration branch.

## Known issues
- PR #5 is draft and unmerged.
- Green branch CI does not establish merge readiness.
- DAT-14 through DAT-19 remain the controlling migration, audit, extension, and publication gates.
- Durable artifact preservation is not yet established in the portfolio artifact layer.

## Blockers
- The migration cannot become canonical until source-lock reconciliation, independent merge-readiness review, and remaining v1.1.1 gates are complete.

## Last test results
- Database-integrity run 245: green on the migration branch.
- Main remains the canonical authority until PR #5 is explicitly approved and merged.
- This control-file commit does not constitute a fresh scientific or merge-readiness QA pass.

## Next action
When the project leaves Parked state, complete the source-locked v1.1.1 migration in PR #5 and run the independent merge-readiness audit before any merge or release-state change.

## Source-of-truth rules
- Notion: project state, research authority, decisions
- Linear: migration and publication gates
- GitHub: source, PRs, tests, CI, releases
- Google Drive / ChatGPT Library: durable research artifacts and preserved handoff packages
