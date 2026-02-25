---
title: Example Commits and Templates
---

# Example Commits and Templates

## Feature Commit Example

```
feat(auth): add JWT authentication

Implement JWT-based authentication system with:
- Login endpoint with token generation
- Token validation middleware
- Refresh token support
```

## Bug Fix Example

```
fix(api): handle null values in user profile

Prevent crashes when user profile fields are null.
Add null checks before accessing nested properties.
```

## Refactor Example

```
refactor(database): simplify query builder

Extract common query patterns into reusable functions.
Reduce code duplication in database layer.
```

## Multi-file Commit Example

```
refactor(core): restructure authentication module

- Move auth logic from controllers to service layer
- Extract validation into separate validators
- Update tests to use new structure
- Add integration tests for auth flow

Breaking change: Auth service now requires config object
```

## Commit Template

```
<type>(<scope>): <short summary>

[optional body explaining why and what]

[optional footer: issues closed, breaking changes, etc.]