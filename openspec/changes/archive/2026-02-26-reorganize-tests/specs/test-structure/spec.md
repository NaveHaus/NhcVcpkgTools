## ADDED Requirements

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
