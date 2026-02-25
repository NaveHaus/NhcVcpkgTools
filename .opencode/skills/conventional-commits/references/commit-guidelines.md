---
title: Commit Guidelines
---

# Commit Guidelines

## Commit Message Format

The commit message should follow the Conventional Commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

## Commit Message Guidelines

**DO:**

- Use imperative mood ("add feature" not "added feature")
- Keep first line under 50 characters
- Capitalize first letter
- No period at end of summary
- Explain WHY not just WHAT in body

**DON'T:**

- Use vague messages like "update" or "fix stuff"
- Include technical implementation details in summary
- Write paragraphs in summary line
- Use past tense

## Multi-file Commits

When committing multiple related changes:

```
refactor(core): restructure authentication module

- Move auth logic from controllers to service layer
- Extract validation into separate validators
- Update tests to use new structure
- Add integration tests for auth flow

Breaking change: Auth service now requires config object
```

## Scope Examples

**Frontend:**

- `feat(ui): add loading spinner to dashboard`
- `fix(form): validate email format`

**Backend:**

- `feat(api): add user profile endpoint`
- `fix(db): resolve connection pool leak`

**Infrastructure:**

- `chore(ci): update Node version to 20`
- `feat(docker): add multi-stage build`

## Breaking Changes

Indicate breaking changes clearly:

```
feat(api)!: restructure API response format

BREAKING CHANGE: All API responses now follow JSON:API spec

Previous format:
{ "data": {...}, "status": "ok" }

New format:
{ "data": {...}, "meta": {...} }

Migration guide: Update client code to handle new response structure