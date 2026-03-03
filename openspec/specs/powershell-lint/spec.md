# Capability: powershell-lint

## Purpose
Define expectations for the repository PowerShell lint runner, including scope, configuration, output, and failure behavior.

## Requirements

### Requirement: Lint runner analyzes only module, test, and tools sources
The repository lint runner SHALL analyze PowerShell files located under `NhcVcpkgTools/`, `tests/`, and `tools/` and SHALL NOT analyze files outside those directories.

#### Scenario: Default scope includes only NhcVcpkgTools, tests, and tools
- **WHEN** `tools/lint.ps1` is run with default parameters
- **THEN** it analyzes `NhcVcpkgTools/**/*.ps1`, `NhcVcpkgTools/**/*.psm1`, `NhcVcpkgTools/**/*.psd1`, `tests/**/*.ps1`, and `tools/**/*.ps1`
- **AND THEN** it ignores files in all other directories, such as `openspec/`, `.opencode/`, or `.git/`

### Requirement: Lint runner uses an explicit settings file with default rules enabled
The lint runner SHALL use `PSScriptAnalyzerSettings.psd1` from the repository root by default, and that settings file SHALL have default rules enabled.

#### Scenario: Default settings path is used
- **WHEN** `tools/lint.ps1` is run without specifying a settings path
- **THEN** the ScriptAnalyzer invocation uses `./PSScriptAnalyzerSettings.psd1`

### Requirement: Lint runner supports local and GitHub output modes
The lint runner SHALL support a `local` mode and a `github` mode.

In `github` mode, the runner SHALL emit GitHub Actions annotations using workflow-command syntax and SHALL format the annotation message compactly as `[{RuleName}] {Message}`.

In `local` mode, the runner SHALL emit a human-readable report that includes at least: severity, rule name, message, and location (file + line).

#### Scenario: GitHub mode produces compact annotations
- **WHEN** the lint runner is executed in `github` mode and ScriptAnalyzer returns one warning diagnostic
- **THEN** the runner emits a `::warning` annotation line containing the diagnostic file path, line/column (when available), and a message formatted as `[{RuleName}] {Message}`

#### Scenario: Local mode produces rich output
- **WHEN** the lint runner is executed in `local` mode and ScriptAnalyzer returns one diagnostic
- **THEN** the runner output includes the diagnostic severity, rule name, message, and file location

### Requirement: Lint runner fails the build on any warnings or errors
The lint runner SHALL exit with status code `0` when there are no ScriptAnalyzer diagnostics with severity `Warning` or `Error`, and SHALL exit with a non-zero status code when at least one such diagnostic exists.

#### Scenario: Warnings cause failure
- **WHEN** ScriptAnalyzer reports one or more diagnostics with severity `Warning` and no diagnostics with severity `Error`
- **THEN** the lint runner exits with a non-zero status code

#### Scenario: No findings succeed
- **WHEN** ScriptAnalyzer reports no diagnostics with severity `Warning` or `Error`
- **THEN** the lint runner exits with status code `0`

### Requirement: GitHub annotations use repository-relative paths when possible
When emitting GitHub Actions annotations, the lint runner SHALL use file paths relative to the repository root when the diagnostic path is within the repository checkout.

#### Scenario: Absolute paths within the repo are normalized
- **WHEN** ScriptAnalyzer returns a diagnostic with an absolute file path under the repository root
- **THEN** the emitted GitHub annotation uses the corresponding repository-relative path
