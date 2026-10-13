## Purpose

Define how the module names and exports its **port cmdlets**: singular-noun **canonical command names**, plus **legacy aliases** that keep pre-rename plural-noun scripts working.

## ADDED Requirements

### Requirement: Port cmdlets are exported under canonical command names
The module SHALL export each **port cmdlet** as a function under its singular-noun **canonical command name**: `Install-NhcVcpkgPort`, `Export-NhcVcpkgPort`, and `Remove-NhcVcpkgPort`. The module SHALL NOT export functions under the plural-noun names.

#### Scenario: Canonical names are discoverable as functions
- **GIVEN** the NhcVcpkgTools module is imported
- **WHEN** command discovery is performed for `Install-NhcVcpkgPort`, `Export-NhcVcpkgPort`, and `Remove-NhcVcpkgPort` in the NhcVcpkgTools module
- **THEN** each name is reported as a function from the NhcVcpkgTools module

#### Scenario: Plural names are not exported as functions
- **GIVEN** the NhcVcpkgTools module is imported
- **WHEN** the module's exported functions are listed
- **THEN** none of `Install-NhcVcpkgPorts`, `Export-NhcVcpkgPorts`, or `Remove-NhcVcpkgPorts` appears among them

### Requirement: Legacy aliases resolve to canonical command names
The module SHALL export a **legacy alias** for each **port cmdlet**, and each **legacy alias** SHALL resolve to its **canonical command name**: `Install-NhcVcpkgPorts` to `Install-NhcVcpkgPort`, `Export-NhcVcpkgPorts` to `Export-NhcVcpkgPort`, and `Remove-NhcVcpkgPorts` to `Remove-NhcVcpkgPort`.

#### Scenario: Legacy aliases are discoverable and resolve to canonical names
- **GIVEN** the NhcVcpkgTools module is imported
- **WHEN** command discovery is performed for `Install-NhcVcpkgPorts`, `Export-NhcVcpkgPorts`, and `Remove-NhcVcpkgPorts`
- **THEN** each name is reported as an alias
- **AND** each alias resolves to the matching **canonical command name**

### Requirement: Invoking a legacy alias is equivalent to invoking the canonical command
Invoking a **port cmdlet** through its **legacy alias** SHALL accept the same parameters and produce the same behavior and **result object** as invoking it through its **canonical command name**.

#### Scenario: Existing script using a legacy alias keeps working
- **GIVEN** a script that calls `Remove-NhcVcpkgPorts -Ports 'zlib' -WhatIf`
- **WHEN** the script runs with the current module imported
- **THEN** the call binds the same parameters as `Remove-NhcVcpkgPort -Ports 'zlib' -WhatIf`
- **AND** it returns a **result object** with the same entries as the canonical call
