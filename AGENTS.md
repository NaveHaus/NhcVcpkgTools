# AGENTS.md

## Build / test commands

- Generate the module:
  ```powershell
  ./build.ps1 -ResolveDependency -Tasks noop
  ./build.ps1 -Tasks build
  ```

- Execute all tests (canonical — builds the module and sets `PSModulePath`
  so the QA tests under `tests/QA` are discovered, matching CI):
  ```powershell
  ./build.ps1 -Tasks test
  ```
  A bare `Invoke-Pester` runs the unit tests but fails QA discovery unless
  the module has already been built and is on `PSModulePath`.

## Repo-specific constraints

- Ignore openspec artifacts under the `openspec` directory unless the user requests otherwise
- A test-driven development (TDD) red/green/refactor process MUST be implemented when changing or adding production code.
- Use the `nhc-conventional-commit` skill to generate commit messages.

## Branch and pull request workflow (MANDATORY)

- Every fix, feature, or cleanup MUST be done on a new branch — never commit
  directly to `master`/`main`.
- After committing, push the branch and open a pull request. Reference the
  closing issue in the PR body with `Closes #<n>`.
- Mark all test-plan checklist items as complete (`- [x]`) when the
  corresponding verification has already been performed before opening the PR.

## Git safety (MANDATORY)

- Never commit secrets, API keys, or credentials.
- Don't modify git configuration.
- Don't use `--no-verify` or bypass hooks unless explicitly requested.
- Don't force-push protected branches (e.g. `master`, `main`).
- Don't auto-fix git errors — surface the error and ask the user first, then
  offer 1-4 options for resolving it.
- Warn before committing to `master`/`main`, and warn if git reports an error
  or a missing remote branch.
- Always use absolute paths with filesystem tools.
- Don't modify or delete anything listed in `.gitignore`.
- Run build and test commands after modifications.

## `tests` Directory Layout
```
  tests/
  ├── Private/
  ├── Public/
  ├── Integration/
  ├── Tools/
  ├── QA/
  └── Shared/
```
- **Private**: holds all tests corresponding to Private functions and functionality (Unit tests).
- **Public**: holds all tests corresponding to Public functions and functionality (Unit tests).
- **Integration**: holds all integration tests that exercise Public functions and functionality to ensure correct inputs and outputs.
- **Tools**: holds all tests related to supporting tools under the `tools` directory.
- **QA**: holds all tests related to code quality and security.
- **Shared**: holds functions and functionality that can be consumed by any test.

## Common Issues and Solutions
- `Invoke-Pester` fails with an error indicating that the `NhcVcpkgTools` module cannot be found.
  - **Possible Reason**: the module has not been built for the first time.
    - **Solution**:
      ```powershell
      ./build.ps1 -ResolveDependency -Tasks noop
      ./build.ps1 -Tasks build
      ```
  - **Possible Reason**: a `./build.ps1` invocation subequently fails after the module has been built for the first time.
    - **Solution**: Review the errors from `./build.ps1`, present the user with a summary of the error(s), then:
       - IF AND ONLY IF you understand the error(s), offer the user 2-4 possible fixes; otherwise
       - State that you are unsure how to proceed and offer to work iteratively with the user to address each issue one-by-one until resolved.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).