## Why

The current flat test layout makes it harder to distinguish public vs. private coverage and to introduce integration tests cleanly. Reorganizing the test and source folders now sets a consistent structure before integration tests are added and reduces ongoing confusion.

## What Changes

- Capitalize `NhcVcpkgTools/public` and `NhcVcpkgTools/private` to `Public/` and `Private/` using a safe two-step `git mv` approach.
- Update module loader paths in `NhcVcpkgTools.psm1` to dot-source from `Public/` and `Private/`.
- Reorganize tests into `tests/Public` and `tests/Private` based on the visibility of the function under test, keeping filenames as `*.Tests.ps1`, and move files with `git mv`.
- Add `tests/Integration/.gitkeep` to reserve a location for upcoming integration tests.
- Update test dot-sourcing paths to the new directory layout.

## Capabilities

### New Capabilities
- `test-structure`: Defines the repository conventions for organizing public, private, and integration tests.

### Modified Capabilities
- (none)

## Impact

- Filesystem layout under `NhcVcpkgTools/` and `tests/`.
- Module loader path resolution in `NhcVcpkgTools.psm1`.
- Pester test file locations and dot-sourcing paths.
