## ADDED Requirements

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
