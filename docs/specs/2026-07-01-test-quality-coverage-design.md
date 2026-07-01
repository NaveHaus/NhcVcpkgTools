# Test-quality coverage design for issues #21 and #12

## Goal

Close issue #21 and issue #12 in one focused test-quality branch, provided the
Remove-NhcVcpkgPort work remains a coverage exercise and does not require a
larger change to external process output semantics.

## Scope

This change covers:

- Adding missing private-helper tests for Get-BinaryType and
  Test-EmptyDirectory.
- Making Get-NormalizedNamedDir discoverable by the QA TestQuality checks by
  moving it to its own private function file and loading that file from the
  module root.
- Adding a unit-test file for Get-NormalizedNamedDir.
- Extending Remove-NhcVcpkgPort error-scenario tests to satisfy issue #12.
- Verifying the TestQuality tag passes with the built module on PSModulePath.

This change does not cover unrelated refactoring, openspec artifacts, or changes
to vcpkg command semantics beyond what is required for the tests to pass.

## Architecture and components

### Private helper discoverability

Get-NormalizedNamedDir is currently defined inside
NhcVcpkgTools/Private/Get-CommonArgument.ps1. The QA tests enumerate functions
from the imported module, then look for a source file named `<Name>.ps1` for each
function. Because Get-NormalizedNamedDir has no matching source file, analyzer
and help-quality discovery can fail on a null file path.

The design moves Get-NormalizedNamedDir unchanged into
NhcVcpkgTools/Private/Get-NormalizedNamedDir.ps1 and adds
`Get-NormalizedNamedDir` to the private function list in
NhcVcpkgTools/NhcVcpkgTools.psm1. Get-CommonArgument continues to call the same
helper name, so the public data flow and command-line argument behavior remain
unchanged.

### Private helper tests

Add focused Pester tests under tests/Private:

- Get-BinaryType.Tests.ps1 validates practical modern Windows cases:
  BinaryType.NONE for a non-executable file and BinaryType.BIT64 for a stable
  64-bit executable. Other enum values are not targeted because modern Windows
  systems are unlikely to have reliable DOS, WOW, PIF, POSIX, or OS/2 test
  fixtures.
- Test-EmptyDirectory.Tests.ps1 covers an empty directory, a directory with a
  normal file, a directory with a hidden file, and a nonexistent path error.
- Get-NormalizedNamedDir.Tests.ps1 covers explicit absolute paths, default
  relative paths under a parent, explicitly supplied relative paths, and trailing
  separator normalization.

### Remove-NhcVcpkgPort error coverage

Issue #12 is addressed in tests/Public/Remove-NhcVcpkgPort.Tests.ps1 using
Pester mocks for Start-Process. The tests should verify:

- vcpkg non-zero exit codes return Status = false.
- Start-Process launch failures return Status = false.
- dependency-conflict-style failures, represented by a non-zero vcpkg exit,
  return Status = false without dropping the requested arguments.
- error scenarios still pass the expected command and argument list to
  Start-Process.
- Quiet controls whether Invoke-Vcpkg suppresses Start-Process invocation errors.

The current production design inherits child process console output through
Start-Process -NoNewWindow. Tests should not claim stderr is captured into a
separate buffer unless production code is intentionally changed. If implementation
shows issue #12 requires a new capture/display contract rather than validating
existing inherited output behavior, pause and split that work into a follow-up
scope decision.

## Data flow

Remove-NhcVcpkgPort builds a configuration with Get-CommonArgument, prepends the
`remove` verb, and passes the command plus argument array to Invoke-Vcpkg.
Invoke-Vcpkg calls Start-Process with -Wait and -PassThru, then returns true only
for exit code 0. Remove-NhcVcpkgPort stores that boolean in the returned
configuration as Status.

The Get-NormalizedNamedDir split preserves the existing flow:
Get-CommonArgument determines parent/default directory inputs, calls
Get-NormalizedNamedDir, and receives a normalized path string for the relevant
vcpkg directory option.

## Error handling

No new public error-handling contract is planned. Existing behavior is preserved:

- Get-CommonArgument raises errors for invalid roots, commands, and required
  directories.
- Get-NormalizedNamedDir delegates path validation and normalization to existing
  helpers.
- Invoke-Vcpkg returns false for non-zero process exit codes and for
  Start-Process launch failures.
- Remove-NhcVcpkgPort returns Status = false when Invoke-Vcpkg reports failure.

## Testing and TDD plan

Implementation must follow red/green/refactor:

1. Add failing tests for each #21 helper gap and for the missing #12 error
   scenarios.
2. Make the smallest production change needed to pass, expected to be only the
   Get-NormalizedNamedDir file split unless tests reveal a real mismatch.
3. Refactor only targeted duplication or test setup noise introduced by the new
   tests.

Targeted verification should include the new private tests and
Remove-NhcVcpkgPort.Tests.ps1. Final verification should include the QA
TestQuality checks with the built module available and the canonical
`./build.ps1 -Tasks test` command. After modifying code, run `graphify update .`
to refresh the project graph.

## Pull request boundaries

Use branch `fix/test-quality-coverage-21-12`. If verification passes and no
scope split is needed, the PR body should include:

- Closes #21
- Closes #12
