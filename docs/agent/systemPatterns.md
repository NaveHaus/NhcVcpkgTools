# System Patterns

## System Architecture

- Modular PowerShell scripts structured as a reusable module.
- Public commands exposed in the 'public' folder.
- Private helper functions isolated in a 'private' folder for encapsulation.

## Key Technical Decisions

- Use of PowerShell advanced functions with parameter validation.
- Logging through verbose and error streams.
- Normalize all paths to avoid cross-platform issues.
- Use of triplet-aware configurations for vcpkg builds.

## Design Patterns

- Command pattern for exposing public functionality.
- Separation of concerns between public commands and private utilities.
- Idempotent operations to enable safe repeated executions.

## Component Relationships

- Public commands interact with private helpers for tasks like path normalization, argument processing, and executable detection.
- Scripts rely on consistent triplet and environment variable passing.

## Critical Implementation Paths

- Install command workflow: validate inputs → normalize paths → detect vcpkg executable → perform install → log results.
- Export command workflow: validate inputs → prepare export directory → execute export → handle output and errors.