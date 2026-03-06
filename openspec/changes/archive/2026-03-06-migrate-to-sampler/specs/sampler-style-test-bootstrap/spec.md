## ADDED Requirements

### Requirement: Unit tests bootstrap and target imported module
Unit tests under `tests/Public` and `tests/Private` SHALL run against an imported `NhcVcpkgTools` module (built output), not by dot-sourcing function scripts from `NhcVcpkgTools/Public` or `NhcVcpkgTools/Private`.

All unit tests under `tests/Public` and `tests/Private` SHALL consume a *single shared* bootstrap script located under `tests/Shared/` rather than duplicating bootstrap logic per suite.

The shared bootstrap script SHALL:
- ensures a build exists (runs `./build.ps1 -Tasks noop` when the built module is not importable)
- imports `NhcVcpkgTools`
- sets module-scoped defaults:
  - `$PSDefaultParameterValues['Mock:ModuleName'] = 'NhcVcpkgTools'`
  - `$PSDefaultParameterValues['Should:ModuleName'] = 'NhcVcpkgTools'`
  - `$PSDefaultParameterValues['InModuleScope:ModuleName'] = 'NhcVcpkgTools'`

Each test file under `tests/Public` and `tests/Private` SHOULD dot-source the shared bootstrap script (directly or via suite-level `BeforeAll`) to guarantee module import and defaults are applied consistently.

#### Scenario: Test run bootstraps module before execution
- **WHEN** `Invoke-Pester -Path tests/Public` or `Invoke-Pester -Path tests/Private` runs in a clean repository workspace where `NhcVcpkgTools` is not importable
- **THEN** the suite bootstrap runs `./build.ps1 -Tasks noop`, imports `NhcVcpkgTools`, and proceeds without dot-sourcing any function scripts

#### Scenario: Test run uses existing import when present
- **WHEN** `NhcVcpkgTools` is already imported before tests start
- **THEN** the suite bootstrap does not require a rebuild and tests continue using the imported module

#### Scenario: Private tests execute within module scope
- **WHEN** a test under `tests/Private` validates an internal function
- **THEN** assertions and mocks within 'It' script blocks execute inside `InModuleScope -ScriptBlock` so private commands are resolved from the imported module

#### Scenario: Both supported entrypoints succeed
- **WHEN** unit tests are executed via `./build.ps1 -Tasks test`
- **THEN** the test run imports `NhcVcpkgTools` and unit tests execute with module-scoped defaults applied

### Requirement: Bootstrap helper functions are covered by unit tests
Any helper functions introduced to support suite bootstrap (for example, functions that ensure the built `NhcVcpkgTools` module is available/imported and/or apply module-scoped Pester defaults) SHALL have their own Pester tests.

These tests SHALL be written and exercised using a TDD red/green/refactor workflow as part of implementing this change.

#### Scenario: Helper ensures build and import when module is not importable
- **GIVEN** the helper is invoked in a workspace where `NhcVcpkgTools` cannot be imported
- **WHEN** the helper runs
- **THEN** it invokes `./build.ps1 -Tasks noop` and imports `NhcVcpkgTools`

#### Scenario: Helper is a no-op when module is already imported
- **GIVEN** `NhcVcpkgTools` is already imported
- **WHEN** the helper runs
- **THEN** it does not invoke `./build.ps1 -Tasks noop` and leaves the existing import in place

#### Scenario: Helper applies module-scoped Pester defaults
- **WHEN** the helper runs
- **THEN** `$PSDefaultParameterValues` contains module defaults for `Mock`, `Should`, and `InModuleScope` targeting `NhcVcpkgTools`
