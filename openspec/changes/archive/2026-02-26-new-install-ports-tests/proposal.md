## Why

The public `Install-NhcVcpkgPorts` function has no dedicated unit tests, which leaves command-line argument construction and output directory handling unverified. Adding targeted Pester tests now will harden the contract for this API while keeping tests hermetic and independent of a vcpkg installation.

## What Changes

- Add unit tests for `Install-NhcVcpkgPorts` that validate generated command-line arguments and output configuration without invoking vcpkg.
- Mock external process invocation (`Start-Process`) and executable validation (`Test-Executable`) to keep tests hermetic while relying on real `Get-CommonArguments` and `Get-TaggedOutputDir` behavior.
- Focus exclusively on `Install-NhcVcpkgPorts` in this change; defer Windows integration tests (e.g., `Get-BinaryType`) and other missing-test coverage to later revisions.

## Capabilities

### New Capabilities
- `install-ports-tests`: Unit-test coverage for `Install-NhcVcpkgPorts` argument generation, directory shaping, and dry-run behavior.

### Modified Capabilities
- None.

## Impact

- New Pester tests under `tests/` covering `Install-NhcVcpkgPorts`.
- No production code changes; no changes to public API behavior.
- Tests will mock `Start-Process` only and will not require vcpkg to be installed.
