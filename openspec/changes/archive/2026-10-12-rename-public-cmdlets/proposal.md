## Problem and Why

Commit `0af2377` (2026-07-01) renamed the module's public commands to singular nouns to satisfy PSScriptAnalyzer's `PSUseSingularNouns` rule: `Install-NhcVcpkgPorts`, `Export-NhcVcpkgPorts`, and `Remove-NhcVcpkgPorts` became `Install-NhcVcpkgPort`, `Export-NhcVcpkgPort`, and `Remove-NhcVcpkgPort`, with the plural names kept as exported aliases. The private helper `Get-CommonArguments` became `Get-CommonArgument` in the same commit. No plan, design, or spec recorded this, and it changed the module's public surface.

Two consequences:

- The backward-compatibility promise (scripts calling the plural names keep working) exists only in tests, not in any spec.
- `remove-ports`, `install-env-parameter`, and `install-ports-tests` still name the plural commands and the old helper name, so the main specs disagree with the module.

## Goals

- The specs record the singular-noun **canonical command names** as the primary public surface of the **port cmdlets**.
- The specs record the plural-noun **legacy aliases** as a supported, exported, backward-compatible way to invoke each **port cmdlet**.
- Existing main specs refer to **port cmdlets** and private helpers by their current names.

## Scope and Capabilities

### New Capabilities

- `public-command-names`: How the module names and exports its **port cmdlets**: **canonical command names**, the **legacy aliases** that resolve to them, and the equivalence of invoking either name.

### Modified Capabilities

- `remove-ports`: Requirements and scenarios refer to `Remove-NhcVcpkgPort` and `Get-CommonArgument` instead of `Remove-NhcVcpkgPorts` and `Get-CommonArguments`; requirement titles that embed those names are renamed.
- `install-env-parameter`: Requirements and scenarios refer to `Install-NhcVcpkgPort` instead of `Install-NhcVcpkgPorts`.
- `install-ports-tests`: Requirements and scenarios refer to `Install-NhcVcpkgPort` and `Get-CommonArgument` instead of `Install-NhcVcpkgPorts` and `Get-CommonArguments`.

## Non-Goals

- No deprecation warning, removal timeline, or other change to the behavior of **legacy aliases**.
- No change to any **port cmdlet** parameter or behavior.
- No specs for `Export-NhcVcpkgPort` or `Install-NhcVcpkgPort` functionality beyond naming (deferred to a separate per-cmdlet effort).
- No restatement of vcpkg exit status or `-Quiet` behavior; `surface-vcpkg-exit-status` owns that.
- No rewording of existing requirements beyond the rename.

## Impact

- `openspec/specs/public-command-names/spec.md` is created.
- `openspec/specs/remove-ports/spec.md`, `openspec/specs/install-env-parameter/spec.md`, and `openspec/specs/install-ports-tests/spec.md` are updated to current names. Purpose sections of existing specs are outside the delta-spec format, so the plural name in the `install-env-parameter` Purpose is updated by a direct edit when this change is synced to the main specs. The `install-ports-tests` Purpose, a placeholder that also names the plural command, is rewritten with the **canonical command name** by `repair-spec-baseline`, which is synced first.
- Not breaking for callers, because the **legacy aliases** remain exported. The one observable difference is that command discovery now reports the singular names as functions and the plural names as aliases.
- Archive order: archived after `repair-spec-baseline` and before `surface-vcpkg-exit-status` and `test-quality-coverage`, which use the **canonical command names**.
- No code, API, dependency, or workflow changes.
