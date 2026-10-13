# Module internal dependency loading

## Purpose
Define how internal dependencies between module functions are resolved to support Sampler/ModuleBuilder packaging.

## Requirements

### Requirement: Module import provides internal dependencies
Functions in `NhcVcpkgTools/Public/*.ps1` and `NhcVcpkgTools/Private/*.ps1` SHALL rely on module import (Sampler/ModuleBuilder assembly) to provide internal command dependencies and MUST NOT dot-source other module scripts at function invocation time.

#### Scenario: Public function resolves private helper from imported module
- **WHEN** a public function calls a private helper during a test run against imported `NhcVcpkgTools`
- **THEN** the helper is available through module scope without any runtime dot-sourcing statement in the public function script

#### Scenario: Function scripts avoid runtime dot-sourcing
- **WHEN** function scripts under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private` are validated by tests
- **THEN** tests confirm there are no active runtime dot-sourcing statements used to load sibling module scripts

#### Scenario: Private helpers are callable only from module scope
- **WHEN** tests need to call a private helper
- **THEN** they do so from within `InModuleScope 'NhcVcpkgTools'` after importing the module (not by dot-sourcing the private helper script)

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
