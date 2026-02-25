---
name: conventional-commits
description: Commit convention, message best practices, conventional commits for use when writing git commit messages.
---

# Conventional Commits Skill

## Table of Contents

- [Quick Workflow](#quick-workflow)
- [Commit Message Format](#commit-message-format)
- [Analyzing Changes](#analyzing-changes)
- [Interactive Commit Helper](#interactive-commit-helper)
- [Amending Commits](#amending-commits)
- [Best Practices](#best-practices)
- [Commit Message Checklist](#commit-message-checklist)
- [References](#references)

## Quick Workflow

1. Review staged changes:

```bash
git diff --staged
```

2. Identify commit type (feat, fix, chore, etc.) and scope.
3. Write a concise, imperative summary line.
4. Add body explaining why and what changed, if needed.
5. Note any breaking changes clearly.
6. Commit with:

```bash
git commit -m "type(scope): summary"
```

## Commit Message Format

Follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

For details, examples, and templates, see the references below.

## Analyzing Changes

Use git commands to inspect what you are committing:

```bash
git status
git diff --staged
git diff --staged --stat
git diff --staged path/to/file
```

## Interactive Commit Helper

Stage changes selectively and commit:

```bash
git add -p
git diff --staged
git commit -m "type(scope): description"
```

## Amending Commits

Fix the last commit message or add more changes:

```bash
git commit --amend
git add forgotten-file.js
git commit --amend --no-edit
```

## Best Practices

- Atomic commits: one logical change per commit
- Test before commit
- Reference issues when applicable
- Keep commits focused and readable
- Write commit messages for humans

## Commit Message Checklist

- [ ] Type is appropriate (feat/fix/docs/etc.)
- [ ] Scope is specific and clear
- [ ] Summary is under 50 characters
- [ ] Summary uses imperative mood
- [ ] Body explains WHY not just WHAT
- [ ] Breaking changes are clearly marked
- [ ] Related issue numbers are included

## References

- [Commit Guidelines](references/commit-guidelines.md)
- [Example Commits and Templates](references/templates.md)
- [Conventional Commits Specification](references/conventional-commits.md)