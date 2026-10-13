## ADDED Requirements

### Requirement: Source-mode import provides every module function
A **source-mode import** of NhcVcpkgTools SHALL load every function defined under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private` into module scope, so that the functions available inside the module match those of the **built module**. A **source-mode import** SHALL export only the public functions, as the **built module** does.

#### Scenario: Newly added private helper is available after source-mode import
- **GIVEN** a private function defined in `NhcVcpkgTools/Private/<Name>.ps1`
- **WHEN** the module is imported from `NhcVcpkgTools/NhcVcpkgTools.psm1` in the source tree
- **THEN** the private function can be called from within the module's scope

#### Scenario: Public function that calls a private helper works after source-mode import
- **GIVEN** a source-mode import of the module
- **WHEN** a **port cmdlet** whose code path calls a private helper is invoked
- **THEN** the call does not fail because the helper is missing

#### Scenario: Private functions are not exported by source-mode import
- **GIVEN** a source-mode import of the module
- **WHEN** the module's exported commands are listed
- **THEN** only the public functions and their **legacy aliases** are exported
- **BUT** no private function is exported
