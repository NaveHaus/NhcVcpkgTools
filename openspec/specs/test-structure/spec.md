# Test structure

## Purpose
Document the repository conventions for organizing module scripts and tests so we can keep behavior clear as the suite grows.

## Requirements

### Requirement: Source folders use Public and Private casing
The repository SHALL store module scripts under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`, and the module loader SHALL dot-source from those paths.

#### Scenario: Module loader uses capitalized folders
- **WHEN** the module is imported from the repository root
- **THEN** it dot-sources scripts from `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`

### Requirement: Tests are organized by function visibility
Test files SHALL reside under `tests/Public` for public functions and `tests/Private` for private functions, and filenames SHALL remain `*.Tests.ps1`.

#### Scenario: Pester discovers public and private tests
- **WHEN** Pester is run with `Invoke-Pester -Path tests`
- **THEN** it discovers tests from `tests/Public` and `tests/Private` using `*.Tests.ps1` filenames

### Requirement: Integration test folder exists
The repository SHALL include a `tests/Integration` directory with a `.gitkeep` placeholder to reserve the location for future integration tests.

#### Scenario: Integration folder placeholder is present
- **WHEN** the repository tree is inspected
- **THEN** `tests/Integration/.gitkeep` exists

### Requirement: Each module function lives in a source file named after it
Every function the module defines SHALL be defined in its own file named `<FunctionName>.ps1`, under `NhcVcpkgTools/Public` for exported functions and `NhcVcpkgTools/Private` for functions that are not exported. Each such file SHALL define exactly one function. Module-level scripts that define no function, such as the module header script, are exempt.

#### Scenario: Private helper has its own file
- **GIVEN** a private helper function `Get-Example` used by another module function
- **WHEN** the source tree is inspected
- **THEN** `Get-Example` is defined in `NhcVcpkgTools/Private/Get-Example.ps1`
- **BUT** it is not defined inside another function's source file

#### Scenario: Public function has its own file
- **GIVEN** the exported function `Remove-NhcVcpkgPort`
- **WHEN** the source tree is inspected
- **THEN** it is defined in `NhcVcpkgTools/Public/Remove-NhcVcpkgPort.ps1`
- **AND** that file defines no other function

### Requirement: Each module function has a same-named unit test file
Every function the module defines, public or private, SHALL have a unit test file named `<FunctionName>.Tests.ps1` in the test folder that matches its visibility (`tests/Public` or `tests/Private`). The QA suite SHALL fail for any module function that has no file with that name anywhere under `tests/`; the QA suite does not check which folder the file is in.

#### Scenario: Function with a matching test file passes the check
- **GIVEN** the private function `Test-EmptyDirectory` and the file `tests/Private/Test-EmptyDirectory.Tests.ps1`
- **WHEN** the QA suite runs
- **THEN** the unit-test-file check for `Test-EmptyDirectory` passes

#### Scenario: Function without a test file fails the QA suite
- **GIVEN** a newly added private function `Get-Example` with no file named `Get-Example.Tests.ps1` under `tests/`
- **WHEN** the QA suite runs
- **THEN** the QA suite reports a failure for `Get-Example`

#### Scenario: Misplaced test file is not caught by the QA suite
- **GIVEN** the private function `Get-Example` and a file `tests/Public/Get-Example.Tests.ps1`
- **WHEN** the QA suite runs
- **THEN** the unit-test-file check for `Get-Example` passes
- **BUT** the file violates the visibility-folder convention of this requirement

### Requirement: Each module function passes per-function quality checks
The QA suite SHALL apply the following checks to every function the module defines, public or private, and SHALL fail for any function that does not satisfy them:
- The function's source file produces no PSScriptAnalyzer findings, when PSScriptAnalyzer is available.
- The function's comment-based help has a non-empty synopsis.
- The function's comment-based help has a description longer than 40 characters.
- The function's comment-based help has at least one example; the first example mentions the function name and is more than 10 characters longer than the function name.
- Every declared parameter has a help description longer than 25 characters.

#### Scenario: Private function without a synopsis fails
- **GIVEN** a private function whose comment-based help has no synopsis
- **WHEN** the QA suite runs
- **THEN** the QA suite reports a failure for that function

#### Scenario: Example that only names the function fails
- **GIVEN** a function `Get-Example` whose first help example is just `Get-Example`
- **WHEN** the QA suite runs
- **THEN** the QA suite reports a failure for `Get-Example`

#### Scenario: Parameter with a short description fails
- **GIVEN** a function with a parameter whose help description is 25 characters or fewer
- **WHEN** the QA suite runs
- **THEN** the QA suite reports a failure for that function

#### Scenario: Analyzer finding in a function file fails
- **GIVEN** PSScriptAnalyzer is available
- **AND** a function's source file produces a PSScriptAnalyzer finding
- **WHEN** the QA suite runs
- **THEN** the QA suite reports a failure for that function

#### Scenario: Analyzer check is skipped when PSScriptAnalyzer is unavailable
- **GIVEN** PSScriptAnalyzer is not available in the session
- **WHEN** the QA suite runs
- **THEN** the analyzer check is skipped rather than failed
- **AND** the help checks still run
