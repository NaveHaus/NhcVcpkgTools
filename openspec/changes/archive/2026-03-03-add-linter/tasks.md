## 1. Lint policy scaffolding

- [x] 1.1 Add `PSScriptAnalyzerSettings.psd1` at repo root with default rules enabled
- [x] 1.2 Add `tools/lint.ps1` entrypoint with parameters for `-Mode` (local/github), `-SettingsPath`, and default paths (`NhcVcpkgTools`, `tests`, `tools`)

## 2. Lint runner core behavior

- [x] 2.1 Implement deterministic file scoping to analyze only `NhcVcpkgTools/`, `tests/`, and `tools` PowerShell sources
- [x] 2.2 Implement ScriptAnalyzer invocation using the settings file and scoped paths
- [x] 2.3 Implement `github` mode formatting: one annotation per diagnostic with compact `[{RuleName}] {Message}` messages
- [x] 2.4 Implement repository-relative path normalization for GitHub annotations when diagnostics point inside the checkout
- [x] 2.5 Implement `local` mode formatting: rich, human-readable output including severity, rule name, message, and file location
- [x] 2.6 Implement exit-code policy: succeed only when there are no Warning/Error diagnostics

## 3. Pester tests for lint runner (TDD)

- [x] 3.1 Follow red-green TDD: after adding EACH new test below, run it and confirm it fails (RED) BEFORE implementing the actual test logic
- [x] 3.2 Add Pester tests for `github` mode annotation output (mock ScriptAnalyzer results)
- [x] 3.3 Add Pester tests for exit codes when findings exist (warnings and errors) vs when there are no findings
- [x] 3.4 Add Pester tests that verify analysis scope excludes non-target directories
- [x] 3.5 Add Pester tests for repo-relative path normalization behavior
- [x] 3.6 Add Pester tests that verify the default ScriptAnalyzer settings path is used
- [x] 3.7 Add Pester tests for `local` mode annotation output (mock ScriptAnalyzer results)

## 4. Documentation

- [x] 4.1 Update `README.md` with local lint usage (`pwsh ./tools/lint.ps1`) and required module install guidance
- [x] 4.2 Add brief notes on CI usage (`-Mode github`) to support the follow-on GitHub Actions change
