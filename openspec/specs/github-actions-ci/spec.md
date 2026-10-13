# github-actions-ci Specification

## Purpose

Define the repository's continuous integration contract: when CI runs, which checks it performs, on which runner operating systems, what makes a run fail, and which results it publishes.

## Requirements

### Requirement: CI runs for pull requests targeting master
The repository SHALL run its CI workflow for every pull request whose base branch is `master`, each time the pull request is opened or updated.

#### Scenario: Pull request to master starts CI
- **GIVEN** a pull request whose base branch is `master`
- **WHEN** the pull request is opened or new commits are pushed to it
- **THEN** the CI workflow runs against the pull request

#### Scenario: Pull request to another branch does not start CI
- **GIVEN** a pull request whose base branch is not `master`
- **WHEN** the pull request is opened or updated
- **THEN** the CI workflow does not run for that pull request

### Requirement: CI runs for tag pushes
The repository SHALL run its CI workflow each time a tag is pushed, and SHALL NOT run it for a push to a branch alone; branch commits are covered by the pull-request trigger.

#### Scenario: Tag push starts CI
- **GIVEN** a commit in the repository
- **WHEN** a tag pointing to it is pushed
- **THEN** the CI workflow runs against the tagged commit

#### Scenario: Branch push does not start CI
- **GIVEN** a branch with no open pull request to `master`
- **WHEN** new commits are pushed to the branch
- **THEN** the CI workflow does not run for that push

### Requirement: CI fails when any check fails
The CI workflow SHALL consist of independent checks (source-mode test, build-and-test, and lint; workflow jobs `import-and-test`, `build-and-test`, and `lint`), and a CI run SHALL be marked failed when any one of them fails.

#### Scenario: One failing check fails the run
- **GIVEN** a CI run in which the lint check fails
- **AND** the source-mode test and build-and-test checks pass
- **WHEN** the run completes
- **THEN** the CI run is marked failed

#### Scenario: All checks pass
- **GIVEN** a CI run in which every check passes
- **WHEN** the run completes
- **THEN** the CI run is marked successful

### Requirement: CI tests the module imported from source on Windows
The CI workflow SHALL, on a Windows runner, import the module from the source tree without building it and run the Pester tests under `tests/` excluding the QA tests. The check SHALL fail if the import fails or any test fails, and SHALL publish the test results as an NUnit XML workflow artifact whether or not the tests pass.

#### Scenario: Source-mode import failure fails the check
- **GIVEN** a commit whose module cannot be imported from the source tree
- **WHEN** the source-mode test check runs
- **THEN** the check fails

#### Scenario: Failing unit test fails the check
- **GIVEN** a commit with a failing unit test under `tests/`
- **WHEN** the source-mode test check runs
- **THEN** the check fails
- **AND** the NUnit XML test results are published as a workflow artifact

#### Scenario: QA tests are excluded from the source-mode check
- **GIVEN** a commit with a QA test under `tests/QA`
- **WHEN** the source-mode test check runs
- **THEN** the QA test is not executed by this check

### Requirement: CI builds the module and runs the full test suite on Windows
The CI workflow SHALL, on a Windows runner, resolve build dependencies, build the module, and run the full test suite, including the QA tests, against the **built module** using the repository build script. The check SHALL fail if dependency resolution, the build, or any test fails, and SHALL publish the NUnit XML test results as a workflow artifact.

#### Scenario: Build failure fails the check
- **GIVEN** a commit whose module fails to build
- **WHEN** the build-and-test check runs
- **THEN** the check fails

#### Scenario: Failing QA test fails the check
- **GIVEN** a commit that builds successfully but fails a QA test
- **WHEN** the build-and-test check runs
- **THEN** the check fails

#### Scenario: Passing build publishes test results
- **GIVEN** a commit that builds and passes every test
- **WHEN** the build-and-test check runs
- **THEN** the check passes
- **AND** the NUnit XML test results are published as a workflow artifact

### Requirement: CI lints PowerShell sources on Linux
The CI workflow SHALL, on a Linux runner, run the repository lint runner in GitHub annotation mode over the PowerShell sources it covers. The check SHALL fail when any finding has Warning or Error severity, SHALL report findings as GitHub Actions annotations, and SHALL make PSScriptAnalyzer available itself rather than relying on the runner image to provide it.

#### Scenario: Warning finding fails the lint check
- **GIVEN** a commit with a PowerShell source file that produces a Warning-severity PSScriptAnalyzer finding
- **WHEN** the lint check runs
- **THEN** the check fails
- **AND** the finding is reported as a GitHub Actions annotation

#### Scenario: Information-only findings do not fail the lint check
- **GIVEN** a commit whose only PSScriptAnalyzer findings have Information severity
- **WHEN** the lint check runs
- **THEN** the check passes

#### Scenario: Runner without PSScriptAnalyzer
- **GIVEN** a Linux runner image that does not provide PSScriptAnalyzer
- **WHEN** the lint check runs
- **THEN** PSScriptAnalyzer is made available before linting starts
- **AND** the check result reflects the lint findings rather than a missing-module error
