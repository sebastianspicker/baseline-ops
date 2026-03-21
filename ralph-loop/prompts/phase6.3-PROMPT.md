# Phase 6.3 — Summary and Handoff Report

You are creating the final summary report for the Ralph Loop improvement cycle.

## Task

1. Read all progress files in `ralph-loop/phase*/`.
2. Read `CHANGELOG.md` for the complete change record.
3. Read `git log --oneline --since` for the period covering all phases.
4. Create `ralph-loop/SUMMARY.md` with:
   - **Executive Summary**: 2-3 sentences on what was accomplished.
   - **Metrics**:
     - Security findings fixed (count, severity breakdown).
     - Static analysis issues resolved.
     - Convention violations fixed (count of scripts aligned).
     - Tests added (count, modules now covered).
     - Lines of code changed/removed/added.
     - Total Ralph Loop iterations consumed.
   - **Remaining Work**: Items intentionally deferred with justification.
   - **Recommendations**: Suggestions for future improvement cycles.
   - **Risk Items**: Anything that needs human review before production use.
5. Commit the summary.

## Exit Condition
Output `<promise>SUMMARY_COMPLETE</promise>` when the summary report is committed.
