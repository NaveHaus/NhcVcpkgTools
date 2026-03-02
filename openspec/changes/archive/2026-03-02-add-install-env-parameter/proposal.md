## Why

`Install-NhcVcpkgPorts` already respects the caller’s environment implicitly via the `vcpkg` process, but setting transient vcpkg-related variables in the caller session is error-prone and obscures which variables are meant to apply to a single invocation. Adding explicit parameters for per-invocation environment allows callers to pass variables (including `VCPKG_KEEP_ENV_VARS`) without polluting their session.

## What Changes

- Add an `Env` parameter to `Install-NhcVcpkgPorts` to pass a hashtable of environment variables to the spawned `vcpkg` process (per-invocation overlay; does not modify the caller’s environment).
- Add a `KeepEnvVars` parameter to `Install-NhcVcpkgPorts` that sets `VCPKG_KEEP_ENV_VARS` for the spawned `vcpkg` process using semicolon-separated variable names.
- Document explicit precedence: if `KeepEnvVars` is provided, it overrides any `VCPKG_KEEP_ENV_VARS` entry supplied via `Env` (aligning with vcpkg’s “explicit invocation wins” behavior).
- Update module requirements to PowerShell 7.4+ to rely on process-scoped environment support.
- Add/extend Pester tests (TDD) to validate environment construction and precedence without invoking `vcpkg`.

## Capabilities

### New Capabilities
- `install-env-parameter`: Support explicit, per-invocation environment variables for `Install-NhcVcpkgPorts`, including `KeepEnvVars` precedence and a PowerShell 7.4+ requirement.

### Modified Capabilities

## Impact

- **Public API**: `Install-NhcVcpkgPorts` gains new parameters (`Env`, `KeepEnvVars`).
- **Runtime dependency**: baseline PowerShell version increases to 7.4+.
- **Docs**: README Requirements section updated; module manifest updated to record PowerShell 7.4+.
- **Tests**: new/updated Pester tests for `Install-NhcVcpkgPorts` verifying `Start-Process` receives the expected environment overlay and precedence rules.
