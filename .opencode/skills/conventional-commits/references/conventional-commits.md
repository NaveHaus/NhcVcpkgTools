---
title: Conventional Commits Specification
---

# Conventional Commits Specification

The Conventional Commits specification is a convention for writing standardized commit messages. It provides an easy set of rules for creating an explicit commit history; which makes it easier to write automated tools on top of.

## Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

## Breaking Changes

Breaking changes must be indicated by adding an exclamation mark (!) after the type/scope, or by including BREAKING CHANGE in the footer.

Examples:

```
feat!: drop support for Node 6
```

or

```
fix: make API compatible with new client

BREAKING CHANGE: The API endpoint has changed from /v1 to /v2
```

## Benefits

- Provides a clear history of changes
- Automates versioning and changelog generation
- Improves collaboration and communication

## Further Reading

- [Conventional Commits Official Site](https://www.conventionalcommits.org/en/v1.0.0/)