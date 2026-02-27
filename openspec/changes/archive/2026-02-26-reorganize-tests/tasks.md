## 1. Source folder casing updates

- [x] 1.1 Rename `NhcVcpkgTools/public` to `NhcVcpkgTools/Public` using a two-step `git mv`
- [x] 1.2 Rename `NhcVcpkgTools/private` to `NhcVcpkgTools/Private` using a two-step `git mv`
- [x] 1.3 Update `NhcVcpkgTools.psm1` dot-sourcing paths to use `Public/` and `Private/`

## 2. Test layout reorganization

- [x] 2.1 Create `tests/Public`, `tests/Private`, and `tests/Integration` with a `.gitkeep` in Integration
- [x] 2.2 Move `Install-NhcVcpkgPorts.Tests.ps1` into `tests/Public` using `git mv`
- [x] 2.3 Move remaining `*.Tests.ps1` files into `tests/Private` using `git mv`
- [x] 2.4 Update test dot-sourcing paths for new test locations and source folder casing

## 3. Verification

- [x] 3.1 Run `Invoke-Pester -Path tests` to validate discovery and path updates
