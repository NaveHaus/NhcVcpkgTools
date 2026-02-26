## Context

`Install-NhcVcpkgPorts` is a public PowerShell function that constructs vcpkg command-line arguments and invokes `Start-Process`. The repository already includes unit tests for several private helpers, but there is no test file for this public function. The change focuses on adding hermetic Pester tests that validate argument construction and output configuration without requiring vcpkg to be installed.

## Goals / Non-Goals

**Goals:**
- Add unit tests for `Install-NhcVcpkgPorts` that validate command-line generation and output directory shaping.
- Keep tests hermetic by mocking external process invocation while using real helper functions for argument building.
- Align with the repo’s TDD requirement by adding tests first for new/modified behavior.

**Non-Goals:**
- Adding tests for other missing files (`Get-BinaryType`, `Test-EmptyDirectory`, etc.) in this change.
- Integration tests that require vcpkg or Windows API validation.
- Modifying production code or changing public API behavior.

## Decisions

1. **Scope limited to `Install-NhcVcpkgPorts`**
   - *Decision:* Only add tests for the public install function in this change.
   - *Rationale:* The request defines “missing” as files with no test file and prioritizes the install command. Other gaps can be addressed separately.
   - *Alternatives considered:* Cover all missing test files in one change (rejected to keep scope tight).

2. **Unit tests must not require vcpkg**
   - *Decision:* Mock `Start-Process` so tests never invoke vcpkg, and mock `Test-Executable` to bypass real executable validation.
   - *Rationale:* Tests should run in any environment without external dependencies.
   - *Alternatives considered:* Integration-style tests that call vcpkg (deferred to later revision).

3. **Do not mock `Get-CommonArguments` or `Get-TaggedOutputDir`**
   - *Decision:* Use real implementations to validate the actual command lines produced by `Install-NhcVcpkgPorts`, while allowing `Test-Executable` to be mocked for hermeticity.
   - *Rationale:* These helpers are the core logic being validated; mocking would reduce test value.
   - *Alternatives considered:* Mock all helpers for ultra-isolated tests (rejected; would miss real argument construction).

4. **Defer `Get-BinaryType` tests**
   - *Decision:* Skip `Get-BinaryType` testing in this unit-test change.
   - *Rationale:* It is Windows API–oriented and better suited for integration tests; it is also not required for validating `Install-NhcVcpkgPorts`.
   - *Alternatives considered:* Add unit tests with local executables (deferred).

## Risks / Trade-offs

- **Risk:** `Test-VcpkgRoot` will always fail if passed a non-existent directory or a directory that does not look like a vcpkg root. → *Mitigation:* Use `TestDrive:` and create minimal `.vcpkg-root`.
- **Risk:** `Test-Executable` will always fail since there is no vcpkg executable to test. → *Mitigation:* Mock `Test-Executable` to avoid dummy executables.
- **Risk:** Argument comparisons can be brittle due to path normalization. → *Mitigation:* Normalize expected paths using the same helpers or compare with `-Like`/contains checks where appropriate.