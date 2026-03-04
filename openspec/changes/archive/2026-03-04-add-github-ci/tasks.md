## 1. Workflow scaffolding

- [x] 1.1 Add a GitHub Actions workflow under `.github/workflows/` that triggers on `pull_request` and `push`
- [x] 1.2 Configure the workflow job to run on `windows-latest`

## 2. CI lint step (diagnostics)

- [x] 2.1 Ensure PSScriptAnalyzer is available in the workflow (install/pin a version)
- [x] 2.2 Run `pwsh ./tools/lint.ps1 -Mode github` and fail the job if it reports any warnings or errors

## 3. CI test step (Pester)

- [x] 3.1 Ensure Pester v5+ is available in the workflow (install/pin a version)
- [x] 3.2 Run `Invoke-Pester -Path tests` and configure it to emit an NUnit XML results file to a known path
- [x] 3.3 Upload the NUnit XML results file as a workflow artifact (ensure upload runs even if tests fail)

## 4. Validation

- [x] 4.1 Validate on a PR that lint findings appear as annotations and that test failures fail the check
- [x] 4.2 Validate that the test results artifact is present for both passing and failing test runs
