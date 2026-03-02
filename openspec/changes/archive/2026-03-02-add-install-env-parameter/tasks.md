## 1. Tests (TDD)

- [x] 1.1 Follow red-green TDD: after adding EACH new test below, run it and confirm it fails (RED) before completing the corresponding implementation task in section 2
- [x] 1.2 Extend `Install-NhcVcpkgPorts.Tests.ps1` to capture the `-Environment` argument from the mocked `Start-Process`
- [x] 1.3 Add unit test: passing `-Env @{ FOO = 'bar' }` results in `Start-Process -Environment` containing `FOO=bar`
- [x] 1.4 Add unit test: passing `-Env @{ FOO = $null }` passes `FOO=$null` through to `Start-Process -Environment`
- [x] 1.5 Add unit test: caller `$env:` is not mutated when `-Env` is provided
- [x] 1.6 Add unit test: `-KeepEnvVars @('A','B')` sets `VCPKG_KEEP_ENV_VARS` to `A;B` in `Start-Process -Environment`
- [x] 1.7 Add unit test: `-KeepEnvVars` overrides `-Env` provided `VCPKG_KEEP_ENV_VARS`
- [x] 1.8 Add unit test: `-KeepEnvVars @(' A','A','B ')` preserves entries exactly (no trim, no dedupe)

## 2. Implementation

- [x] 2.1 Add `Env` and `KeepEnvVars` parameters to `Install-NhcVcpkgPorts` with help text documenting precedence and `;` delimiter
- [x] 2.2 Build the `Start-Process -Environment` hashtable from `Env` and `KeepEnvVars` (with `KeepEnvVars` overriding `VCPKG_KEEP_ENV_VARS`)
- [x] 2.3 Pass the environment hashtable to both `Start-Process` call sites (`Quiet` and non-`Quiet`)
- [x] 2.4 Ensure implementation does not mutate caller `$env:` and passes `$null` values through for unsetting variables

## 3. Dependency and documentation updates

- [x] 3.1 Update module manifest (`NhcVcpkgTools.psd1`) `PowerShellVersion` to `7.4` (or higher)
- [x] 3.2 Update README “Requirements” section to list PowerShell 7.4+ and update any “PowerShell 7.2+” wording accordingly
- [x] 3.3 Run full Pester suite and ensure all tests pass under PowerShell 7.4+
