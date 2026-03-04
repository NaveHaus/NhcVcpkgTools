## Context

The repository currently documents how to run Pester locally but has no GitHub Actions workflow, so regressions can land without automated verification.

This change adds a Windows-based CI workflow that runs on pushes and pull requests. It will:

- run PowerShell linting (diagnostics) via PSScriptAnalyzer and fail on warnings/errors
- run unit tests via Pester and upload an NUnit XML test result artifact

The repo’s current test suite includes Windows-centric assertions and path shapes, so the initial CI target is `windows-latest`.

## Goals / Non-Goals

**Goals:**

- Provide consistent, automated feedback on every PR and push:
  - lint failures appear as GitHub annotations
  - test failures are visible and test results are archived as an artifact
- Keep the workflow deterministic and straightforward to maintain.
- Align CI behavior with local workflows (prefer a shared lint entrypoint).

**Non-Goals:**

- Cross-platform CI matrix (Linux/macOS) in the initial iteration.
- Integration tests that execute real vcpkg commands (reserved for future work).
- Publishing the module, packaging, or release automation.
- SARIF/code-scanning integration (possible follow-on).

## Decisions

1. **Runner OS: `windows-latest`**

   - **Decision:** CI runs on Windows.
   - **Rationale:** Current tests contain Windows-specific expectations; Windows CI maximizes signal while keeping change scope small.
   - **Alternatives considered:** multi-OS matrix → likely immediate failures and higher maintenance.

2. **Workflow triggers: `pull_request` and `push`**

   - **Decision:** Run CI on PRs and on pushes.
   - **Rationale:** PR gating plus protection for direct pushes.

3. **Lint execution uses the repository lint runner**

   - **Decision:** Prefer calling `tools/lint.ps1 -Mode github` (from the `add-linter` change).
   - **Rationale:** Centralizes lint policy and avoids duplicating ScriptAnalyzer options in YAML.
   - **Dependency note:** This assumes `add-linter` lands first (or the workflow is updated in the same PR sequence).
   - **Alternatives considered:** run `Invoke-ScriptAnalyzer` directly in the workflow → simpler, but duplicates policy.

4. **Pester results are stored as an artifact**

   - **Decision:** Configure Pester to emit an NUnit XML file and upload it as a workflow artifact.
   - **Rationale:** Preserves test details beyond console output; supports later enhancements like test reporting/annotation.

5. **Dependency handling: install required PowerShell modules in CI**

   - **Decision:** Ensure Pester (v5+) and PSScriptAnalyzer are available on the runner.
   - **Rationale:** GitHub-hosted runners don’t guarantee the desired versions.
   - **Alternatives considered:** vendoring modules → reduces network reliance but adds repo weight and update overhead.

## Risks / Trade-offs

- **[PSGallery/network flakiness installing modules]** → Mitigation: pin versions; consider caching the PowerShell module path if install time becomes significant.
- **[Lint gate blocks contributions]** → Mitigation: keep rule set explicit and tune settings as needed; start with default rules but iterate quickly if noise is high.
- **[Windows-only CI misses cross-platform issues]** → Mitigation: treat as an incremental rollout; make tests platform-adaptive before expanding.

## Migration Plan

1. Add `.github/workflows/ci.yml` with a Windows job that runs lint then Pester.
2. Validate the workflow on a PR and ensure annotations appear for lint issues.
3. Optionally add a README badge once the workflow is stable.

## Open Questions

- Should lint and tests be separate jobs (parallel) or a single job (simpler)?
- Should the workflow upload additional artifacts (e.g., a structured lint report) for debugging?
- Do we want scheduled runs (nightly) later to catch flakiness and dependency changes?
