Related: #21
Related: #12

## Problem and Why

The test-quality work of 2026-07-01..02 (`b7cae2a`..`4f42e34`, following `docs/specs/2026-07-01-test-quality-coverage-design.md` and `docs/plans/2026-07-01-test-quality-coverage-implementation.md`) relied on two development contracts that no spec records:

- The QA suite discovers every function defined in the module, public or private, and expects each one to live in a source file named after it with a matching unit test file. A private helper nested inside another function's file broke this discovery and had to be moved into its own file.
- A **source-mode import** has to provide every private function. Twice, a newly added private function was missing from **source-mode import** (`3a0fadf` for the vcpkg launch helper, `7cff107` for the empty-directory helper). Tests that run against the **built module** did not catch either gap.

Without specs, contributors adding a function have no stated rule for where it goes, how it is tested, or how it becomes available in both import modes, and the same class of bug can recur.

## Goals

- The specs state that each module function, public or private, lives in its own source file named after the function, with a same-named unit test file in the matching visibility folder.
- The specs state the per-function quality checks the QA suite applies, so a contributor knows what a new function must satisfy before the suite passes.
- The specs state that a **source-mode import** makes every private function available to the module, consistent with the **built module**.
- A unit test enforces the source-mode requirement, so the regression class behind `3a0fadf` and `7cff107` fails CI.

## Scope and Capabilities

### New Capabilities

None.

### Modified Capabilities

- `test-structure`: Adds requirements for one function per source file named after the function, a same-named unit test file per function, and the per-function quality checks the QA suite enforces.
- `module-internal-dependency-loading`: Adds a requirement that a **source-mode import** provides every private function, matching the set the **built module** provides.

## Non-Goals

- No specs for individual private helpers, including the hidden-file handling added to the empty-directory helper; the hidden-file fix is covered by unit tests, and no **port cmdlet** currently uses that helper.
- No restatement of the `Remove-NhcVcpkgPort` error-scenario behavior covered by issue #12's tests; `surface-vcpkg-exit-status` specifies that behavior.
- No code-coverage thresholds or other new test-quality targets.
- No change to module code or the build; the only test change is the source-mode import test.
- No spec for the QA suite's changelog checks.

## Impact

- `openspec/specs/test-structure/spec.md` and `openspec/specs/module-internal-dependency-loading/spec.md` gain requirements.
- `tests/Private/SourceModeImport.Tests.ps1` imports the module from source in a child process and fails if any function defined under `Public` or `Private` is missing from module scope, or if anything other than the public functions and their **legacy aliases** is exported.
- Archive order: archived last, after `surface-vcpkg-exit-status`.
- No module code, API, dependency, or workflow changes.
