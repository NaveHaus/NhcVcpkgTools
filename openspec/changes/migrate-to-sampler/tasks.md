## 1. Baseline + safety checks

- [x] 1.1 Run current unit tests via both entrypoints and record current failures/behavior (`./build.ps1 -Tasks test` and `Invoke-Pester -Path tests/Public,tests/Private`)
- [x] 1.2 Add a small “migration guard” Pester test that fails if any unit test file dot-sources `NhcVcpkgTools/Public/*.ps1` or `NhcVcpkgTools/Private/*.ps1` (red first)

## 2. Shared unit-test bootstrap (tests/Shared)

- [x] 2.1 Create `tests/Shared/Bootstrap-NhcVcpkgTools.Tests.ps1` (or equivalent) that ensures a build exists (`./build.ps1 -Tasks noop` if module not importable), imports `NhcVcpkgTools`, and sets `$PSDefaultParameterValues` for `Mock`, `Should`, and `InModuleScope`
- [x] 2.2 Write Pester tests for the bootstrap helper: no-op when module already imported; triggers noop build + import when not importable; applies module-scoped defaults

## 3. Migrate tests/Public to imported-module pattern

- [x] 3.1 Convert `tests/Public` to dot-source only the shared bootstrap and remove any direct dot-sourcing of module source scripts
- [x] 3.2 Update Public tests to use module-scoped mocks/assertions (rely on defaults, and use `InModuleScope` only where required)

## 4. Migrate tests/Private to `InModuleScope`

- [x] 4.1 Convert `tests/Private` to dot-source only the shared bootstrap and remove any direct dot-sourcing of module source scripts
- [x] 4.2 Update Private tests to enclose 'It' script blocks within `InModuleScope -ScriptBlock` blocks and adjust mocks/assertions accordingly

## 5. Remove runtime dot-sourcing between function scripts

- [x] 5.1 Add/extend Pester tests that scan `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private` for active runtime dot-sourcing statements of sibling module scripts (red first)
- [x] 5.2 Remove intra-module `. <path-to-other-function.ps1>` calls from affected function scripts and ensure dependencies resolve via module import/assembly (green)

## 6. `#Requires -Version` relocation for ModuleBuilder compatibility

- [x] 6.1 Add/extend Pester tests that assert no `NhcVcpkgTools/Public/*.ps1` or `NhcVcpkgTools/Private/*.ps1` file contains `#Requires -Version`
- [x] 6.2 Remove `#Requires -Version 7.4` directives from function scripts and ensure module-level enforcement remains via manifest/header (verify module imports in PS 7.4+)

## 7. Verify supported entrypoints + regression pass

- [x] 7.1 Ensure `./build.ps1 -Tasks test` runs green with the new bootstrap behavior
- [x] 7.2 Ensure direct `Invoke-Pester -Path tests/Public,tests/Private` runs green in a clean workspace (no pre-built module) and in a workspace with module already imported
