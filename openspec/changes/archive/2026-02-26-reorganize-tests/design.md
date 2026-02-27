## Context

The repository currently stores all tests in a flat `tests/` directory and keeps module source under `NhcVcpkgTools/public` and `NhcVcpkgTools/private`. The change introduces a conventional Public/Private/Integration test layout and capitalizes source folders to match common PowerShell project structure, without changing test discovery or filenames.

## Goals / Non-Goals

**Goals:**
- Establish a clear Public/Private/Integration test layout while keeping `*.Tests.ps1` filenames.
- Preserve default Pester discovery (`Invoke-Pester -Path tests`) without requiring configuration changes.
- Align source folder casing with a conventional `Public/` and `Private/` structure.
- Keep tests aligned with the visibility of the function under test.

**Non-Goals:**
- Changing test semantics, assertions, or the set of tested functions.
- Introducing or running integration tests as part of this change.
- Modifying module APIs or runtime behavior.

## Decisions

- **Keep filenames as `*.Tests.ps1`.**
  - *Rationale:* Preserves Pester default discovery and avoids changes to README or CI commands.
  - *Alternatives:* Rename to `*.UnitTests.ps1` (rejected: would require custom discovery patterns).

- **Categorize tests by function visibility using `git mv` for moves.**
  - *Rationale:* The placement rule is simple and deterministic: public functions → `tests/Public`, private functions → `tests/Private`, and `git mv` preserves history.
  - *Alternatives:* Tag-only classification or mixed placements (rejected: less discoverable folder organization).

- **Case-only renames via two-step `git mv`.**
  - *Rationale:* Ensures Git records casing changes reliably on Windows.
  - *Alternatives:* Direct rename in-place (rejected: can be ignored by Git on case-insensitive filesystems).

- **Integration tests reside under `tests/Integration` and are tagged `Integration`.**
  - *Rationale:* Provides a home for future tests while allowing tag-based selection when desired.
  - *Alternatives:* Separate discovery patterns (rejected for now: adds configuration overhead).

## Risks / Trade-offs

- **[Risk] Case-only renames not recorded correctly** → *Mitigation:* Use two-step `git mv` (temp name → final casing).
- **[Risk] Dot-sourcing paths break after relocation** → *Mitigation:* Update all relative paths in tests and `NhcVcpkgTools.psm1` to the new casing and folder structure; validate by running Pester.
- **[Risk] Confusion over integration tests running by default later** → *Mitigation:* Document tagging expectations when integration tests are added; optionally add an exclude-tag example later.

## Migration Plan

1. Rename `NhcVcpkgTools/public` → `NhcVcpkgTools/Public` and `NhcVcpkgTools/private` → `NhcVcpkgTools/Private` via two-step `git mv`.
2. Update `NhcVcpkgTools.psm1` dot-sourcing paths to `Public/` and `Private/`.
3. Create `tests/Public`, `tests/Private`, and `tests/Integration` (with `.gitkeep`).
4. Move tests into `tests/Public` or `tests/Private` using `git mv` based on function visibility.
5. Update test dot-sourcing paths to match new folder structure.
6. Run Pester to ensure test discovery and paths are correct.

## Open Questions

- None identified for this change.
