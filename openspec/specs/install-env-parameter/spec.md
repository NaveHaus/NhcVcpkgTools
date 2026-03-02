# Capability: install-env-parameter

## Purpose
Provide explicit, per-invocation environment variables for the `vcpkg` process launched by `Install-NhcVcpkgPorts`, avoiding mutation of the caller’s PowerShell environment.

## Requirements

### Requirement: Install passes a process-scoped environment overlay
When `Install-NhcVcpkgPorts` is invoked with `Env` and/or `KeepEnvVars`, the function SHALL pass a hashtable to `Start-Process -Environment` that represents an overlay for the spawned `vcpkg` process and SHALL NOT mutate the caller’s `$env:`.

#### Scenario: Env entries are passed to Start-Process
- **WHEN** `Install-NhcVcpkgPorts` is invoked with `Env = @{ FOO = 'bar' }` and `Start-Process` is mocked
- **THEN** the mocked `Start-Process` call receives `-Environment` containing key `FOO` with value `bar`

#### Scenario: Env supports unsetting variables via $null
- **WHEN** `Install-NhcVcpkgPorts` is invoked with `Env = @{ FOO = $null }` and `Start-Process` is mocked
- **THEN** the mocked `Start-Process` call receives `-Environment` containing key `FOO` with value `$null`

#### Scenario: Caller environment is not mutated
- **WHEN** a test sets `$env:FOO = 'original'` and invokes `Install-NhcVcpkgPorts` with `Env = @{ FOO = 'child' }`
- **THEN** after invocation the caller’s `$env:FOO` remains `original`

### Requirement: KeepEnvVars sets VCPKG_KEEP_ENV_VARS using semicolons
When `Install-NhcVcpkgPorts` is invoked with `KeepEnvVars`, the function SHALL set `VCPKG_KEEP_ENV_VARS` in the child process environment to the `KeepEnvVars` entries joined by `;`.

#### Scenario: KeepEnvVars joins entries with semicolons
- **WHEN** `Install-NhcVcpkgPorts` is invoked with `KeepEnvVars = @('A','B')` and `Start-Process` is mocked
- **THEN** the mocked `Start-Process` call receives `-Environment` where `VCPKG_KEEP_ENV_VARS` is `A;B`

### Requirement: KeepEnvVars overrides Env VCPKG_KEEP_ENV_VARS
If both `Env` and `KeepEnvVars` are provided and `Env` contains `VCPKG_KEEP_ENV_VARS`, the function SHALL use the `KeepEnvVars`-derived value for `VCPKG_KEEP_ENV_VARS` in the child process environment.

#### Scenario: KeepEnvVars takes precedence over Env
- **WHEN** `Install-NhcVcpkgPorts` is invoked with `Env = @{ VCPKG_KEEP_ENV_VARS = 'X;Y' }` and `KeepEnvVars = @('A','B')` and `Start-Process` is mocked
- **THEN** the mocked `Start-Process` call receives `-Environment` where `VCPKG_KEEP_ENV_VARS` is `A;B`

### Requirement: KeepEnvVars preserves entries exactly
`Install-NhcVcpkgPorts` SHALL preserve `KeepEnvVars` entries exactly as provided when constructing `VCPKG_KEEP_ENV_VARS` and SHALL NOT trim whitespace or deduplicate entries.

#### Scenario: KeepEnvVars does not trim or deduplicate
- **WHEN** `Install-NhcVcpkgPorts` is invoked with `KeepEnvVars = @(' A','A','B ')` and `Start-Process` is mocked
- **THEN** the mocked `Start-Process` call receives `-Environment` where `VCPKG_KEEP_ENV_VARS` is ` A;A;B `

### Requirement: Module declares and documents PowerShell 7.4+ dependency
The module SHALL require PowerShell 7.4+ to support process-scoped environment passing and SHALL document this requirement.

#### Scenario: Module manifest requires PowerShell 7.4+
- **WHEN** the module manifest is inspected
- **THEN** the manifest `PowerShellVersion` is `7.4` or higher

#### Scenario: README lists PowerShell 7.4+ under Requirements
- **WHEN** the README is inspected
- **THEN** the Requirements section mentions PowerShell 7.4+