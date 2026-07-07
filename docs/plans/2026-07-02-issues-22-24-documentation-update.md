# Issues #22 and #24 Documentation Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a root `CHANGELOG.md` with verbatim PR-title backfill and fix the README license badge URL to close issues #22 and #24 in one docs-only PR.

**Architecture:** Keep the change static and tightly scoped. One file will become the canonical release-history document, and the README will receive a single badge URL replacement. The changelog should not invent summaries; it should reuse the exact release/PR titles already present in the repository history, ordered newest release to oldest release.

**Tech Stack:** Markdown, Git history, PowerShell build scripts, GitHub issue references.

---

## File structure

- Create `CHANGELOG.md`: root changelog in Keep a Changelog format.
- Modify `README.md`: replace the license badge URL with the fixed MIT badge path.

---

### Task 1: Collect exact release titles for the backfill

**Files:**
- Read: `gh pr list --repo NaveHaus/NhcVcpkgTools --state merged --limit 100 --json number,title,mergedAt`

- [ ] **Step 1: Inspect the tagged release boundaries**

Run:

```powershell
gh pr list --repo NaveHaus/NhcVcpkgTools --state merged --limit 100 --json number,title,mergedAt
```

Expected:

- The merged PR list includes the release-history PR titles and merge timestamps.
- The titles are taken from PRs, not commit subjects.

- [ ] **Step 2: Map titles to release sections**

Use the following verbatim PR titles in the changelog, grouped by release window and kept in merge order:

```markdown
## [1.1.1]
- Add test-quality coverage for helpers and remove errors

## [1.1.0]
- refactor: clear PSScriptAnalyzer warnings across module
- fix: surface vcpkg exit codes in port cmdlets

## [1.0.0]
- Implement Remove-NhcVcpkgPorts
- feat(config): rely on global opencode configuration
- feat: allow the module to be imported without building
- Add AGENTS.md
- migrate-to-sampler change not fully archived
- Mark validation tasks as complete for migrate-to-sampler
- Migrate the module to Sampler
- ci: add workflow for linting and testing
```

These are the exact line items to paste into `CHANGELOG.md`; do not paraphrase them into summary prose.

- [ ] **Step 3: Confirm the release ordering**

Expected ordering in the final file:

1. `Unreleased`
2. `1.1.1`
3. `1.1.0`
4. `1.0.0`

---

### Task 2: Create the root changelog

**Files:**
- Create: `CHANGELOG.md`

- [ ] **Step 1: Write the changelog file**

Create `CHANGELOG.md` with this exact structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1]
- docs: record test-quality coverage design
- test: cover helper and remove error cases
- fix: load empty-directory helper in source module
- test: address review coverage feedback
- test: avoid parsed redirection in quiet coverage
- test: refine review follow-up tests

## [1.1.0]
- chore: move to Claude and simplify AGENTS.md
- chore: unhide ./docs in .gitignore
- feat: add Invoke-Vcpkg helper that reports real vcpkg exit status
- fix: surface vcpkg exit status in Install-NhcVcpkgPorts
- fix: surface vcpkg exit status in Remove-NhcVcpkgPorts
- fix: surface vcpkg exit status in Export-NhcVcpkgPorts
- docs: complete comment-based help for Invoke-Vcpkg
- fix: register Invoke-Vcpkg in source module loader
- chore: record plan for fixing issue #17
- test: cover vcpkg launch failure in port cmdlets
- refactor: clear PSScriptAnalyzer warnings across module
- docs: recommend ./build.ps1 -Tasks test for full suite
- docs: fix README examples to match cmdlet parameters

## [1.0.0]
- feat: add Remove-NhcVcpkgPorts function
```

Do not add explanatory summaries inside the release sections. The bullets themselves are the release notes.

- [ ] **Step 2: Verify the file content**

Run:

```powershell
Get-Content -LiteralPath .\CHANGELOG.md
```

Expected:

- The file starts with `# Changelog`.
- The release sections appear in newest-to-oldest order.
- Every bullet matches the exact titles listed in Task 1.

---

### Task 3: Fix the README license badge

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the badge URL**

Update the license badge link in `README.md` to:

```markdown
https://img.shields.io/badge/License-MIT-yellow.svg
```

Keep the badge label and surrounding README content unchanged.

- [ ] **Step 2: Verify the README snippet**

Run:

```powershell
Get-Content -LiteralPath .\README.md | Select-String -Pattern 'img.shields.io'
```

Expected:

- The license badge line now uses the fixed MIT badge URL.

---

### Task 4: Validate the docs-only update

**Files:**
- No additional file changes expected unless verification finds a docs defect.

- [ ] **Step 1: Run the build**

Run:

```powershell
./build.ps1 -Tasks build
```

Expected:

- Build completes successfully.
- No new changelog or README-related warnings appear.

- [ ] **Step 2: Run the test suite**

Run:

```powershell
./build.ps1 -Tasks test
```

Expected:

- Canonical test run completes successfully.
- QA discovery still works with the new changelog in place.

- [ ] **Step 3: Spot-check the final diff**

Run:

```powershell
git status --short
git diff --stat
```

Expected:

- Only `CHANGELOG.md` and `README.md` are changed for the docs update.

---

### Task 5: Commit and open the docs PR

**Files:**
- Staged docs changes only.

- [ ] **Step 1: Create the commit**

Use the conventional commit message:

```powershell
git add CHANGELOG.md README.md
git commit -m "docs: add changelog and fix license badge"
```

- [ ] **Step 2: Push the branch and open the PR**

Open one pull request that closes both issues and includes:

- `Closes #22`
- `Closes #24`

Expected:

- One docs-only PR lands with the changelog backfill and badge fix together.
