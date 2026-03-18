Related: #12
Related: #13

## Context

NhcVcpkgTools wraps vcpkg commands with PowerShell functions that provide consistent parameter handling, path normalization, and integration with PowerShell patterns like `ShouldProcess`. The module currently has:

- `Install-NhcVcpkgPorts` - wraps `vcpkg install`, creates output directories via `-OutputDir`/`-Tag`
- `Export-NhcVcpkgPorts` - wraps `vcpkg export`, reads from `-InstallDir`, writes to `-OutputDir`/`-Tag`

The `vcpkg remove` command operates only on an existing install directory (no output directories). This makes `Remove-NhcVcpkgPorts` simpler than the other functions - it follows the `-InstallDir` pattern from `Export-NhcVcpkgPorts`.

## Goals / Non-Goals

**Goals:**
- Provide a PowerShell wrapper for `vcpkg remove` with consistent parameter handling
- Support both explicit port removal (`-Ports`) and stale package cleanup (`-Outdated`)
- Enable dependent package removal via `-Recurse`
- Integrate with PowerShell's `ShouldProcess` for `-WhatIf`/`-Confirm` support
- Reuse existing `Get-CommonArguments` helper for vcpkg executable and root directory detection

**Non-Goals:**
- Manifest mode support (vcpkg remove doesn't support it)
- Creating or managing output directories (Remove operates on existing install location)
- Custom environment variable handling (`-Env`/`-KeepEnvVars` - not needed for remove)

## Decisions

### 1. Parameter Sets: `-Ports` vs `-Outdated`

**Decision**: Use two mutually exclusive parameter sets matching vcpkg's usage patterns.

```powershell
# ParameterSet "Ports" - remove specific packages
Remove-NhcVcpkgPorts -Ports zlib, fmt

# ParameterSet "Outdated" - remove stale packages  
Remove-NhcVcpkgPorts -Outdated
```

**Rationale**: This mirrors vcpkg's CLI where you either specify packages or use `--outdated`. The parameter sets enforce mutual exclusivity at the PowerShell level.

**Implementation**: Both `-Ports` and `-Outdated` are passed to `Get-CommonArguments` via the `$Parameters` hashtable. `Get-CommonArguments` already handles `-Ports` (adds port names + `--classic`), and will be extended to handle `-Outdated` (adds `--outdated` flag). This keeps argument generation centralized in `Get-CommonArguments`.

**Alternatives considered**:
- Single parameter set with validation logic - rejected because PowerShell parameter sets provide clearer UX and better tab-completion
- Handle `-Ports` and `-Outdated` directly in Remove function - rejected because `Get-CommonArguments` already handles `-Ports` and centralizing argument generation improves maintainability

### 2. Reuse `Get-CommonArguments` with Minimal Directories

**Decision**: Call `Get-CommonArguments` with `$Directories = @('InstallDir')` to leverage existing vcpkg detection and path handling while only generating the `--x-install-root` argument.

### 2A. `Get-CommonArguments` Returns String Paths

**Decision**: Modify `Get-CommonArguments` to ensure all path values in the `$result` hashtable are returned as strings by enclosing source variables in double quotes (e.g., `Path = "$PackageDir"`).

**Rationale**: Ensures consistent string typing for all path values in the returned hashtable, preventing potential type coercion issues when callers access these values. The double-quote syntax forces PowerShell to convert the variable to a string at assignment time.

**Investigation note**: Verification during openspec-refine confirmed that `Get-CommonArguments` already implements this pattern consistently for all path returns (Command, RootDir, ParentDir.Path, and all directory Path values). No additional changes needed for Install-NhcVcpkgPorts or Export-NhcVcpkgPorts.

**Rationale**: `Get-CommonArguments` already handles:
- Finding vcpkg executable from `-Command`, `-RootDir`, or `$env:VCPKG_ROOT`
- Validating vcpkg root directory
- Triplet detection and normalization
- Overlay ports/triplets handling
- Path normalization (removing trailing slashes that vcpkg dislikes)
- `-Ports` parameter (adds port names + `--classic` flag)

`Get-CommonArguments` will be extended to handle:
- `-Outdated` parameter (adds `--outdated` flag)
- `-Recurse` parameter (adds `--recurse` flag)

**Alternatives considered**:
- Duplicate the vcpkg detection logic - rejected to avoid code duplication
- Pass all directories and ignore extras - rejected because it would generate unused arguments
- Handle `-Outdated` in Remove function separately - rejected because `-Ports` is already handled in `Get-CommonArguments`, so `-Outdated` should be handled there too for consistency

### 3. WhatIf Implementation via `--dry-run`

**Decision**: Translate PowerShell's `-WhatIf` to vcpkg's `--dry-run` flag by:
1. Calling `$PSCmdlet.ShouldProcess()` before executing vcpkg
2. When `ShouldProcess()` returns `$false`, adding `--dry-run` to arguments and executing vcpkg
3. Always executing vcpkg (even with `-WhatIf`) to show dry-run output
4. Returning the full hashtable with results from the dry-run execution

**Rationale**: Maintains consistency with `Install-NhcVcpkgPorts` and `Export-NhcVcpkgPorts`, which both execute vcpkg with `--dry-run` when `-WhatIf` is specified (lines 210-216 in Install, 281-287 in Export). This allows users to see what would be removed without making changes.

**Alternatives considered**:
- Return early without executing vcpkg - rejected because users need to see what would be removed, and vcpkg's `--dry-run` provides this information
- Skip `ShouldProcess()` and only check `$WhatIfPreference` - rejected because it wouldn't support `-Confirm` prompts

### 4. Return Value Structure

**Decision**: Return a hashtable with subset of fields used by other functions:

```powershell
@{
    Command    = <string>   # Full path to vcpkg executable
    Arguments  = <string[]> # CLI arguments passed to vcpkg
    RootDir    = <string>   # vcpkg root directory
    InstallDir = @{         # Install directory info
        Path   = <string>
        Exists = <bool>
    }
    Status     = <bool>     # $true if removal succeeded
}
```

**Rationale**: Consistent with other public functions, but omits fields that don't apply (BaseDir, OutputDir, Tag, DownloadDir, BuildDir, PackageDir). Hashtable chosen over custom PSObject or class because:
- **Consistency**: Install/Export already use hashtables, maintaining module-wide pattern
- **Flexibility**: Easy to add fields in future without breaking changes to type definitions
- **Trade-off accepted**: Less discoverable via tab-completion than custom types, but consistency and flexibility outweigh this limitation

**Alternatives considered**:
- Return identical structure to Install/Export with all fields - rejected because Remove doesn't create directories, so including null/empty OutputDir, DownloadDir, BuildDir, PackageDir would be misleading
- Return only Status boolean - rejected because callers need access to Command, Arguments, and paths for logging/debugging
- Add ExitCode field - rejected to maintain consistency with Install/Export which use boolean Status
- Use custom PSObject or PowerShell class - rejected to maintain consistency with existing functions and avoid introducing new type patterns for a single function

### 5. TDD Approach

**Decision**: Follow red/green/refactor TDD process:
1. Create test file with tests for parameter validation, argument generation, and ShouldProcess behavior
2. Implement minimal function skeleton that fails tests
3. Implement functionality to pass tests
4. Refactor for clarity

**Rationale**: Required by project guidelines (AGENTS.md) and ensures comprehensive test coverage.

**Alternatives considered**:
- Write implementation first, then tests - rejected because it's prohibited by project guidelines and leads to incomplete test coverage
- Use property-based testing - rejected as overkill for this wrapper function; scenario-based testing is sufficient
- Skip unit tests and only write integration tests - rejected because project guidelines mandate unit tests for all new code

### 6. Force Parameter Implementation

**Decision**: Implement `-Force` switch parameter following Microsoft PowerShell ShouldProcess best practices:
1. Add `-Force` switch parameter to function signature
2. When `-Force` is specified without explicit `-Confirm`, set `$ConfirmPreference = 'None'` in local scope
3. Use `$PSBoundParameters.ContainsKey('Confirm')` to detect explicit `-Confirm` usage
4. Preserve `-WhatIf` precedence: if both `-Force` and `-WhatIf` are specified, `-WhatIf` takes priority
5. Do NOT add `-Force` check inside the `if ($PSCmdlet.ShouldProcess())` block - handle it before ShouldProcess

**Rationale**: 
- Microsoft ShouldProcess guidelines strongly recommend `-Force` for functions performing destructive operations
- Consistent with PowerShell user expectations (users instinctively try `-Force` to suppress prompts)
- Pattern preserves both `-Confirm` override and `-WhatIf` precedence semantics
- Matches pattern documented in [Microsoft ShouldProcess deep-dive](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess)

**Alternatives considered**:
- Don't implement Force, require users to use `-Confirm:$false` - rejected because users expect `-Force` for destructive operations
- Add Force check inside ShouldProcess if-block - rejected because this is an anti-pattern that breaks `-WhatIf` precedence
- Set `$ConfirmPreference = 'None'` unconditionally when Force is specified - rejected because it would suppress explicit `-Confirm` prompts

### 7. Ports Parameter Validation

**Decision**: Add `[ValidateNotNullOrEmpty()]` attribute to the `-Ports` parameter.

**Rationale**: 
- Provides defensive validation at PowerShell parameter level before vcpkg invocation
- Early error feedback improves user experience (fail fast with clear message)
- Follows Microsoft "Validating Parameter Input" guidelines for cmdlet development
- Prevents common user errors (passing empty array or null)
- Low implementation cost with meaningful UX improvement

**Alternatives considered**:
- Let vcpkg handle validation - rejected because PowerShell-level validation provides clearer, earlier error messages
- Add manual validation logic in function body - rejected because validation attributes are more declarative and idiomatic
- Use ValidateCount instead - rejected because it doesn't catch null values, only validates array length

## Commonality Analysis

Investigation of existing code to identify reuse opportunities:

### Existing Shared Components

| Component | Decision | Rationale |
|-----------|----------|-----------|
| `Get-CommonArguments` | **Reuse + Extend** | Already handles vcpkg detection, validation, argument generation, and `-Ports` parameter. Will be extended to also handle `-Outdated` (adds `--outdated` flag) and `-Recurse` (adds `--recurse` flag) parameters. Called with `$Directories = @('InstallDir')` to generate only the needed arguments. |
| Private helpers | **Reuse** | `Get-CommonArguments` internally uses `Test-VcpkgRoot`, `Test-Executable`, `Get-Executable` which are already available. |

### Existing Patterns from Install/Export

| Pattern | Decision | Rationale |
|---------|----------|-----------|
| `ShouldProcess` implementation | **Reuse pattern** | Both Install (lines 210-216) and Export (lines 281-287) use identical pattern: call `ShouldProcess()`, add `--dry-run` if false, always execute vcpkg. This pattern will be adopted exactly. |
| Error handling | **Reuse pattern** | Both Install and Export check `$?` after `Start-Process` and set `Status = $true/$false` (Install lines 227-232, Export lines 298-303). No custom error parsing. This pattern will be adopted. |
| Dry-run cleanup | **Not applicable** | Install/Export clean up created directories after `--dry-run` (Install lines 234-263, Export lines 305-334). Remove doesn't create directories, so this cleanup logic is not needed. |
| Quiet mode handling | **Reuse pattern** | Both Install and Export have conditional logic for `-Quiet` parameter to suppress output (Install lines 218-225, Export lines 289-296). This pattern will be adopted. |
| Environment variable passing | **Not needed** | Install uses `-Environment` parameter with `Start-Process` for `-Env`/`-KeepEnvVars` support. Remove doesn't support these parameters per design decision, so this pattern is not needed. |

### Related Existing Specs

No existing specs define removal functionality. The closest are:
- `install-ports-tests` - defines testing patterns for Install
- `install-env-parameter` - defines environment variable handling (not applicable to Remove)

## Risks / Trade-offs

**Risk**: vcpkg remove errors are passed through without translation.
- **Mitigation**: Acceptable per proposal - vcpkg provides clear error messages. Future enhancement could add error parsing if needed.

**Risk**: No validation that InstallDir actually contains installed ports.
- **Mitigation**: vcpkg itself validates this and provides appropriate errors. Adding pre-validation would duplicate vcpkg's logic.

**Trade-off**: Simpler return value than Install/Export (fewer fields).
- **Acceptance**: Appropriate because Remove doesn't create directories. Consistency in present fields matters more than having identical field counts.
