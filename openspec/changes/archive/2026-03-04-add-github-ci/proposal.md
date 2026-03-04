## Why

The repo currently relies on manual test execution. Adding GitHub Actions for lint and tests makes regressions visible on every PR and standardizes the quality gate for contributions.

## What Changes

- Add a GitHub Actions workflow that runs on `pull_request` and `push`.
- Run on `windows-latest` (aligned with the current test suite’s Windows-oriented assumptions).
- Execute PowerShell linting via PSScriptAnalyzer and fail the check on any warnings or errors.
  - Prefer invoking `tools/lint.ps1 -Mode github` (from the `add-linter` change) to keep policy centralized.
- Execute unit tests via Pester (`Invoke-Pester -Path tests`) and publish an NUnit XML test results artifact.

## Capabilities

### New Capabilities
- `github-actions-ci`: A CI capability that defines when CI runs, what it executes (lint + Pester), how results are reported (annotations + test results artifact), and the required runner OS.

### Modified Capabilities

## Impact

- Adds `.github/workflows/*` and introduces CI as a merge-quality signal.
- Establishes Windows as the initial CI target; expanding to other OS runners would require making tests/lint assumptions platform-aware.
- Adds dependency management for Pester/PSScriptAnalyzer within CI.
