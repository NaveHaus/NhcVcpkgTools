## Why

The current unit tests and many functions rely on dot-sourcing individual `.ps1` files, which creates inconsistent behavior between “source tree execution” and “installed/built module execution”. Migrating to Sampler conventions will make development, CI, and eventual distribution behave the same way.

## What Changes

- Stop dot-sourcing dependencies inside `NhcVcpkgTools/{Public,Private}/*.ps1`; functions will assume dependencies are loaded by module import.
- Update unit tests under `tests/Public` and `tests/Private` to run against the imported `NhcVcpkgTools` module (Sampler-style), including:
  - importing the module (building via `./build.ps1 -Tasks noop` when needed)
  - setting `PSDefaultParameterValues` for `Mock`, `Should`, and `InModuleScope` to target the module
  - using `InModuleScope` for private function tests
- Address build/import gotchas required for distribution readiness (e.g., avoid `#Requires` statements inside merged module output).
- **Out of scope for this step:** QA tests (`tests/QA`) and Tools tests (`tests/Tools`).

## Capabilities

### New Capabilities
- `sampler-style-test-bootstrap`: Unit tests can self-bootstrap (build “noop” if needed), import the module, and reliably mock/inspect calls within module scope.
- `module-internal-dependency-loading`: Module import loads all required functions so public functions do not dot-source private helpers at runtime.

### Modified Capabilities
- `test-structure`: Update the requirement that the module loader dot-sources scripts from `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private` to a Sampler-compatible module loading approach.

## Impact

- **Code:** All function files under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private` (remove dot-sourcing and adjust any assumptions about script scope).
- **Tests:** All unit tests under `tests/Public` and `tests/Private` (import module, use `InModuleScope`, module-scoped `Mock`/`Should -Invoke`).
- **Build/Distribution:** Ensure the built module imports cleanly when produced by ModuleBuilder/Sampler (notably around `#Requires` placement).
