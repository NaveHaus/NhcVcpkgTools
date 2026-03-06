## ADDED Requirements

### Requirement: PowerShell version requirements are compatible with module assembly
The minimum supported PowerShell version for `NhcVcpkgTools` SHALL be enforced via the module manifest and/or the module header script used by ModuleBuilder.

Individual function scripts under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private` MUST NOT contain `#Requires -Version 7.4` directives.

#### Scenario: Built module imports without per-function #Requires
- **WHEN** the module is built via Sampler/ModuleBuilder and imported in PowerShell 7.4+
- **THEN** the module imports successfully and exposes the expected commands

#### Scenario: Function files do not declare #Requires -Version
- **WHEN** unit tests validate source scripts under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`
- **THEN** no file contains a `#Requires -Version` directive
