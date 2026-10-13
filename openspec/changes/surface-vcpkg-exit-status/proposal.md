Related: #17
Related: #18

## Problem and Why

Before 2026-06-30 the **port cmdlets** set the `Status` entry of their **result object** from whether PowerShell managed to start vcpkg, not from the **vcpkg exit status**. A vcpkg operation that failed (for example, a port that does not exist or a dependency conflict) still reported success. Callers that branch on `Status` could not detect failures (issue #17).

Commits `bb017ed`..`97a63d0` fixed this for all three **port cmdlets**, following `docs/plans/2026-06-30-vcpkg-exit-code-status.md`. No OpenSpec spec records the corrected contract. `remove-ports` also says `-Quiet` suppresses all vcpkg output, which does not match the module.

## Goals

- The specs define, for every **port cmdlet**, what `Status` means: success only when vcpkg ran and its **vcpkg exit status** was zero, and failure when vcpkg exited non-zero or a **launch failure** occurred.
- The specs state that a failed vcpkg operation is reported through the **result object**, not through a thrown exception, and that the **result object** is still returned.
- The specs state what `-Quiet` does and does not suppress, and where vcpkg's own diagnostic output appears.
- `remove-ports` no longer contradicts these rules.

## Scope and Capabilities

### New Capabilities

- `vcpkg-exit-status`: How **port cmdlets** report the outcome of the vcpkg process they launch: the meaning of `Status`, behavior on **launch failure**, the guarantee that the **result object** is returned, the scope of `-Quiet`, and the visibility of vcpkg's own output.

### Modified Capabilities

- `remove-ports`: "Quiet switch suppresses vcpkg output" is replaced by "Quiet switch suppresses launch error records", and "vcpkg errors are passed through" is updated, so both align with `vcpkg-exit-status`: `-Quiet` does not hide vcpkg's own console output, and vcpkg's diagnostics are not routed into the PowerShell error stream. The replaced requirement also held misplaced copies of three argument pass-through scenarios; `repair-spec-baseline` already placed those scenarios under "Common vcpkg arguments are supported".

## Non-Goals

- No terminating error, `Write-Error`, or exception on non-zero **vcpkg exit status**; that is tracked separately (issue #18).
- No capture, buffering, or parsing of vcpkg's stdout or stderr.
- No interpretation of specific vcpkg exit codes beyond zero versus non-zero.
- No specs for other `Install-NhcVcpkgPort` or `Export-NhcVcpkgPort` behavior (deferred to a separate per-cmdlet effort).
- No specs for the private helper that launches vcpkg; the contract is stated at the **port cmdlet** level.

## Impact

- `openspec/specs/vcpkg-exit-status/spec.md` is created.
- `openspec/specs/remove-ports/spec.md` updates two requirements.
- Archive order: third, after `repair-spec-baseline` and `rename-public-cmdlets` and before `test-quality-coverage`; its delta specs use **canonical command names**.
- No code, API, dependency, or workflow changes; the behavior described already exists on `master`.
