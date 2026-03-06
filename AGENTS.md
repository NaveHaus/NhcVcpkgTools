# Context, Rules, and Guidelines for AI Agents
## Tech stack
- PowerShell 7.4+.
- Pester 5.7+.
- GitHub Flavored Markdown.

## Safety & Operational Rules (MANDATORY)
To maintain repository integrity, agents MUST follow these rules:
- **No Secrets**: NEVER commit secrets, API keys, or credentials.
- **Git Safety**:
  - DO NOT modify git configuration.
  - DO NOT use `--no-verify` or bypass hooks unless explicitly requested.
  - DO NOT force push to protected branches, e.g. `master` or `main`.
  - DO NOT automatically fix `git` errors---ALWAYS ask the user for confirmation first.
  - DO warn the user if attempting to commit to `master` or `main`.
  - DO warn the user if `git` returns an error or reports that the remote branch is missing.
  - DO offer to resolve `git` errors, presenting the user with 1-4 options for doing so.
- **Path Handling**: Always use absolute paths when interacting with file system tools.
- **Verification**: Always run build and test commands after modifications.

## Terminology
- **openspec**: An artifact-driven workflow for managing software changes (features, fixes, etc.) through structured specifications and tasks.
- **opsx-***: Shortcut commands for interacting with the OpenSpec workflow.
- **nhc-opsx-commit**: A helper command that uses OpenSpec artifacts and the `conventional-commits` skill to generate compliant git commit messages.

## Process
### Requirements (MANDATORY)
- An `openspec` workflow MUST be used to implement code additions and modifications.
- An `openspec` workflow MAY be used to implement documentation additions and/or modifications.
- The `nhc-opsx-commit` command MUST be used to generate a `git` commit message and commit changes made WITH an `openspec` workflow.
- The `conventional-commits` skill MUST be used to generate a `git` commit message for changes made WITHOUT an `openspec` workflow.
- If unsure about which commit strategy applies, you MUST ask the user to avoid generating spurious or erroneous commits.

### Required Commands (MANDATORY)
To ensure consistency and correctness, agents MUST use these commands:

1. **Environment Setup & Dependency Resolution:**
   - `./build.ps1 -ResolveDependency -Tasks noop`: Locally installs all modules required for testing under `output/RequiredModules`.
2. **Building the Project:**
   - `./build.ps1 -Tasks build`: Prepares the module for testing, packaging, and distribution.
3. **Running Tests:**
   - `./build.ps1 -Tasks test`: Executes all tests configured in `build.yaml` under the `Pester` branch.

### OpenSpec Workflow Details
`openspec` workflows ensure changes are well-defined and verifiable through these artifacts:
- **spec**: The high-level design and requirements.
- **delta-spec**: Detailed technical specifications of the changes.
- **tasks**: Actionable implementation steps.

Most common sequence of `openspec` operations:
1. `opsx-new <name>`: Initialize the change.
2. `opsx-ff <name>`: Generate/update artifacts.
3. `opsx-apply <name>`: Implement the tasks (following TDD process - see [Testing](#testing)).
4. `./build.ps1 -Tasks test`: Verify all tests before completing the change.
5. `opsx-verify <name>`: Validate implementation against specs (see [Error Handling Guidance](#error-handling-guidance) if this fails).
6. `git add ./openspec/ <paths-to-changed-files-and-directories>`: Prepare to commit the changes.
7. `nhc-opsx-commit`: Generate a `conventional-commits` `git` commit message based on the changes and complete the commit.
8. `opsx-sync <name>`: Make change specs permanent.
9. `opsx-archive <name>`: Archive the change.
10. `git add ./openspec/`: Prepare to commit the archived change artifacts.
11. `nhc-opsx-commit`: Generate a `conventional-commits` `git` commit message based on the changes and complete the commit.

## Testing
### Requirements (MANDATORY)
- A test-driven development (TDD) red/green/refactor process MUST be implemented when changing or adding code:
  1. Create or update a test to reflect the desired change (Red), making sure the test initially FAILS by implementing only the bare-minimum skeleton needed to invoke the test.
    - Use `Invoke-Pester` to verify the test fails by invoking the containing script; e.g. `Invoke-Pester -Script ./tests/Private/Get-DefaultTriplet.Tests.ps1`
  2. Implement the minimum changes that make the test PASS (Green).
    - Use `Invoke-Pester` to verify the test passes by invoking the containing script; e.g. `Invoke-Pester -Script ./tests/Private/Test-AbsolutePath.Tests.ps1`
  3. Refactor the code and tests for clarity and efficiency (Refactor).
    - After each refactor, use `Invoke-Pester` to verify the test passes by invoking the containing script; e.g. `Invoke-Pester -Script ./tests/Private/Join-RelativePath.Tests.ps1`
- ALL changes to existing code MUST be tested by updating ALL relevant existing Unit and Integration tests following TDD.
- ALL new code MUST be tested by creating new Unit tests following TDD.
- Integration tests MAY be added for any code change or addition---ask the user if you are unsure if one is needed.
- Files MUST follow the naming convention: `*.Tests.ps1`.
- Tests MUST be stored under the `tests/` directory.
- ALL tests MUST be verified once a change is complete by running `./build.ps1 -Tasks test`.

### Test Types & Expectations
- **Unit Tests**: Exercise individual functions in isolation. Required for ALL new or modified code (Private or Public).
- **Integration Tests**: Exercise Public functions to ensure correct system interaction (e.g., file system, vcpkg). Optional, depending upon user requirements.
  - `./build.ps1 -Tasks test`

### `tests` Directory Layout
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

## Example Workflows
### One-Shot Implementation
Can be used for simple changes that require no investigation or decision making prior to implementation:
- Generate the `openspec` change artifacts in one shot:
  - `opsx-new <change-name>`
  - `opsx-ff <change-name>`
- Implement and verify the change:
  - `opsx-apply <change-name>`
  - `./build.ps1 -Tasks test`
  - `opsx-verify <change-name>`
- Locally commit the working `openspec` artifacts and associated project changes:
  - `git add ./openspec/ <changed-files-and-or-directories>`; e.g.:
    ```bash
    git add ./openspec/ ./NhcVcpkgTools/ ./build.ps1
    ```
  - `nhc-opsx-commit`
- Locally archive the `openspec` completed change artifacts:
  - `opsx-sync <change-name>`
  - `opsx-archive <change-name>`
  - `git add ./openspec/`
  - `nhc-opsx-commit`
### One-Shot Exploration to Implementation
Can be used for straightforward changes that require some upfront investigation and/or decision making prior to implementing.
- Interactively research and investigate a change with the user:
  - `opsx-explore <topic>`
- Generate the `openspec` change artifacts in one shot:
  - `opsx-new <change-name>`
  - `opsx-ff <change-name>`
- Implement and verify the change:
  - `opsx-apply <change-name>`
  - `./build.ps1 -Tasks test`
  - `opsx-verify <change-name>`
- Locally commit the working `openspec` artifacts and associated project changes:
  - `git add ./openspec/ <changed-files-and-or-directories>`; e.g.:
    ```bash
    git add ./openspec/ ./NhcVcpkgTools/ ./build.ps1
    ```
  - `nhc-opsx-commit`
- Locally archive the `openspec` completed change artifacts:
  - `opsx-sync <change-name>`
  - `opsx-archive <change-name>`
  - `git add ./openspec/`
  - `nhc-opsx-commit`
### Iterative Exploration to Implementation
Can be used for complex changes or changes with unclear requirements.
- Interactively research and investigate a change with the user:
  - `opsx-explore <topic>`
- Generate the `openspec` change artifacts in one shot:
  - `opsx-new <change-name>`
  - `opsx-continue <change-name>` iteratively and interactively with the user until all artifacts have been accepted.
- Implement and verify the change:
  - `opsx-apply <change-name>`
  - `./build.ps1 -Tasks test`
  - `opsx-verify <change-name>`
- Locally commit the working `openspec` artifacts and associated project changes:
  - `git add ./openspec/ <changed-files-and-or-directories>`; e.g.:
    ```bash
    git add ./openspec/ ./NhcVcpkgTools/ ./build.ps1
    ```
  - `nhc-opsx-commit`
- Locally archive the `openspec` completed change artifacts:
  - `opsx-sync <change-name>`
  - `opsx-archive <change-name>`
  - `git add ./openspec/`
  - `nhc-opsx-commit`

## General Rules (MANDATORY)
- You MUST ask the user when in doubt about how to complete a user request---do not guess or fabricate steps, especially when modifying existing code.
- NEVER make or commit changes automatically without explicit confirmation from the user UNLESS the user has explicitly requested a fully automated change; for example:
  ```
  User:   /opsx-new fix-off-by-one-bug-in-install-nhcvcpkgports
  Agent:  Created openspec/changes/fix-off-by-one-bug-in-install-nhcvcpkgports

  User:   Go ahead and one-shot this change starting with opsx-ff. Only pause if a problem or ambiguity arises that requires my input.
  Agent:  <follows the "One-Shot Implementation" workflow>
  ```

## Error Handling Guidance
- ALWAYS present the user with 1-4 fix options if the build fails, making sure to provide an accurate and concise summary of the error (see [Common Issues and Solutions](#common-issues-and-solutions) for frequent problems).
- ALWAYS present the user with 1-4 fix options if any tests fail, making sure to provide an accurate and concise summary of all errors.
- ALWAYS ask the user what to do if `opsx-verify` fails, making sure to provide an accurate and concise summary of the error. You MAY present 1-4 fix options, but ONLY if the problem is straightforward to solve based on your knowledge of the `openspec` tool.

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

## References
### Rules (MANDATORY)
- Prefer to ask the user for clarification or updated instructions rather than pulling a reference into context.
- ONLY pull these references into context with user confirmation, or if the user requests an autonomous change and a reference is required to complete the change.
### Links
- [fission-ai/openspec/README.md](https://raw.githubusercontent.com/Fission-AI/OpenSpec/refs/heads/main/README.md)
- [fission-ai/openspec/commands.md](https://raw.githubusercontent.com/Fission-AI/OpenSpec/refs/heads/main/docs/commands.md)
- [fission-ai/openspec/workflows.md](https://github.com/Fission-AI/OpenSpec/blob/main/docs/workflows.md)