## REMOVED Requirements

### Requirement: Mutually exclusive parameter sets for Ports and Outdated
**Reason**: Two of its scenarios contradicted the "Ports parameter validation" requirement and the module, which rejects a null or empty -Ports value before vcpkg runs.
**Migration**: Replaced by "Ports and Outdated parameter sets are mutually exclusive", which keeps the remaining scenarios unchanged.

## MODIFIED Requirements

### Requirement: Common vcpkg arguments are supported

The function SHALL accept and pass through common vcpkg arguments consistent with other NhcVcpkgTools functions:
- `-Command`: Path to vcpkg executable (optional, auto-detected from RootDir or VCPKG_ROOT)
- `-RootDir`: Path to vcpkg root directory (optional, auto-detected from Command or VCPKG_ROOT)
- `-Triplet`: Target triplet (optional, auto-detected from vcpkg defaults)
- `-OverlayPorts`: Array of overlay ports paths (optional)
- `-OverlayTriplets`: Array of overlay triplets paths (optional)

These arguments SHALL be handled by reusing the `Get-CommonArguments` private function with `$Directories = @('InstallDir')`.

#### Scenario: RootDir is passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -RootDir 'C:\vcpkg'` is invoked
- **THEN** the function includes `--vcpkg-root="C:\vcpkg"` in the arguments passed to vcpkg

#### Scenario: Triplet is passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -Triplet 'x64-windows'` is invoked
- **THEN** the function includes `--triplet="x64-windows"` in the arguments passed to vcpkg

#### Scenario: OverlayPorts paths are passed to vcpkg
- **WHEN** `Remove-NhcVcpkgPorts -Ports 'zlib' -OverlayPorts 'C:\overlays\ports'` is invoked
- **THEN** the function includes `--overlay-ports="C:\overlays\ports"` in the arguments passed to vcpkg

## ADDED Requirements

### Requirement: Ports and Outdated parameter sets are mutually exclusive

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
