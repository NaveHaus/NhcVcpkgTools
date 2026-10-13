## Problem and Why

OpenSpec is being reintroduced after a gap (last archived change: `2026-03-18-implement-remove-nhcvcpkgports`). The main specs under `openspec/specs/` carry defects that predate that gap, and the retroactive changes that follow build on these specs:

- The `github-actions-ci` capability was never synced: `openspec/specs/github-actions-ci/` exists but holds no spec, and the archived delta from `2026-03-04-add-github-ci` no longer describes the CI workflow (CI gained a separate lint job on a Linux runner, explicit PSScriptAnalyzer provisioning, and trigger filters).
- `remove-ports` contradicts itself: two scenarios state that an empty `-Ports` array and unvalidated port names are passed to vcpkg, while the "Ports parameter validation" requirement in the same spec (and the module) rejects null or empty `-Ports` before vcpkg runs.
- `remove-ports` has a requirement with no scenario: "Common vcpkg arguments are supported" has none, and its three argument pass-through scenarios sit under "Quiet switch suppresses vcpkg output". OpenSpec refuses to archive any change to a spec in this state.
- `remove-ports` and `install-ports-tests` have placeholder (`TBD`) Purpose sections.

Without repair, later changes would modify an inconsistent baseline and the CI contract would remain undocumented.

## Goals

- The main specs describe the CI workflow as it behaves at the current `master` (`6f737c0`), including the PSScriptAnalyzer provisioning fix from `29e3d9e`.
- `remove-ports` contains no requirements or scenarios that contradict each other or the module's behavior, and every requirement has at least one scenario.
- Every main spec touched by this change has a real Purpose statement instead of a placeholder.

## Scope and Capabilities

### New Capabilities

- `github-actions-ci`: The repository's continuous integration contract: when CI runs, which checks it performs (lint, module import, build, and tests), on which runner operating systems, what makes a run fail, and which results it publishes.

### Modified Capabilities

- `remove-ports`: The "Mutually exclusive parameter sets for Ports and Outdated" requirement is replaced by "Ports and Outdated parameter sets are mutually exclusive", which keeps its other scenarios and drops the two that contradict the "Ports parameter validation" requirement. OpenSpec does not allow a modified requirement to drop scenarios, so the requirement is replaced under a new name. "Common vcpkg arguments are supported" gains the three argument pass-through scenarios; their misplaced copies under the Quiet requirement go away when `surface-vcpkg-exit-status` replaces that requirement.

## Non-Goals

- No change to the CI workflow, module code, or tests; this change only brings specs in line with existing behavior.
- No requirement for CI on branch pushes. The workflow's push trigger carries a path filter with only an exclusion pattern; at `master`, branch pushes do not start CI and only tag pushes do. Whether that is intended is an open question, so the spec covers only the pull-request trigger until it is answered.
- No renaming of plural command names in specs; `rename-public-cmdlets` owns that.
- No restatement of vcpkg exit status or `-Quiet` behavior; `surface-vcpkg-exit-status` owns that.
- No backfill of functional specs for `Export-NhcVcpkgPort` or `Install-NhcVcpkgPort` (deferred to a separate per-cmdlet effort).
- No specs for private helper functions.
- No rewrite of `remove-ports` requirements that are implementation-flavored but not contradictory.

## Impact

- `openspec/specs/github-actions-ci/spec.md` is created from this change's delta spec.
- `openspec/specs/remove-ports/spec.md` loses two contradictory scenarios.
- Purpose sections are outside the delta-spec format, so the Purpose text for `remove-ports` and `install-ports-tests` is set by a direct edit when this change is synced to the main specs, using the current singular-noun command names. The new `github-actions-ci` spec gets its Purpose from this change's delta spec.
- Archive order: this change is archived first, before `rename-public-cmdlets`, `surface-vcpkg-exit-status`, and `test-quality-coverage`, whose delta specs assume this baseline.
- No code, API, dependency, or workflow changes.
