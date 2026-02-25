# Conventional Commit Examples (Condensed)

Representative examples for each commit type.

---

## feat

Simple:

```
feat: add user profile page
```

With scope:

```
feat(auth): add two-factor authentication
```

With body + issue:

```
feat(api): add webhook signature verification

Add HMAC validation for incoming webhooks.

Closes #456
```

Breaking change:

```
feat(api)!: migrate to OAuth

BREAKING CHANGE: API keys no longer supported.
```

---

## fix

Simple:

```
fix: resolve login redirect loop
```

With explanation:

```
fix(auth): prevent race condition on login

Add locking to avoid concurrent session corruption.

Fixes #789
```

Security:

```
fix(security): prevent SQL injection

Replace string interpolation with parameterized queries.

Fixes GHSA-2024-001
```

---

## docs

```
docs: update README setup instructions
docs(api): add webhook documentation
```

With body:

```
docs(contributing): add review guidelines

Include security and performance checklist.

Related to #234
```

---

## refactor

```
refactor: extract validation service
refactor(models): simplify tenant scoping
```

Larger:

```
refactor(services): return Result objects

No behavior changes.
```

---

## perf

```
perf: add index for user lookups
```

With metrics:

```
perf(api): eliminate N+1 queries

Reduce page load from 2.3s to 0.3s.
```

---

## test

```
test: add auth specs
test(integration): add webhook tests
```

Comprehensive:

```
test(services): increase CreateOrderService coverage

Raise coverage from 67% to 95%.
```

---

## chore / build / ci

```
chore(deps): bump rails to 7.2.0
build(docker): optimize production image
ci: add parallel test execution
```

---

## style

```
style: format code
style(ui): adjust button spacing
```

---

## revert

```
revert: revert "feat: add export feature"

This reverts commit a1b2c3d4.
```

---

## Multiple Footers

```
feat(ml): add document classification

Closes #123
Related to #100
Co-authored-by: Jane <jane@example.com>
```

---

## Anti-Patterns (Avoid)

Vague:

```
fix: update stuff
```

Past tense:

```
feat: added profile
```

Capitalized:

```
Feat: Add profile
```

Trailing period:

```
feat: add profile.
```

Too long:

```
feat: add very large feature with many unrelated concerns
```

Multiple changes:

```
feat: add profile, fix bug, update docs
```

Missing type:

```
add profile
```

---

## Minimal Template

```
<type>(<scope>): <description>

[body]

[footer]
```

Types:
`feat, fix, docs, style, refactor, perf, test, chore, build, ci, revert`

Breaking:

```
feat!: change API
# or
BREAKING CHANGE: description
```

Issues:

```
Closes #123
Fixes #456
Related to #789
```