# Agent Guidelines

## git Requirements

- `.gitignore` ignores by default - use opt-in rules to include additional tracked files or directories

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

## GitHub Templates

IMPORTANT: Retrieve the raw template content using builtin GitHub tools if available, `gh` if not

- Bugs: https://github.com/NaveHaus/.github/blob/main/.github/ISSUE_TEMPLATE/ai_agent_bug_report.md
- Features: https://github.com/NaveHaus/.github/blob/main/.github/ISSUE_TEMPLATE/ai_agent_feature_request.md
- Refactoring: https://github.com/NaveHaus/.github/blob/main/.github/ISSUE_TEMPLATE/ai_agent_refactor_task.md
- Pull Request: https://github.com/NaveHaus/.github/blob/main/.github/PULL_REQUEST_TEMPLATES/ai_agent_pull_request.md