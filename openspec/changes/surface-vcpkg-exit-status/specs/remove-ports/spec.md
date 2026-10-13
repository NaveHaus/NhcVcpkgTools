## REMOVED Requirements

### Requirement: Quiet switch suppresses vcpkg output
**Reason**: It stated that `-Quiet` suppresses all vcpkg output, including stdout and stderr, which does not match the module: `-Quiet` changes neither vcpkg's console output, the error records written, nor `Status`. It also carried three argument pass-through scenarios that belong to "Common vcpkg arguments are supported".
**Migration**: Replaced by "Quiet switch changes neither output nor Status" and the `vcpkg-exit-status` capability. The three pass-through scenarios already appear under "Common vcpkg arguments are supported".

## MODIFIED Requirements

### Requirement: vcpkg errors are passed through

The function SHALL NOT perform custom error handling or translation. When vcpkg reports an error:
- The error message from vcpkg SHALL be visible to the user on the console
- The function SHALL NOT re-emit vcpkg's error message as a PowerShell error record
- The function SHALL return `Status = $false`
- The function SHALL NOT throw exceptions for vcpkg operational errors

#### Scenario: vcpkg error message is visible
- **WHEN** vcpkg returns an error (e.g., port not installed, dependencies prevent removal)
- **THEN** the error message from vcpkg is displayed on the console
- **AND** no PowerShell error record is written for that message
- **AND** the function returns `Status = $false`

#### Scenario: Dependency conflict without Recurse
- **GIVEN** an installed port that other installed ports depend on
- **WHEN** `Remove-NhcVcpkgPort -Ports '<that port>'` is invoked without `-Recurse` and vcpkg refuses the removal with a non-zero exit code
- **THEN** the function returns `Status = $false`
- **BUT** no exception is thrown

## ADDED Requirements

### Requirement: Quiet switch changes neither output nor Status

The function SHALL accept a `-Quiet` switch parameter with the semantics defined by the `vcpkg-exit-status` capability: it SHALL NOT suppress vcpkg's own console output and SHALL NOT change `Status`, and a launch failure writes no error records whether or not it is specified.

#### Scenario: Quiet mode with a launch failure writes no error records
- **GIVEN** the vcpkg command cannot be started
- **WHEN** `Remove-NhcVcpkgPort -Ports 'zlib' -Quiet` is invoked
- **THEN** no error records are written to the PowerShell error stream
- **AND** the function still returns the result hashtable with `Status = $false`

#### Scenario: Quiet mode does not hide vcpkg console output
- **GIVEN** vcpkg starts and writes output to the console
- **WHEN** `Remove-NhcVcpkgPort -Ports 'zlib' -Quiet` is invoked
- **THEN** vcpkg's output still appears on the console
- **AND** `Status` reflects the vcpkg exit status

#### Scenario: Without Quiet mode, output is displayed
- **WHEN** `Remove-NhcVcpkgPort -Ports 'zlib'` is invoked without `-Quiet`
- **THEN** output from vcpkg is displayed to the console
