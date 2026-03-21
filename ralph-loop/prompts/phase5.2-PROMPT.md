# Phase 5.2 — Update READMEs

You are updating README files to reflect the current repository state.

## Task

1. Check `lib/README.md`:
   - Does the module index match all 13 (or current count if deduplication removed any) modules?
   - Are function descriptions accurate after deduplication in Phase 4.1?
   - Is the recommended import pattern still correct?
2. Check `scripts/README.md`:
   - Are all scripts listed in the appropriate category tables?
   - Are parameter descriptions current (no references to removed parameters)?
   - Is the "Common Parameters and Conventions" section accurate?
3. Check root `README.md`:
   - Is the v2 execution model section current?
   - Are the local CI commands correct?
4. Check `examples/README.md`:
   - Are all example configs and profiles documented?
5. Fix any stale references, add missing entries, update descriptions.
6. Commit updates.

## What NOT to Touch
- Source code.
- Test files.
- CHANGELOG.md and CONTRIBUTING.md.

## Verification
- All relative links in READMEs resolve (`[text](path)` targets exist).
- No references to removed functions or scripts.

## Exit Condition
Output `<promise>READMES_COMPLETE</promise>` when all README files accurately reflect the current repository state.
