Related: #12
Related: #13

## 1. Test Setup and Function Skeleton (Red)

- [x] 1.1 Create test file `tests/Public/Remove-NhcVcpkgPorts.Tests.ps1` with BeforeAll/AfterAll bootstrap and helper function `New-TestVcpkgRoot`
- [x] 1.2 Add test: function is discoverable via `Get-Command Remove-NhcVcpkgPorts -Module NhcVcpkgTools`
- [x] 1.3 Create minimal function skeleton `NhcVcpkgTools/Public/Remove-NhcVcpkgPorts.ps1` with empty param block (verify test fails initially, then passes)

## 2. Parameter Sets Tests (Red)

- [x] 2.1 Add test: `-Ports` parameter accepts string array and passes port names to vcpkg `remove` command (via `Get-CommonArguments`)
- [x] 2.2 Add test: `-Outdated` switch passes `--outdated` flag to vcpkg (via `Get-CommonArguments`)
- [x] 2.3 Add test: `-Ports` and `-Outdated` cannot be used together (parameter set mutual exclusivity)

## 2A. Get-CommonArguments Outdated/Recurse Tests (Red)

- [x] 2A.1 Add test in `tests/Private/Get-CommonArguments.Tests.ps1`: when `Outdated` is in `$Parameters`, `--outdated` is included in returned `Arguments`
- [x] 2A.2 Add test: when `Outdated` is NOT in `$Parameters`, `--outdated` is NOT included in returned `Arguments`
- [x] 2A.3 Add test: when `Recurse` is in `$Parameters`, `--recurse` is included in returned `Arguments`
- [x] 2A.4 Add test: when `Recurse` is NOT in `$Parameters`, `--recurse` is NOT included in returned `Arguments`

## 2B. Get-CommonArguments Outdated/Recurse Implementation (Green)

- [x] 2B.1 Extend `Get-CommonArguments` to check for `Outdated` key in `$Parameters` and add `--outdated` to arguments when present
- [x] 2B.2 Extend `Get-CommonArguments` to check for `Recurse` key in `$Parameters` and add `--recurse` to arguments when present
- [x] 2B.3 Verify all Get-CommonArguments Outdated/Recurse tests pass

## 2C. Get-CommonArguments String Path Returns

- [x] 2C.1 Verify `Get-CommonArguments` returns all path values in `$result` as strings by enclosing source variables in double quotes (e.g., `Path = "$PackageDir"`)
- [x] 2C.2 Add test in `tests/Private/Get-CommonArguments.Tests.ps1`: all `Path` values in the returned hashtable are of type `[string]`

## 3. Parameter Sets Implementation (Green)

- [x] 3.1 Implement `Ports` parameter set with `-Ports` string array parameter (passed to `Get-CommonArguments` via `$Parameters`)
- [x] 3.2 Implement `Outdated` parameter set with `-Outdated` switch parameter (passed to `Get-CommonArguments` via `$Parameters`)
- [x] 3.3 Verify all parameter set tests pass

## 4. Recurse Switch Tests (Red)

- [x] 4.1 Add test: `-Recurse` switch includes `--recurse` flag in vcpkg arguments (via `Get-CommonArguments`)
- [x] 4.2 Add test: without `-Recurse`, `--recurse` flag is NOT included

## 5. Recurse Switch Implementation (Green)

- [x] 5.1 Add `-Recurse` switch parameter to function (passed to `Get-CommonArguments` via `$Parameters`)
- [x] 5.2 Verify `-Recurse` is passed to `Get-CommonArguments` via `$Parameters` hashtable (implementation in `Get-CommonArguments` per 2B.2)
- [x] 5.3 Verify all Recurse tests pass

## 6. Common Arguments Tests (Red)

- [x] 6.1 Add test: `-RootDir` is passed as `--vcpkg-root` to vcpkg
- [x] 6.2 Add test: `-Triplet` is passed as `--triplet` to vcpkg
- [x] 6.3 Add test: `-OverlayPorts` paths are passed as `--overlay-ports` to vcpkg
- [x] 6.4 Add test: `-InstallDir` is passed as `--x-install-root` to vcpkg

## 7. Common Arguments Implementation (Green)

- [x] 7.1 Add common parameters: `-Command`, `-RootDir`, `-Triplet`, `-OverlayPorts`, `-OverlayTriplets`, `-InstallDir`
- [x] 7.2 Call `Get-CommonArguments` with `$Directories = @('InstallDir')` to build vcpkg arguments
- [x] 7.3 Verify all common arguments tests pass

## 8. ShouldProcess Tests (Red)

- [x] 8.1 Add test: `-WhatIf` includes `--dry-run` flag in vcpkg arguments
- [x] 8.2 Add test: function declares `[CmdletBinding(SupportsShouldProcess)]`

## 9. ShouldProcess Implementation (Green)

- [x] 9.1 Add `[CmdletBinding(SupportsShouldProcess)]` attribute to function
- [x] 9.2 Implement `$PSCmdlet.ShouldProcess()` check before executing vcpkg
- [x] 9.3 Add `--dry-run` to arguments when `-WhatIf` is specified
- [x] 9.4 Verify all ShouldProcess tests pass

## 9A. Quiet Switch Tests (Red)

- [x] 9A.1 Add test: `-Quiet` switch parameter exists on function
- [x] 9A.2 Add test: with `-Quiet`, vcpkg output (stdout/stderr) is suppressed

## 9B. Quiet Switch Implementation (Green)

- [x] 9B.1 Add `-Quiet` switch parameter to function
- [x] 9B.2 Implement conditional logic to pipe `Start-Process` output to `Out-Null` when `-Quiet` is specified
- [x] 9B.3 Verify all Quiet switch tests pass

## 10. Return Value Tests (Red)

- [x] 10.1 Add test: return hashtable contains `Command` as string path to vcpkg executable
- [x] 10.2 Add test: return hashtable contains `Arguments` as array of CLI arguments
- [x] 10.3 Add test: return hashtable contains `RootDir` as string path
- [x] 10.4 Add test: return hashtable contains `InstallDir` with `Path` and `Exists` keys
- [x] 10.5 Add test: return hashtable contains `Status = $true` on successful execution
- [x] 10.6 Add test: return hashtable contains `Status = $false` when vcpkg fails

## 11. Return Value Implementation (Green)

- [x] 11.1 Build return hashtable with `Command`, `Arguments`, `RootDir`, `InstallDir`, `Status` fields
- [x] 11.2 Implement `InstallDir` as hashtable with `Path` (string) and `Exists` (bool)
- [x] 11.3 Set `Status` based on vcpkg exit code
- [x] 11.4 Verify all return value tests pass

## 12. Force Parameter Tests (Red)

- [x] 12.1 Add test: `-Force` switch parameter exists on function
- [x] 12.2 Add test: `-Force` suppresses confirmation prompts (no prompt occurs)
- [x] 12.3 Add test: `-Force -Confirm` still prompts for confirmation (explicit Confirm overrides Force)
- [x] 12.4 Add test: `-Force -WhatIf` performs dry-run (WhatIf takes precedence over Force)
- [x] 12.5 Add test: `-Force` without explicit `-Confirm` sets `$ConfirmPreference = 'None'` in local scope

## 13. Force Parameter Implementation (Green)

- [x] 13.1 Add `-Force` switch parameter to function signature
- [x] 13.2 Add Force handling logic before ShouldProcess: `if ($Force -and -not $PSBoundParameters.ContainsKey('Confirm')) { $ConfirmPreference = 'None' }`
- [x] 13.3 Verify Force logic preserves WhatIf precedence (ShouldProcess always executes)
- [x] 13.4 Verify all Force parameter tests pass

## 14. Ports Parameter Validation Tests (Red)

- [x] 14.1 Add test: `-Ports @()` (empty array) raises parameter validation error
- [x] 14.2 Add test: `-Ports $null` raises parameter validation error
- [x] 14.3 Add test: `-Ports 'zlib'` (valid single port) passes validation

## 15. Ports Parameter Validation Implementation (Green)

- [x] 15.1 Add `[ValidateNotNullOrEmpty()]` attribute to `-Ports` parameter
- [x] 15.2 Verify all Ports parameter validation tests pass

## 16. Refactor and Final Validation

- [x] 16.1 Review function implementation for code clarity and consistency with existing public functions
- [x] 16.2 Run full test suite: `./build.ps1 -Tasks test`
- [x] 16.3 Verify function is automatically exported by module manifest
