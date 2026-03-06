## Context

The current `NhcVcpkgTools` unit test model executes function scripts directly by dot-sourcing files from `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`. This differs from real module consumption, where users import a module and invoke exported commands in module scope.

This mismatch causes three issues:

1. Test behavior is not a reliable proxy for packaged/distributed behavior.
2. Internal function dependency loading is split between module import and runtime dot-sourcing.
3. Pester mocking patterns are fragile because tests are not consistently scoped to an imported module.

Additionally, `NhcVcpkgTools.psm1` in source is intentionally empty, so source import cannot load function bodies unless built output is used. Prior to this change, the project was manually migrated to Sampler and now uses Sampler/ModuleBuilder conventions (see `build.yaml`), so the tests should be migrated to align with that pipeline.

This design covers only `tests/Public` and `tests/Private` and excludes `tests/QA` and `tests/Tools` for this change.

## Goals / Non-Goals

**Goals:**
- Make unit tests execute against an imported `NhcVcpkgTools` module (not directly dot-sourced function scripts).
- Support both test entrypoints:
  - `./build.ps1 -Tasks test`
  - direct `Invoke-Pester -Path tests`
- If the module is not already imported, run `./build.ps1 -Tasks noop`, then import the module.
- Remove dot-sourcing between function files in `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`.
- Standardize Pester module-scoped assertions/mocks for reliable behavior (`Mock`, `Should`, `InModuleScope` targeting `NhcVcpkgTools`).
- Adhere to the TDD red/green/refactor methodology

**Non-Goals:**
- Refactor QA tests under `tests/QA`.
- Refactor tooling/lint tests under `tests/Tools`.
- Redesign public API behavior beyond what is required for module-import consistency.
- Change release/versioning process in this step.

## Decisions

### 1) Unit tests will self-bootstrap module import
**Decision:** Add shared test bootstrap logic for unit tests that:
- checks whether `NhcVcpkgTools` is importable
- if not importable, runs `./build.ps1 -Tasks noop`
- imports `NhcVcpkgTools`
- sets module defaults:
  - `$PSDefaultParameterValues['Mock:ModuleName'] = 'NhcVcpkgTools'`
  - `$PSDefaultParameterValues['Should:ModuleName'] = 'NhcVcpkgTools'`
  - `$PSDefaultParameterValues['InModuleScope:ModuleName'] = 'NhcVcpkgTools'`

**Rationale:** This mirrors Sampler patterns and ensures tests run consistently both from build workflow and direct `Invoke-Pester` runs.

**Alternatives considered:**
- **Build-only entrypoint** (`build.ps1 -Tasks test` exclusively): rejected because direct `Invoke-Pester` remains a common local and CI debugging path.
- **Assume module prebuilt externally**: rejected because it makes test execution order-dependent and less portable.

### 2) Remove intra-module dot-sourcing in function scripts
**Decision:** Eliminate `. <path-to-other-function.ps1>` calls from files under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`; function dependencies are resolved through module assembly/import.

**Rationale:** Dot-sourcing inside function files creates dual loading behavior and breaks separation between source-file execution and module execution. Sampler/ModuleBuilder already provide module-time composition.

**Alternatives considered:**
- **Keep selective dot-sourcing for private helpers**: rejected because it preserves inconsistent runtime behavior and complicates distribution correctness.
- **Wrapper loader script in every test**: rejected because it recreates custom loading behavior rather than validating module behavior.

### 3) Private function tests will execute with `InModuleScope`
**Decision:** Convert private tests to call private functions only inside `InModuleScope` blocks after module import.

**Rationale:** Private functions are not part of external module surface and should be validated through module scope, not by dot-sourcing private files directly.

**Alternatives considered:**
- **Export private functions in test mode**: rejected due to API leakage and conditional behavior.
- **Continue direct dot-sourcing private files in tests**: rejected because it bypasses module semantics.

### 4) `#Requires -Version 7.4` handling will move out of function files
**Decision:** Remove per-function `#Requires -Version 7.4` directives from `Public/*.ps1` and `Private/*.ps1`, relying on module manifest/runtime policy (already `PowerShellVersion = '7.4'` in `.psd1`) and the private `00ModuleHeader.ps1` script that is automatically prepended to the generated module.

**Rationale:** ModuleBuilder merge output can place script content before subsequent `#Requires`, causing parsing/runtime issues. Per-file `#Requires` is safe in isolated scripts but brittle in concatenated module outputs.

**Alternatives considered:**
- **Leave `#Requires` in every function file**: rejected because it is incompatible with merged module assembly constraints.
- **Duplicate checks in every function body**: rejected due to noise and maintenance overhead.

### 5) TDD migration will proceed incrementally by test area
**Decision:** Migrate test + code in small slices (e.g., one public function + dependent private tests at a time), ensuring failing tests first, then implementation updates, then green tests.

**Rationale:** The change is cross-cutting; incremental TDD reduces regressions and keeps failures local.

**Alternatives considered:**
- **Big-bang rewrite of all tests and functions**: rejected due to high breakage risk and difficult diagnosis.

## Risks / Trade-offs

- **[Risk] Bootstrap logic divergence across many test files** → **Mitigation:** centralize bootstrap in shared test helper/fixture and dot-source only that helper from tests.
- **[Risk] Mock assertions fail after scope change** → **Mitigation:** enforce module-scoped defaults and update assertions to module-aware patterns.
- **[Risk] Private tests become harder to read with `InModuleScope` nesting** → **Mitigation:** standardize test structure template and helper functions for setup.
- **[Risk] Removing dot-sourcing reveals hidden coupling/order dependencies** → **Mitigation:** migrate incrementally and run unit tests after each slice.
- **[Risk] `#Requires` relocation could miss edge execution paths** → **Mitigation:** validate module import in PowerShell 7.4+ and ensure manifest-enforced minimum version remains authoritative.

## Migration Plan

1. Add/standardize unit-test bootstrap helper implementation
2. Update a first vertical slice of tests (`tests/Public` + related `tests/Private`) to module import + module-scoped defaults + `InModuleScope`.
3. Remove corresponding dot-sourcing from affected function files and fix any dependency assumptions.
4. Repeat slice-by-slice until all targeted tests/functions in `tests/Public`, `tests/Private`, and `NhcVcpkgTools/{Public,Private}` are migrated.
5. Validate both entrypoints:
   - `./build.ps1 -Tasks test`
   - `Invoke-Pester -Path tests/Public,tests/Private`
6. Confirm no regressions in scope of this change and document any follow-up work for QA/Tools tests as out-of-scope backlog.

**Rollback strategy:** Revert migrated slices if a blocking issue is found. Because migration is incremental and scoped, rollback can occur per-slice without reverting unrelated repository changes.

## Resolved Questions

- Module bootstrap helper will be embedded per suite (`tests/Public` and `tests/Private`) for consistency with Sampler test suite conventions.
- For direct `Invoke-Pester -Path tests`, discovery of QA/Tools tests will be left unchanged and handled by invocation path conventions.
- Private tests will not be redesigned in this change to assert behavior via public commands; they will continue to directly invoke private functions under `InModuleScope`.