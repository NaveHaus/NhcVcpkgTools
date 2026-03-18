Related: #12
Related: #13

## ADDED Requirements

### Requirement: Remove-NhcVcpkgPorts function exists

The module SHALL export a public function named `Remove-NhcVcpkgPorts` that wraps the `vcpkg remove` command.

#### Scenario: Function is discoverable
- **WHEN** the NhcVcpkgTools module is imported
- **THEN** `Get-Command Remove-NhcVcpkgPorts -Module NhcVcpkgTools` returns the function

### Requirement: Mutually exclusive parameter sets for Ports and Outdated

The function SHALL define two mutually exclusive parameter sets:
- `Ports` parameter set: accepts a `-Ports` parameter (string array) for removing specific packages
- `Outdated` parameter set: accepts an `-Outdated` switch for removing stale packages

The function SHALL NOT allow both `-Ports` and `-Outdated` to be specified together.

Both `-Ports` and `-Outdated` SHALL be passed to `Get-CommonArguments` via the `$Parameters` hashtable for argument generation. `Get-CommonArguments` SHALL be extended to handle `-Outdated` by adding the `--outdated` flag to the arguments (it already handles `-Ports`).

#### Scenario: Remove specific ports using -Ports parameter
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib', 'fmt'` is invoked
- **THEN** `Get-CommonArguments` adds `zlib fmt --classic` to the arguments
- **AND** the function passes `remove zlib fmt --classic ...` to vcpkg

#### Scenario: Remove outdated ports using -Outdated switch
- **WHEN** `Remove-NhcVcpkgPorts -Outdated` is invoked
- **THEN** `Get-CommonArguments` adds `--outdated` to the arguments
- **AND** the function passes `remove --outdated ...` to vcpkg

#### Scenario: Reject both -Ports and -Outdated together
- **WHEN** a user attempts to invoke `Remove-NhcVcpkgPorts -Ports 'zlib' -Outdated`
- **THEN** PowerShell raises a parameter set ambiguity error before the function executes

#### Scenario: Empty Ports array is passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports @()` is invoked with an empty array
- **THEN** the function passes `remove` to vcpkg with no port arguments
- **AND** vcpkg handles the empty port list according to its own validation

#### Scenario: Invalid port name is passed through to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'nonexistent-port'` is invoked
- **THEN** the function passes `remove nonexistent-port` to vcpkg without validation
- **AND** vcpkg validates the port name and returns an appropriate error if invalid

### Requirement: Recurse switch enables dependent package removal

The function SHALL accept a `-Recurse` switch parameter that, when specified, allows removal of packages that depend on the specified packages.

The `-Recurse` parameter SHALL be passed to `Get-CommonArguments` via the `$Parameters` hashtable for argument generation. `Get-CommonArguments` SHALL be extended to handle `-Recurse` by adding the `--recurse` flag to the arguments.

#### Scenario: Remove with -Recurse flag
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Recurse` is invoked
- **THEN** `Get-CommonArguments` adds `--recurse` to the arguments
- **AND** the function passes `remove ... --recurse ...` to vcpkg

#### Scenario: Remove without -Recurse flag
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib'` is invoked without `-Recurse`
- **THEN** `Get-CommonArguments` does NOT add `--recurse` to the arguments

### Requirement: InstallDir parameter specifies the install root

The function SHALL accept an `-InstallDir` parameter that specifies where ports are installed. This parameter:
- SHALL default to `<vcpkg-root>/installed` when not specified
- SHALL be passed to vcpkg as `--x-install-root="<path>"`
- SHALL use the same semantics as `Export-NhcVcpkgPorts` (source location, not output)

#### Scenario: Custom InstallDir is passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -InstallDir 'C:\custom\installed'` is invoked
- **THEN** the function includes `--x-install-root="C:\custom\installed"` in the arguments passed to vcpkg

#### Scenario: Default InstallDir uses vcpkg root
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -RootDir 'C:\vcpkg'` is invoked without `-InstallDir`
- **THEN** the function uses `<RootDir>/installed` as the default install root

### Requirement: Common vcpkg arguments are supported

The function SHALL accept and pass through common vcpkg arguments consistent with other NhcVcpkgTools functions:
- `-Command`: Path to vcpkg executable (optional, auto-detected from RootDir or VCPKG_ROOT)
- `-RootDir`: Path to vcpkg root directory (optional, auto-detected from Command or VCPKG_ROOT)
- `-Triplet`: Target triplet (optional, auto-detected from vcpkg defaults)
- `-OverlayPorts`: Array of overlay ports paths (optional)
- `-OverlayTriplets`: Array of overlay triplets paths (optional)

These arguments SHALL be handled by reusing the `Get-CommonArguments` private function with `$Directories = @('InstallDir')`.

### Requirement: Get-CommonArguments handles Outdated parameter

The `Get-CommonArguments` private function SHALL be extended to recognize the `Outdated` parameter in the `$Parameters` hashtable. When `Outdated` is present (truthy), it SHALL add `--outdated` to the generated arguments array.

#### Scenario: Get-CommonArguments generates --outdated flag
- **WHEN** `Get-CommonArguments` is called with `$Parameters` containing `Outdated = $true`
- **THEN** the returned `Arguments` array includes `--outdated`

#### Scenario: Get-CommonArguments omits --outdated when not specified
- **WHEN** `Get-CommonArguments` is called with `$Parameters` NOT containing `Outdated`
- **THEN** the returned `Arguments` array does NOT include `--outdated`

### Requirement: Get-CommonArguments handles Recurse parameter

The `Get-CommonArguments` private function SHALL be extended to recognize the `Recurse` parameter in the `$Parameters` hashtable. When `Recurse` is present (truthy), it SHALL add `--recurse` to the generated arguments array.

#### Scenario: Get-CommonArguments generates --recurse flag
- **WHEN** `Get-CommonArguments` is called with `$Parameters` containing `Recurse = $true`
- **THEN** the returned `Arguments` array includes `--recurse`

#### Scenario: Get-CommonArguments omits --recurse when not specified
- **WHEN** `Get-CommonArguments` is called with `$Parameters` NOT containing `Recurse`
- **THEN** the returned `Arguments` array does NOT include `--recurse`

### Requirement: Get-CommonArguments returns string paths

The `Get-CommonArguments` private function SHALL return all path values in the `$result` hashtable as strings by enclosing source variables in double quotes (e.g., `Path = "$PackageDir"`).

#### Scenario: Path values are returned as strings
- **WHEN** `Get-CommonArguments` is called and returns a result hashtable
- **THEN** all `Path` values under `ParentDir`, `DownloadDir`, `BuildDir`, `PackageDir`, and `InstallDir` are of type `[string]`
- **AND** `Command` and `RootDir` values are of type `[string]`

### Requirement: Quiet switch suppresses vcpkg output

The function SHALL accept a `-Quiet` switch parameter that, when specified, suppresses all output from the vcpkg command (including errors) by piping `Start-Process` output to `Out-Null`.

#### Scenario: Quiet mode suppresses output
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Quiet` is invoked
- **THEN** all output from vcpkg (stdout and stderr) is suppressed
- **AND** the function still returns the result hashtable with `Status` reflecting success or failure

#### Scenario: Without Quiet mode, output is displayed
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib'` is invoked without `-Quiet`
- **THEN** output from vcpkg is displayed to the console

#### Scenario: RootDir is passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -RootDir 'C:\vcpkg'` is invoked
- **THEN** the function includes `--vcpkg-root="C:\vcpkg"` in the arguments passed to vcpkg

#### Scenario: Triplet is passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Triplet 'x64-windows'` is invoked
- **THEN** the function includes `--triplet="x64-windows"` in the arguments passed to vcpkg

#### Scenario: OverlayPorts paths are passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -OverlayPorts 'C:\overlays\ports'` is invoked
- **THEN** the function includes `--overlay-ports="C:\overlays\ports"` in the arguments passed to vcpkg

### Requirement: ShouldProcess support via WhatIf and Confirm

The function SHALL support PowerShell's `ShouldProcess` pattern:
- SHALL declare `[CmdletBinding(SupportsShouldProcess)]`
- SHALL call `$PSCmdlet.ShouldProcess()` before executing vcpkg
- SHALL translate `-WhatIf` to vcpkg's `--dry-run` flag when `ShouldProcess()` returns `$false`
- SHALL execute vcpkg even when `-WhatIf` is specified (with `--dry-run` flag) to display what would be removed
- SHALL return the full hashtable with results from the dry-run execution

#### Scenario: WhatIf shows dry-run output and returns results
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -WhatIf` is invoked
- **THEN** `ShouldProcess()` returns `$false` and the function adds `--dry-run` to the arguments
- **AND** vcpkg is executed with `--dry-run` to display what would be removed
- **AND** the function returns a hashtable with `Command`, `Arguments`, `RootDir`, `InstallDir`, and `Status` fields

#### Scenario: Confirm prompts before execution
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Confirm` is invoked
- **THEN** `ShouldProcess()` prompts the user for confirmation
- **AND** vcpkg is executed only if the user confirms

### Requirement: Force parameter suppresses confirmation prompts

The function SHALL accept a `-Force` switch parameter that suppresses confirmation prompts while preserving `-WhatIf` functionality. When `-Force` is specified:
- SHALL set `$ConfirmPreference = 'None'` in local scope when `-Confirm` is not explicitly specified
- SHALL still honor explicit `-Confirm` parameter (e.g., `-Force -Confirm` prompts for confirmation)
- SHALL preserve `-WhatIf` precedence (e.g., `-Force -WhatIf` performs dry-run, not actual removal)
- SHALL use `$PSBoundParameters.ContainsKey('Confirm')` to detect explicit `-Confirm` usage

This follows Microsoft PowerShell ShouldProcess best practices for functions performing destructive operations.

#### Scenario: Force suppresses confirmation prompt
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Force` is invoked
- **THEN** the function does not prompt for confirmation
- **AND** vcpkg remove executes immediately

#### Scenario: Force with explicit Confirm still prompts
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Force -Confirm` is invoked
- **THEN** the function prompts for confirmation despite `-Force`
- **AND** vcpkg executes only if the user confirms

#### Scenario: Force with WhatIf performs dry-run
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Force -WhatIf` is invoked
- **THEN** `-WhatIf` takes precedence over `-Force`
- **AND** vcpkg executes with `--dry-run` flag
- **AND** no actual removal occurs

### Requirement: Ports parameter validation

The `-Ports` parameter SHALL have a `[ValidateNotNullOrEmpty()]` attribute to provide defensive validation at the PowerShell parameter level. This prevents null or empty arrays from being passed to vcpkg, providing early error feedback to users.

#### Scenario: Empty Ports array is rejected
- **WHEN** `Remove-NhcVcpkgPorts -Ports @()` is invoked with an empty array
- **THEN** PowerShell raises a parameter validation error before the function executes

#### Scenario: Null Ports value is rejected
- **WHEN** `Remove-NhcVcpkgPorts -Ports $null` is invoked
- **THEN** PowerShell raises a parameter validation error before the function executes

### Requirement: Return value structure

The function SHALL return a hashtable containing:
- `Command`: Full path to the vcpkg executable used
- `Arguments`: Array of CLI arguments passed to vcpkg
- `RootDir`: The vcpkg root directory path
- `InstallDir`: A hashtable with `Path` (string) and `Exists` (bool) properties
- `Status`: Boolean indicating whether the removal succeeded ($true) or failed ($false)

#### Scenario: Successful removal returns status true
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib'` executes successfully
- **THEN** the returned hashtable contains `Status = $true`
- **AND** the returned hashtable contains `Command` as a string path
- **AND** the returned hashtable contains `Arguments` as an array
- **AND** the returned hashtable contains `RootDir` as a string path
- **AND** the returned hashtable contains `InstallDir` as a hashtable with `Path` and `Exists` keys

#### Scenario: Failed removal returns status false
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'nonexistent-port'` fails because the port is not installed
- **THEN** the returned hashtable contains `Status = $false`

### Requirement: vcpkg errors are passed through

The function SHALL NOT perform custom error handling or translation. When vcpkg reports an error:
- The error message from vcpkg SHALL be visible to the user
- The function SHALL return `Status = $false`
- The function SHALL NOT throw exceptions for vcpkg operational errors

#### Scenario: vcpkg error message is visible
- **WHEN** vcpkg returns an error (e.g., port not installed, dependencies prevent removal)
- **THEN** the error message from vcpkg is written to the error stream
- **AND** the function returns `Status = $false`
