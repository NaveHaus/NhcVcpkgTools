# Documentation update design for issues #22 and #24

## Goal

Close issues #22 and #24 in a single documentation-only pull request by
adding a root `CHANGELOG.md` and correcting the README license badge URL.

## Scope

This change covers:

- Adding `CHANGELOG.md` at the repository root.
- Using Keep a Changelog structure with an `Unreleased` section and backfilled
  release sections for the existing tagged releases.
- Populating each release section with the exact PR titles for that release
  range, verbatim, without paraphrasing or summarizing the entries.
- Updating the README license badge to the fixed MIT badge URL.

This change does not cover production code, test code, release automation, or
any additional documentation cleanup beyond the two issue targets.

## Design

### Changelog structure

The new `CHANGELOG.md` will follow Keep a Changelog style:

- `## [Unreleased]`
- `## [1.1.1]`
- `## [1.1.0]`
- `## [1.0.0]`

The release sections will be ordered newest to oldest. Each bullet inside a
release section will use the exact PR title associated with that release
window. No line item will be rewritten into a summary sentence, and no release
note will be inferred beyond what the PR title already states.

The source of truth for the backfill will be the repository history already
present in this checkout:

- `1.1.1` covers the post-`1.1.0` documentation and test follow-up work.
- `1.1.0` covers the vcpkg exit-status work and the associated docs/test
  cleanup.
- `1.0.0` anchors the initial public release.

If a release window contains multiple merged PR titles, all of them will be
listed under that release section in the same order they were merged.

### README badge fix

The README license badge will be updated to the fixed shields.io MIT badge:

`https://img.shields.io/badge/License-MIT-yellow.svg`

This is a direct URL replacement only. The surrounding README text and the rest
of the documentation stay unchanged.

## Data flow

There is no runtime data flow change. The only affected artifacts are static
documentation files:

1. Git history identifies the release windows.
2. `CHANGELOG.md` records the release sections using verbatim PR titles.
3. `README.md` points to the corrected badge URL.

## Error handling

Because this is a documentation-only change, the only meaningful failure modes
are editorial:

- Missing or out-of-order release headings.
- Changelog entries rewritten as summaries instead of exact titles.
- A stale or incorrect badge URL in the README.

The implementation should fail closed on ambiguity: if a release title cannot be
confirmed, leave it out rather than inventing wording.

## Validation

Verification for the documentation update should include:

- Inspecting the final `CHANGELOG.md` for Keep a Changelog structure.
- Confirming that all release bullets are exact titles, not summaries.
- Confirming the README badge URL matches the fixed MIT badge path.
- Running the repository's canonical build and test commands after the doc
  change to ensure the docs update does not introduce any incidental issues:
  - `./build.ps1 -Tasks build`
  - `./build.ps1 -Tasks test`

## PR boundaries

Use a single documentation PR that closes both issues:

- Closes #22
- Closes #24
