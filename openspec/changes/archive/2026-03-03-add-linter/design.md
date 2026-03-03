## Context

The repository currently has a growing Pester unit test suite but no standardized, version-controlled linting entrypoint. Contributors run PowerShell tooling ad-hoc, and CI cannot enforce consistent style/safety checks.

This change introduces a repo-level lint command (`tools/lint.ps1`) that can be executed both locally and in GitHub Actions, with output tailored to the environment.

Constraints:

- The project targets PowerShell 7.4+ and uses Pester 5+.
- Lint output in PRs should be reviewer-friendly (compact) while local output should be developer-friendly (rich).
- Lint scope should be limited to `NhcVcpkgTools/`, `tests/`, and `tools/`.

## Goals / Non-Goals

**Goals:**

- Provide a single lint entrypoint (`tools/lint.ps1`) that codifies:
  - which directories are analyzed (`NhcVcpkgTools/`, `tests/`, `tools/`)
  - which settings file is used (`PSScriptAnalyzerSettings.psd1`)
  - how results are presented (`local` vs `github` mode)
  - what constitutes failure (any warnings or errors)
- Produce GitHub Actions annotations in CI using the standard workflow-command format while keeping messages compact.
- Keep the policy explicit and revisionable via `PSScriptAnalyzerSettings.psd1` with default rules enabled.

**Non-Goals:**

- Creating custom ScriptAnalyzer rules or enforcing a specific stylistic regime beyond defaults (initially).
- Generating SARIF / code-scanning output (can be a later enhancement).
- Treating lint as Pester tests or merging lint results into NUnit output.
- Cross-platform lint runner guarantees (CI will be Windows-first; local usage can vary).

## Decisions

1. **Centralize lint behavior in `tools/lint.ps1`**

   - **Decision:** CI and developers will run a shared script rather than embedding ScriptAnalyzer logic in multiple places.
   - **Rationale:** Keeps policy consistent; reduces drift between local expectations and CI enforcement.
   - **Alternatives considered:**
     - Run `Invoke-ScriptAnalyzer` directly in CI with duplicated flags → simpler initially, but policy drifts.
     - Model lint as Pester tests → unifies reporting but violates the “diagnostics” preference.

2. **Two output modes: `local` and `github`**

   - **Decision:** The lint script supports a mode switch.
     - `github` mode emits workflow commands (`::warning`/`::error`) using compact messages.
     - `local` mode emits rich, human-readable output suitable for iterative fixing.
   - **Rationale:** PR review needs concise annotations; local fixing benefits from more context.
   - **Alternatives considered:** separate scripts for CI vs local → adds maintenance cost.

3. **Strict gating: fail on warnings and errors**

   - **Decision:** Any warning or error from ScriptAnalyzer makes the command exit non-zero.
   - **Rationale:** Establishes a clear quality bar and prevents gradual lint debt accumulation.
   - **Trade-off:** May be noisy initially; policy can be relaxed later if needed.

4. **Scope limited to `NhcVcpkgTools/`, `tests/`, `tools/`**

   - **Decision:** Only analyze those directories.
   - **Rationale:** Avoid linting generated/archival content (e.g., `.git`, `openspec/`, `.opencode/`).
   - **Alternatives considered:** repo-wide linting → higher noise and unclear ownership.

5. **Settings file is the policy anchor (defaults enabled)**

   - **Decision:** Add `PSScriptAnalyzerSettings.psd1` and configure the lint runner to use it by default.
   - **Rationale:** Makes the policy explicit, reviewable, and easy to tune as the repo evolves.

6. **Annotation path normalization**

   - **Decision:** Prefer file paths relative to repository root when emitting annotations.
   - **Rationale:** GitHub annotations link reliably when paths match checkout paths.
   - **Alternatives considered:** emit absolute paths → can work, but is more brittle across runners.

## Risks / Trade-offs

- **[Initial noise from defaults]** → Mitigation: iterate on settings file (exclude rules/suppressions) if necessary; keep changes scoped to the three directories.
- **[Tooling/version drift]** → Mitigation: CI will pin module versions; lint script should surface versions in local mode output.
- **[Annotation linking issues due to path formatting]** → Mitigation: normalize to repo-relative paths where possible and preserve line/column when present.
- **[Harder to unit test a script entrypoint]** → Mitigation: structure the script so the formatting/exit-code logic can be exercised via Pester (by dot-sourcing and mocking ScriptAnalyzer invocation).

## Migration Plan

1. Add `PSScriptAnalyzerSettings.psd1` (defaults enabled).
2. Add `tools/lint.ps1` and document local usage in `README.md` under "Running Tests".
3. Add Pester tests for the lint runner’s core behavior (mode formatting + exit codes) without requiring real ScriptAnalyzer execution.
4. (Follow-on change) Wire `tools/lint.ps1 -Mode github` into GitHub Actions.

## Open Questions

- Should `Information`-severity ScriptAnalyzer findings be emitted as `::notice` in GitHub mode or suppressed?
- Do we want a single “summary” line/group in GitHub logs in addition to per-finding annotations?
- Which exact versions of PSScriptAnalyzer/Pester should CI pin to balance stability vs updates?