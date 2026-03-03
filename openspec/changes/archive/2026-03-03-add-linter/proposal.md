## Why

Today the repo has tests but no codified linting policy. Adding a standard ScriptAnalyzer runner makes style and common PowerShell issues visible early (locally and in CI) and reduces review churn.

## What Changes

- Add a repo command `tools/lint.ps1` that runs PSScriptAnalyzer over `NhcVcpkgTools/`, `tests/`, and `tools/`.
- Support two output modes:
  - `local`: richer, developer-friendly console output.
  - `github`: compact GitHub Actions annotations (`::warning`/`::error`) suitable for PR review.
- Fail the lint command when any warnings or errors are present (strict gate; can be relaxed later if too noisy).
- Add a `PSScriptAnalyzerSettings.psd1` file (defaults enabled) so the lint policy is explicit and versionable.

## Capabilities

### New Capabilities
- `powershell-lint`: A repository linting capability that defines what files are analyzed, which ScriptAnalyzer settings apply, what output modes exist, and what exit codes represent.

### Modified Capabilities

## Impact

- Adds a new developer workflow entrypoint (`tools/lint.ps1`) used both locally and by automation.
- Introduces PSScriptAnalyzer as a required tool for contributors/CI.
- May initially surface warnings in existing code/tests; the change will need a clear policy on fixing vs suppressing findings.
