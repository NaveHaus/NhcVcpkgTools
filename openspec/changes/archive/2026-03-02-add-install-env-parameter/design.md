## Context

`Install-NhcVcpkgPorts` is a public PowerShell function that constructs a `vcpkg install` command line and invokes `Start-Process`. Today, vcpkg implicitly inherits the caller’s environment, which means callers must set transient vcpkg-related environment variables in their session (or parent process) to influence a single invocation.

This change introduces explicit, per-invocation environment controls for the spawned `vcpkg` process:

- `Env`: caller-provided environment variable overrides for the child process.
- `KeepEnvVars`: a convenience parameter that sets `VCPKG_KEEP_ENV_VARS` (semicolon-separated) for the child process, with explicit precedence over any `VCPKG_KEEP_ENV_VARS` entry in `Env`.

The repository targets PowerShell Core and uses Pester v5+ for unit testing. The implementation will rely on `Start-Process -Environment`, which is available starting in PowerShell 7.4, so the module’s minimum required PowerShell version will be updated accordingly (README + module manifest).

## Goals / Non-Goals

**Goals:**

- Provide a per-invocation mechanism for passing environment variables to the spawned `vcpkg` process without mutating the caller’s `$env:`.
- Add `KeepEnvVars` as an ergonomic way to set `VCPKG_KEEP_ENV_VARS` using the vcpkg-required `;` delimiter.
- Make precedence explicit and testable: `KeepEnvVars` overrides `Env["VCPKG_KEEP_ENV_VARS"]` when both are provided.
- Implement test-first: add Pester tests that validate the environment passed to `Start-Process` (and precedence rules) without launching vcpkg.
- Record the new PowerShell 7.4+ dependency in both README and module manifest.

**Non-Goals:**

- Do not add `Env`/`KeepEnvVars` to `Export-NhcVcpkgPorts` in this change.
- Do not change argument construction logic or how vcpkg root/triplet defaults are detected.
- Do not support process-scoped environment passing on PowerShell versions older than 7.4.

## Decisions

1. **Use `Start-Process -Environment` (PowerShell 7.4+) to avoid caller environment mutation**

   - **Decision:** Require PowerShell 7.4+ and use `Start-Process`’s `-Environment <hashtable>` parameter to set/override environment variables only for the child process.
   - **Rationale:** This directly achieves the “no session pollution” goal. A fallback implementation for older PowerShell versions would either require a different process-launch mechanism or temporarily mutating `$env:` (undesirable and harder to make robust).
   - **Alternatives considered:**
     - Temporarily set `$env:` variables and restore them after launch (riskier and not concurrency-safe).
     - Use `System.Diagnostics.ProcessStartInfo` directly to control environment (more complex and inconsistent with existing `Start-Process` usage).

2. **Parameter contract and precedence mirrors “explicit invocation wins”**

   - **Decision:** If `KeepEnvVars` is specified, it always overrides any `VCPKG_KEEP_ENV_VARS` value provided via `Env`.
   - **Rationale:** This matches the spirit of vcpkg’s precedence rules and reduces ambiguity. The most explicit per-invocation knob (`KeepEnvVars`) wins.
   - **Notes:** This precedence must be documented in parameter help and README (as applicable).

3. **`KeepEnvVars` serialization uses semicolon delimiter**

   - **Decision:** Serialize `KeepEnvVars` to `VCPKG_KEEP_ENV_VARS` using `;` as the separator.
   - **Rationale:** vcpkg expects semicolon-separated variable names.
   - **Edge behavior:** Preserve user-provided ordering exactly; do not trim whitespace and do not deduplicate entries.

4. **`Env` supports unsetting variables via `$null` values**

   - **Decision:** Allow `Env` to contain keys with `$null` values; these will be passed through to `Start-Process -Environment` to unset the corresponding variable in the child process.
   - **Rationale:** PowerShell’s `Start-Process -Environment` explicitly supports `$null` values to unset variables, and this is useful for transient invocations.

4. **Test strategy: mock `Start-Process` and assert `-Environment` contents**

   - **Decision:** Extend/create Pester unit tests for `Install-NhcVcpkgPorts` that:
     - Mock `Start-Process` to capture `-Environment` (and existing `-ArgumentList`) without launching vcpkg.
     - Verify `Env` entries are present in the captured environment.
     - Verify `KeepEnvVars` produces the expected `VCPKG_KEEP_ENV_VARS` value and overrides `Env["VCPKG_KEEP_ENV_VARS"]`.
     - Verify `$null` values in `Env` are passed through to `Start-Process -Environment` to unset variables for the child process.
   - **Rationale:** Keeps tests hermetic and focused on the contract of the wrapper.
   - **Alternatives considered:** Integration tests that run vcpkg (rejected; would require vcpkg installation and would be slow/flaky).

## Risks / Trade-offs

- **[Raising minimum PowerShell version to 7.4+] → Mitigation:** Document the dependency explicitly (README Requirements + manifest `PowerShellVersion`) and ensure tests run under 7.4+ in CI.
- **[`Start-Process -Environment` has special handling for `PATH`] → Mitigation:** Avoid manipulating `PATH` as part of this feature; document this nuance in parameter help for `Env` if we expose `$null`/replacement semantics.
- **[Environment variable name casing and platform differences] → Mitigation:** Treat environment variable keys as case-insensitive for precedence checks (especially on Windows); keep behavior consistent in tests.

## Migration Plan

1. Update module manifest to require PowerShell 7.4+.
2. Update README “Requirements” section to list PowerShell 7.4+.
3. Add tests first, then implement parameter handling, then update docs/versioning as needed.

## Open Questions

- None.
