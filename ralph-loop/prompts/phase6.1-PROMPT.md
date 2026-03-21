# Phase 6.1 — CI Pipeline Improvements

You are enhancing the GitHub Actions CI pipeline.

## Task

1. In `.github/workflows/ci.yml`:
   a. Add test coverage artifact upload: after Pester runs, upload the `TestResults.xml` as a GitHub Actions artifact.
   b. Add a job summary step that reports test count and pass/fail in the GitHub Actions UI.
   c. Consider adding a `lint-markdown` job for README/CHANGELOG validation (optional — defer if too complex).
   d. Verify the `test-smoke-linux` job is still useful and tests meaningful paths.
   e. Add `--failOnStderr` or equivalent if PSScriptAnalyzer supports it.
2. In `.github/workflows/scorecard.yml`:
   - Verify pin hashes are current for all actions used.
   - Check if any new best practices should be applied.
3. Pin rules:
   - ALL GitHub Actions must use full SHA pins (not tags).
   - Verify existing pins in ci.yml and scorecard.yml match the claimed version tags.
4. After changes, verify CI definition is valid YAML.
5. Commit changes.

## What NOT to Touch
- Source scripts.
- Test files.
- lib/ modules.

## Verification
- YAML files are valid (no parse errors).
- Action SHA pins are verifiable.
- No changes to source code or tests.

## Exit Condition
Output `<promise>CI_IMPROVEMENTS_COMPLETE</promise>` when CI pipeline is enhanced and all YAML is valid.
