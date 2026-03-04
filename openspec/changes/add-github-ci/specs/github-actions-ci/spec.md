## ADDED Requirements

### Requirement: CI workflow runs on pushes and pull requests
The repository SHALL include a GitHub Actions workflow that runs on `push` and `pull_request` events.

#### Scenario: Workflow triggers for PRs
- **WHEN** a pull request is opened or updated
- **THEN** the CI workflow runs

#### Scenario: Workflow triggers for pushes
- **WHEN** a commit is pushed to a branch in the repository
- **THEN** the CI workflow runs

### Requirement: CI workflow runs on Windows
The CI workflow SHALL run on the `windows-latest` GitHub-hosted runner.

#### Scenario: Runner selection is windows-latest
- **WHEN** the workflow job definition is evaluated
- **THEN** it selects `runs-on: windows-latest`

### Requirement: CI runs PSScriptAnalyzer lint and fails on warnings and errors
The CI workflow SHALL run PSScriptAnalyzer over `NhcVcpkgTools/` and `tests/` and SHALL fail if any warnings or errors are reported.

Lint findings SHALL be emitted as GitHub Actions annotations.

#### Scenario: Lint failures fail the workflow
- **WHEN** ScriptAnalyzer reports one or more warnings or errors
- **THEN** the workflow run is marked as failed

### Requirement: CI runs Pester tests and publishes an NUnit XML artifact
The CI workflow SHALL run Pester unit tests discovered under `tests/` and SHALL produce an NUnit XML test results file that is uploaded as a workflow artifact.

#### Scenario: Test results artifact is uploaded
- **WHEN** Pester completes (pass or fail)
- **THEN** the workflow uploads an artifact containing the NUnit XML results file

### Requirement: CI ensures required PowerShell tooling is available
The CI workflow SHALL ensure Pester v5+ and PSScriptAnalyzer are available before running tests and lint.

#### Scenario: Tool installation precedes execution
- **WHEN** the workflow starts
- **THEN** it installs or otherwise provides Pester v5+ and PSScriptAnalyzer before invoking lint or tests
