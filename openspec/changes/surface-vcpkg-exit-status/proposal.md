Related: #17
Related: #18
Related: #29

## Problem and Why

Before 2026-06-30 the **port cmdlets** set the `Status` entry of their **result object** from whether PowerShell managed to start vcpkg, not from the **vcpkg exit status**. A vcpkg operation that failed (for example, a port that does not exist or a dependency conflict) still reported success. Callers that branch on `Status` could not detect failures (issue #17).

Commits `bb017ed`..`97a63d0` fixed this for all three **port cmdlets**, following `docs/plans/2026-06-30-vcpkg-exit-code-status.md`. No OpenSpec spec records the corrected contract. `remove-ports` and the port cmdlets' help also say `-Quiet` suppresses all vcpkg output, including errors, which does not match the module. In fact `-Quiet` has no observable effect: a **launch failure** writes no error records with or without it, and vcpkg's console output is never suppressed.

## Goals

- The specs define, for every **port cmdlet**, what `Status` means: success only when vcpkg ran and its **vcpkg exit status** was zero, and failure when vcpkg exited non-zero or a **launch failure** occurred.
- The specs state that a failed vcpkg operation is reported through the **result object**, not through a thrown exception, and that the **result object** is still returned.
- The specs state that `-Quiet` changes neither vcpkg's console output, the error records written, nor `Status`, and where vcpkg's own diagnostic output appears.
- The `-Quiet` help text of every **port cmdlet** matches that behavior.
- `remove-ports` no longer contradicts these rules.

## Scope and Capabilities

### New Capabilities

- `vcpkg-exit-status`: How **port cmdlets** report the outcome of the vcpkg process they launch: the meaning of `Status`, behavior on **launch failure**, the guarantee that the **result object** is returned, the scope of `-Quiet`, and the visibility of vcpkg's own output.

### Modified Capabilities

- `remove-ports`: "Quiet switch suppresses vcpkg output" is replaced by "Quiet switch changes neither output nor Status", and "vcpkg errors are passed through" is updated, so both align with `vcpkg-exit-status`: `-Quiet` does not hide vcpkg's own console output, and vcpkg's diagnostics are not routed into the PowerShell error stream. The replaced requirement also held misplaced copies of three argument pass-through scenarios; `repair-spec-baseline` already placed those scenarios under "Common vcpkg arguments are supported".

## Non-Goals

- No terminating error, `Write-Error`, or exception on non-zero **vcpkg exit status**; that is tracked separately (issue #18).
- No capture, buffering, or parsing of vcpkg's stdout or stderr.
- No interpretation of specific vcpkg exit codes beyond zero versus non-zero.
- No change to `-Quiet` behavior; whether it should suppress something or be deprecated is tracked separately (issue #29).
- No specs for other `Install-NhcVcpkgPort` or `Export-NhcVcpkgPort` behavior (deferred to a separate per-cmdlet effort).
- No specs for the private helper that launches vcpkg; the contract is stated at the **port cmdlet** level.

## Impact

- `openspec/specs/vcpkg-exit-status/spec.md` is created.
- `openspec/specs/remove-ports/spec.md` updates two requirements.
- Archive order: third, after `repair-spec-baseline` and `rename-public-cmdlets` and before `test-quality-coverage`; its delta specs use **canonical command names**.
- The `.PARAMETER Quiet` help in `Install-NhcVcpkgPort`, `Export-NhcVcpkgPort`, and `Remove-NhcVcpkgPort` is corrected. No behavior, API, dependency, or workflow changes; the behavior described already exists on `master`.
