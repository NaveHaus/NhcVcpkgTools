# vcpkg Exit-Code Status Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-optimized:subagent-driven-development (recommended) or superpowers-optimized:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make `Install`/`Export`/`Remove-NhcVcpkgPorts` return `Status: $false` when vcpkg exits with a non-zero code (GitHub issue #17).

**Architecture:** Extract a single private helper `Invoke-Vcpkg` that runs vcpkg via `Start-Process -PassThru -Wait` and reports success as `$proc.ExitCode -eq 0`. The three public cmdlets replace their duplicated `Start-Process` + `$status = $?` blocks with one call to the helper, assigning the result to `$config.Status`. The previous code read `$?` (which reflects only whether `Start-Process` *launched*, never the child exit code), so failures were silently reported as success.

**Tech Stack:** PowerShell module (Sampler build), Pester 5 tests, `./build.ps1` for module assembly.

**Assumptions:**
- Assumes vcpkg is invoked through `Start-Process -Wait` so `ExitCode` is populated by the time it is read — will NOT work if a future change drops `-Wait` (ExitCode would be unavailable on a still-running process).
- Assumes the helper runs in module scope and calls the module-scoped mocked `Start-Process` in tests (Public tests set `Mock:ModuleName = NhcVcpkgTools` via the bootstrap) — will NOT work if a test mocks `Start-Process` without the module default.
- Assumes `Status`-only surfacing this round (no `Write-Error`/throw on non-zero exit). A follow-up issue tracks the louder `Status + Write-Error` behavior.

---

## File Structure

- `NhcVcpkgTools/Private/Invoke-Vcpkg.ps1` *(new)* — single responsibility: run vcpkg and return a boolean success based on the real exit code. Owns the `-Quiet` and launch-failure (`try/catch`) handling that was previously triplicated.
- `NhcVcpkgTools/Public/Install-NhcVcpkgPorts.ps1` *(modify)* — replace run block (lines ~218-231) with helper call passing `-Environment`.
- `NhcVcpkgTools/Public/Export-NhcVcpkgPorts.ps1` *(modify)* — replace run block (lines ~289-302) with helper call (no environment).
- `NhcVcpkgTools/Public/Remove-NhcVcpkgPorts.ps1` *(modify)* — replace run block (lines ~132-145) with helper call (no environment).
- `tests/Private/Invoke-Vcpkg.Tests.ps1` *(new)* — unit tests for the helper (the primary red→green test).
- `tests/Public/Install-NhcVcpkgPorts.Tests.ps1` *(modify)* — mock `Start-Process` to return an object with `ExitCode`; add a non-zero-exit → `Status:$false` case.
- `tests/Public/Remove-NhcVcpkgPorts.Tests.ps1` *(modify)* — same mock update + `Status:$false` case.
- `tests/Public/Export-NhcVcpkgPorts.Tests.ps1` *(new)* — minimal exit-code regression test (state.md finding 1); a single raw-export invocation asserting `Status` false/true on `ExitCode` 1/0.

**Note on Export:** `tests/Public/Export-NhcVcpkgPorts.Tests.ps1` did not exist before this fix. Per state.md finding 1 a minimal exit-code regression test is added (Task 5); the full parameter-set matrix remains out of scope.

---

### Task 1: Create working branch

**Files:** none

**Security flag:** `none`

- [x] **Step 1: Create and switch to a feature branch**

Run:
```bash
git switch -c fix/17-vcpkg-exit-code-status
```
Expected: switched to a new branch `fix/17-vcpkg-exit-code-status`.

---

### Task 2: Add `Invoke-Vcpkg` helper (TDD red → green)

**Files:**
- Create: `tests/Private/Invoke-Vcpkg.Tests.ps1`
- Create: `NhcVcpkgTools/Private/Invoke-Vcpkg.ps1`

**Security flag:** `none`

**Does NOT cover:** Only the exit-code → boolean mapping and launch-failure path. Does NOT suppress the child process's console output (with `-NoNewWindow` vcpkg writes directly to the console; `-Quiet` only governs `Start-Process`'s own error stream, matching prior behavior). Does NOT emit a `Write-Error` on failure (tracked by follow-up issue).

- [x] **Step 1: Write failing tests**

Create `tests/Private/Invoke-Vcpkg.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Invoke-Vcpkg' {
    Context 'Exit code handling' {
        It 'returns $true when vcpkg exits with code 0' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 0 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install', 'zlib') | Should -BeTrue
            }
        }

        It 'returns $false when vcpkg exits with a non-zero code' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 1 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install', 'zlib') | Should -BeFalse
            }
        }

        It 'returns $false when Start-Process throws (launch failure)' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { throw 'cannot launch' }
                Invoke-Vcpkg -Command 'missing' -Arguments @('install') | Should -BeFalse
            }
        }

        It 'passes -PassThru and -Wait to Start-Process' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 0 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install') | Out-Null
                Should -Invoke Start-Process -Times 1 -ParameterFilter {
                    $PassThru -and $Wait
                }
            }
        }

        It 'forwards Environment to Start-Process when provided' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 0 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install') -Environment @{ FOO = 'bar' } | Out-Null
                Should -Invoke Start-Process -Times 1 -ParameterFilter {
                    $null -ne $Environment -and $Environment['FOO'] -eq 'bar'
                }
            }
        }
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path tests/Private/Invoke-Vcpkg.Tests.ps1`
Expected: FAIL — `Invoke-Vcpkg` command not found (helper does not exist yet).

- [x] **Step 3: Implement the helper**

Create `NhcVcpkgTools/Private/Invoke-Vcpkg.ps1`:

```powershell
Set-StrictMode -Version 3.0

function Invoke-Vcpkg {
    <#
    .SYNOPSIS
    Runs the vcpkg executable and reports whether it exited successfully.

    .DESCRIPTION
    Wraps Start-Process so the real child exit code is captured via -PassThru.
    Returns $true only when vcpkg exits with code 0; returns $false on a
    non-zero exit code or if the process fails to launch.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [hashtable]$Environment,

        [switch]$Quiet
    )

    $private:splat = @{
        FilePath     = $Command
        ArgumentList = $Arguments
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        WhatIf       = $false
        Confirm      = $false
        ErrorAction  = 'Stop'
    }
    if ($null -ne $Environment) {
        $splat['Environment'] = $Environment
    }

    try {
        if ($Quiet) {
            $private:proc = Start-Process @splat 2>$null
        }
        else {
            $private:proc = Start-Process @splat
        }
        return ($null -ne $proc) -and (0 -eq $proc.ExitCode)
    }
    catch {
        # vcpkg failed to launch - report failure without rethrowing.
        return $false
    }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `./build.ps1 -Tasks build` then `Invoke-Pester -Path tests/Private/Invoke-Vcpkg.Tests.ps1`
Expected: PASS (all 5 tests). The build step regenerates the module so the new Private function is included.

- [x] **Step 5: Commit**

```bash
git add NhcVcpkgTools/Private/Invoke-Vcpkg.ps1 tests/Private/Invoke-Vcpkg.Tests.ps1
git commit -m "feat: add Invoke-Vcpkg helper that reports real vcpkg exit status"
```

---

### Task 3: Wire `Install-NhcVcpkgPorts` to the helper (TDD red → green)

**Files:**
- Modify: `tests/Public/Install-NhcVcpkgPorts.Tests.ps1`
- Modify: `NhcVcpkgTools/Public/Install-NhcVcpkgPorts.ps1`

**Security flag:** `none`

**Does NOT cover:** the `--dry-run`/`WhatIf` path (unchanged) and the cleanup logic below the run block (unchanged).

- [x] **Step 1: Write failing test (do NOT touch the shared mock yet)**

> **Red-step sequencing (state.md finding 2):** Leave the shared `BeforeEach` `Start-Process` mock returning *nothing* during the red step. Do NOT change it to return an object here — a `-PassThru` object returned before the call site consumes it leaks into the cmdlet output stream and pollutes `$result`. The shared mock is switched to return `[pscustomobject]@{ ExitCode = 0 }` in Step 3 (green), in the *same* step as the call-site swap. The failure case uses a **test-local** `ExitCode = 1` mock.

Add a new `Context` at the end of the `Describe` block:

```powershell
    Context 'vcpkg exit status' {
        It 'returns Status false when vcpkg exits non-zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 1 } }

            $result = Install-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
        }

        It 'returns Status true when vcpkg exits zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 0 } }

            $result = Install-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeTrue
        }
    }
```

Both cases use test-local mocks so they are independent of whether the shared mock returns an object.

- [x] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path tests/Public/Install-NhcVcpkgPorts.Tests.ps1`
Expected: FAIL — `returns Status false when vcpkg exits non-zero` fails because the current call site uses `$?` (always `$true` after a mocked `Start-Process`), so `Status` is `$true`.

- [x] **Step 3: Replace the run block with the helper call AND update the shared mock (green)**

In `NhcVcpkgTools/Public/Install-NhcVcpkgPorts.ps1`, replace the `try { ... } catch { ... }` block plus the following `$config.Status = $status` (lines ~218-233) with:

```powershell
        $config.Status = Invoke-Vcpkg -Command $exe -Arguments $params -Environment $environment -Quiet:$Quiet
```

(Leave the `--dry-run` cleanup block that follows unchanged.)

Now the call site consumes the `-PassThru` object, so update the shared `BeforeEach` mock to return a success object as its last line (so the *existing* tests that assert `Status: $true` still pass):

```powershell
        Mock Start-Process {
            param(
                [string]$FilePath,
                [object[]]$ArgumentList,
                [hashtable]$Environment,
                [switch]$NoNewWindow,
                [switch]$Wait,
                [switch]$WhatIf,
                [switch]$Confirm
            )

            $script:capturedCommand = $FilePath
            $script:capturedArguments = $ArgumentList + @($NoNewWindow,$Wait,$WhatIf,$Confirm)
            $script:capturedEnvironment = $Environment
            return [pscustomobject]@{ ExitCode = 0 }
        }
```

- [x] **Step 4: Run test to verify it passes**

Run: `./build.ps1 -Tasks build` then `Invoke-Pester -Path tests/Public/Install-NhcVcpkgPorts.Tests.ps1`
Expected: PASS (all existing tests plus the two new ones).

- [x] **Step 5: Commit**

```bash
git add NhcVcpkgTools/Public/Install-NhcVcpkgPorts.ps1 tests/Public/Install-NhcVcpkgPorts.Tests.ps1
git commit -m "fix: surface vcpkg exit status in Install-NhcVcpkgPorts"
```

---

### Task 4: Wire `Remove-NhcVcpkgPorts` to the helper (TDD red → green)

**Files:**
- Modify: `tests/Public/Remove-NhcVcpkgPorts.Tests.ps1`
- Modify: `NhcVcpkgTools/Public/Remove-NhcVcpkgPorts.ps1`

**Security flag:** `none`

**Does NOT cover:** the `WhatIf`/`--dry-run` path (unchanged).

- [x] **Step 1: Write failing test (do NOT touch the shared mock yet)**

> **Red-step sequencing (state.md finding 2):** Leave the shared `BeforeEach` `Start-Process` mock returning *nothing* during the red step (same rationale as Task 3). Switch it to `[pscustomobject]@{ ExitCode = 0 }` in Step 3 (green), alongside the call-site swap. Failure case uses a test-local `ExitCode = 1` mock.
>
> **Note the pre-existing tests** in `Context 'Return value structure'`: `returns Status as true on successful execution` and `returns Status as false when vcpkg fails` (the latter mocks `Start-Process` to `throw`). Both continue to pass after green — the throw case exercises the helper's `catch`. Keep them; the new `Context` below adds the explicit exit-code cases.

Add a new `Context` at the end of the `Describe` block:

```powershell
    Context 'vcpkg exit status' {
        It 'returns Status false when vcpkg exits non-zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 1 } }

            $result = Remove-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
        }

        It 'returns Status true when vcpkg exits zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 0 } }

            $result = Remove-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeTrue
        }
    }
```

- [x] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path tests/Public/Remove-NhcVcpkgPorts.Tests.ps1`
Expected: FAIL — `returns Status false when vcpkg exits non-zero` fails (current call site uses `$?`).

- [x] **Step 3: Replace the run block with the helper call AND update the shared mock (green)**

In `NhcVcpkgTools/Public/Remove-NhcVcpkgPorts.ps1`, replace the `try { ... } catch { ... }` block plus the following `$config.Status = $status` (lines ~132-147) with:

```powershell
        $config.Status = Invoke-Vcpkg -Command $exe -Arguments $params -Quiet:$Quiet
```

Then update the shared `BeforeEach` mock to return a success object as its last line (so `returns Status as true on successful execution` still passes):

```powershell
        Mock Start-Process {
            param(
                [string]$FilePath,
                [object[]]$ArgumentList,
                [switch]$NoNewWindow,
                [switch]$Wait,
                [switch]$WhatIf,
                [switch]$Confirm
            )

            $script:capturedCommand = $FilePath
            $script:capturedArguments = $ArgumentList + @($NoNewWindow, $Wait, $WhatIf, $Confirm)
            return [pscustomobject]@{ ExitCode = 0 }
        }
```

- [x] **Step 4: Run test to verify it passes**

Run: `./build.ps1 -Tasks build` then `Invoke-Pester -Path tests/Public/Remove-NhcVcpkgPorts.Tests.ps1`
Expected: PASS (all existing tests plus the two new ones).

- [x] **Step 5: Commit**

```bash
git add NhcVcpkgTools/Public/Remove-NhcVcpkgPorts.ps1 tests/Public/Remove-NhcVcpkgPorts.Tests.ps1
git commit -m "fix: surface vcpkg exit status in Remove-NhcVcpkgPorts"
```

---

### Task 5: Wire `Export-NhcVcpkgPorts` to the helper (TDD red → green)

**Files:**
- Create: `tests/Public/Export-NhcVcpkgPorts.Tests.ps1`
- Modify: `NhcVcpkgTools/Public/Export-NhcVcpkgPorts.ps1`

**Security flag:** `none`

> **state.md finding 1:** `tests/Public/Export-NhcVcpkgPorts.Tests.ps1` does not exist today, yet Export is one of the three affected cmdlets. Add a minimal regression test rather than relying solely on the `Invoke-Vcpkg` unit test. Same red-step sequencing as Tasks 3 & 4: the failure/success cases use test-local exit-code mocks, so the shared `BeforeEach` mock can safely return `[pscustomobject]@{ ExitCode = 0 }` from the start (there are no pre-existing Export tests to protect, and both new tests override the mock locally).

**Does NOT cover:** the full Export parameter-set matrix (out of scope). Only the exit-code → `Status` mapping via a single minimal raw-export invocation.

- [x] **Step 1: Write failing test**

Create `tests/Public/Export-NhcVcpkgPorts.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Export-NhcVcpkgPorts' {
    BeforeAll {
        function New-TestVcpkgRoot {
            $rootDir = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString())
            New-Item -Path $rootDir -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $rootDir '.vcpkg-root') -ItemType File | Out-Null
            $command = Join-Path $rootDir 'vcpkg.exe'
            New-Item -Path $command -ItemType File | Out-Null

            return @{ RootDir = $rootDir; Command = $command }
        }
    }

    BeforeEach {
        $script:triplet = 'x64-windows'
        $script:rootInfo = New-TestVcpkgRoot
        $script:outputDir = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString())
        New-Item -Path $script:outputDir -ItemType Directory | Out-Null

        Mock Test-Executable -ModuleName $script:moduleName { return $true }
        Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 0 } }
    }

    Context 'vcpkg exit status' {
        It 'returns Status false when vcpkg exits non-zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 1 } }

            $result = Export-NhcVcpkgPorts -Ports 'zlib' -Raw -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -OutputDir $script:outputDir -Tag 'run'

            $result.Status | Should -BeFalse
        }

        It 'returns Status true when vcpkg exits zero' {
            $result = Export-NhcVcpkgPorts -Ports 'zlib' -Raw -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -OutputDir $script:outputDir -Tag 'run'

            $result.Status | Should -BeTrue
        }
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path tests/Public/Export-NhcVcpkgPorts.Tests.ps1`
Expected: FAIL — `returns Status false when vcpkg exits non-zero` fails because the current call site uses `$?`, so `Status` is `$true`.

> If instead *both* tests error out (not a clean assertion failure), the minimal invocation is wrong for a parameter-set/validation reason — fix the invocation before proceeding; do not skip the test.

- [x] **Step 3: Replace the run block with the helper call**

In `NhcVcpkgTools/Public/Export-NhcVcpkgPorts.ps1`, replace the `try { ... } catch { ... }` block plus the following `$config.Status = $status` (lines ~289-304) with:

```powershell
        $config.Status = Invoke-Vcpkg -Command $exe -Arguments $params -Quiet:$Quiet
```

(Leave the `--dry-run` cleanup block that follows unchanged.)

- [x] **Step 4: Build and run the full suite to confirm no regression**

Run: `./build.ps1 -Tasks build` then `Invoke-Pester`
Expected: PASS — entire suite green, including the Install/Remove/Export/Invoke-Vcpkg tests.

- [x] **Step 5: Commit**

```bash
git add NhcVcpkgTools/Public/Export-NhcVcpkgPorts.ps1 tests/Public/Export-NhcVcpkgPorts.Tests.ps1
git commit -m "fix: surface vcpkg exit status in Export-NhcVcpkgPorts"
```

---

### Task 6: Full verification

**Files:** none

**Security flag:** `none`

- [x] **Step 1: Clean build + full test run**

Run: `./build.ps1 -Tasks build` then `Invoke-Pester`
Expected: PASS — full suite green, no failures.

- [x] **Step 2: Confirm no leftover `$status = $?` pattern remains**

Run (Grep tool): pattern `\$status = \$\?` across `NhcVcpkgTools/Public/`
Expected: no matches.

---

### Task 7: Push and PR

**Files:** none

**Security flag:** `none`

> Note: the follow-up issue for `Status + Write-Error` surfacing was already filed as **#18** before implementation began, and is intentionally decoupled from this fix's flow.

- [x] **Step 2: Push the branch**

```bash
git push -u origin fix/17-vcpkg-exit-code-status
```

- [x] **Step 3: Open the PR**

```bash
gh pr create --title "fix: surface vcpkg exit codes in port cmdlets" --body "$(cat <<'EOF'
## Summary
- Add private `Invoke-Vcpkg` helper that runs vcpkg via `Start-Process -PassThru -Wait` and reports `Status` from the real child exit code instead of `$?`.
- Wire `Install`/`Export`/`Remove-NhcVcpkgPorts` to the helper so they return `Status: $false` when vcpkg fails.

Closes #17. Follow-up for `Write-Error` surfacing: #18

## Test plan
- [x] `Invoke-Pester -Path tests/Private/Invoke-Vcpkg.Tests.ps1` — exit code 0/1/launch-failure mapping
- [x] `Invoke-Pester -Path tests/Public/Install-NhcVcpkgPorts.Tests.ps1` — Status false on non-zero exit
- [x] `Invoke-Pester -Path tests/Public/Remove-NhcVcpkgPorts.Tests.ps1` — Status false on non-zero exit
- [x] `./build.ps1 -Tasks build` then `Invoke-Pester` — full suite green
EOF
)"
```
Expected: prints the PR URL.

---

## Self-Review

- **state.md findings applied:** (1) Export regression test added as a red→green cycle in Task 5 ✓; (2) red-step mock sequencing fixed in Tasks 3 & 4 — shared mock stays returning nothing during red, swapped to `ExitCode = 0` only in the green step, failure cases use test-local `ExitCode = 1` mocks ✓; (3) `ErrorAction = 'Stop'` added to the helper's `Start-Process` splat so the `catch` no longer depends on caller `$ErrorActionPreference`, with the existing launch-failure unit test covering it ✓.
- **Spec coverage:** Helper (Task 2) ✓; all three call sites wired (Tasks 3,4,5) ✓; TDD red/green per behavior change incl. Export ✓; mock updates + Status:False cases (Tasks 3,4,5) ✓; follow-up issue filed as #18 (before implementation, decoupled) ✓; branch + PR with `Closes #17` (Tasks 1,7) ✓; build+Pester verification (Task 6) ✓.
- **Placeholder scan:** none — all code blocks are concrete. `#<follow-up>` is an intentional runtime value with explicit instructions to substitute.
- **Type consistency:** helper name `Invoke-Vcpkg`, params `-Command`/`-Arguments`/`-Environment`/`-Quiet`, and `$config.Status` assignment are consistent across all tasks; mock return shape `[pscustomobject]@{ ExitCode = N }` is uniform.
- **Scope-reduction scan:** "Status-only this round" and the absent Export test are explicitly user-sanctioned decisions, not quiet downgrades; follow-up issue #18 is filed for the deferred surfacing.
