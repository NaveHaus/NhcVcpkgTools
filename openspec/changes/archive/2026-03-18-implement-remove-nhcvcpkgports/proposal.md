Related: #12
Related: #13

## Why

NhcVcpkgTools provides `Install-NhcVcpkgPorts` and `Export-NhcVcpkgPorts` to manage vcpkg ports, but lacks a corresponding function to remove installed ports. Users currently must invoke `vcpkg remove` directly, losing the consistent parameter handling and PowerShell integration the module provides.

## What Changes

- Add new public function `Remove-NhcVcpkgPorts` that wraps `vcpkg remove`
- Support two parameter sets: `-Ports` (remove specific packages) and `-Outdated` (remove stale packages)
- Implement `-Recurse` switch to allow removing dependent packages
- Implement `-Force` switch to suppress confirmation prompts (standard PowerShell pattern for ShouldProcess functions)
- Add `[ValidateNotNullOrEmpty()]` to `-Ports` parameter for defensive validation
- Use `-InstallDir` with same semantics as `Export-NhcVcpkgPorts`: points to where ports are already installed (defaults to `<vcpkg-root>/installed`)
- No `-OutputDir` or `-Tag` parameters needed (unlike Install, Remove operates on an existing location, not creating a new one)
- Reuse `Get-CommonArguments` helper with `$Directories = @('InstallDir')` for consistent path handling
- Support `ShouldProcess` (`-WhatIf`/`-Confirm`) by translating to vcpkg's `--dry-run` flag
- Return a hashtable consistent with other public functions (Command, Arguments, RootDir, InstallDir, Status)

## Capabilities

### New Capabilities

- `remove-ports`: Provides PowerShell wrapper for `vcpkg remove` command with consistent parameter handling and WhatIf support. Uses `-InstallDir` semantics matching `Export-NhcVcpkgPorts` (source location, not output).

### Modified Capabilities

<!-- None - this is a new function that does not change existing behavior -->

## Impact

- **New file**: `NhcVcpkgTools/Public/Remove-NhcVcpkgPorts.ps1`
- **New tests**: `tests/Public/Remove-NhcVcpkgPorts.Tests.ps1`
- **Module exports**: Function will be automatically exported via existing `*.ps1` pattern in module manifest
- **No breaking changes**: Additive change only
