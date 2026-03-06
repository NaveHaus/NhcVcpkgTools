## MODIFIED Requirements

### Requirement: Source folders use Public and Private casing
The repository SHALL store module scripts under `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`.

Unit tests under `tests/Public` and `tests/Private` SHALL validate behavior via an imported `NhcVcpkgTools` module (built output) so commands are resolved from module scope rather than by dot-sourcing source scripts at test time.

#### Scenario: Module import uses Sampler-compatible loading
- **WHEN** the module is imported from the repository root after `./build.ps1 -Tasks noop`
- **THEN** commands are available from the imported `NhcVcpkgTools` module without runtime dot-sourcing from `NhcVcpkgTools/Public` and `NhcVcpkgTools/Private`

#### Scenario: Unit test suites dot-source only their bootstrap
- **WHEN** a test file in `tests/Public` or `tests/Private` requires shared setup
- **THEN** it MAY dot-source the suite bootstrap helper, and MUST NOT dot-source `NhcVcpkgTools/Public/*.ps1` or `NhcVcpkgTools/Private/*.ps1`

#### Scenario: QA/Tools test discovery remains unchanged
- **WHEN** `Invoke-Pester -Path tests` is used (discovering `tests/QA` and `tests/Tools`)
- **THEN** unit-test bootstrap behavior is confined to the `tests/Public` and `tests/Private` suites and does not require refactoring QA/Tools tests as part of this change
