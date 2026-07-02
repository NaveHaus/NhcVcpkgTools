# Test-Quality Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close issues #21 and #12 by adding missing unit coverage, making Get-NormalizedNamedDir QA-discoverable, and expanding Remove-NhcVcpkgPort error-scenario tests.

**Architecture:** Keep production behavior unchanged except for splitting Get-NormalizedNamedDir into its own private function file so QA can map function names to files. Add focused Pester coverage around each helper and public Remove-NhcVcpkgPort failure flow using existing module bootstrap and Start-Process mocks.

**Tech Stack:** PowerShell 7.4+, Pester 5.x, PSScriptAnalyzer, Sampler build tasks, graphify.

---

## File structure

- Create `NhcVcpkgTools/Private/Get-NormalizedNamedDir.ps1`: owns only the Get-NormalizedNamedDir helper currently nested in Get-CommonArgument.ps1.
- Modify `NhcVcpkgTools/Private/Get-CommonArgument.ps1`: remove the nested Get-NormalizedNamedDir definition; keep calls unchanged.
- Modify `NhcVcpkgTools/NhcVcpkgTools.psm1`: add `Get-NormalizedNamedDir` to `$private:PrivateFunctions` after `Get-Executable` or near `Get-CommonArgument`.
- Create `tests/Private/Get-NormalizedNamedDir.Tests.ps1`: tests helper path normalization behavior.
- Create `tests/Private/Get-BinaryType.Tests.ps1`: tests `BinaryType.NONE` and `BinaryType.BIT64` only.
- Create `tests/Private/Test-EmptyDirectory.Tests.ps1`: tests empty, non-empty, hidden-file, and nonexistent-path behavior.
- Modify `tests/Public/Remove-NhcVcpkgPort.Tests.ps1`: add missing issue #12 error-scenario tests using existing mocks.
- Keep `docs/specs/2026-07-01-test-quality-coverage-design.md` unchanged.
- Do not modify files under `openspec/`.

---

### Task 1: Split and test Get-NormalizedNamedDir

**Files:**
- Create: `NhcVcpkgTools/Private/Get-NormalizedNamedDir.ps1`
- Modify: `NhcVcpkgTools/Private/Get-CommonArgument.ps1`
- Modify: `NhcVcpkgTools/NhcVcpkgTools.psm1`
- Test: `tests/Private/Get-NormalizedNamedDir.Tests.ps1`

- [ ] **Step 1: Write the failing test file**

Create `tests/Private/Get-NormalizedNamedDir.Tests.ps1` with:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-NormalizedNamedDir' {
    It 'uses DefaultPath relative to ParentPath when parameter is absent' {
        InModuleScope -ScriptBlock {
            $parent = Join-Path $TestDrive 'vcpkg-root'
            New-Item -Path $parent -ItemType Directory | Out-Null

            $result = Get-NormalizedNamedDir -Parameters @{} -Name 'InstallDir' -ParentPath $parent -DefaultPath 'installed'
            $expected = ConvertTo-NormalizedPath (Join-Path $parent 'installed')

            $result | Should -Be $expected
        }
    }

    It 'uses a relative parameter value under ParentPath' {
        InModuleScope -ScriptBlock {
            $parent = Join-Path $TestDrive 'parent'
            New-Item -Path $parent -ItemType Directory | Out-Null

            $result = Get-NormalizedNamedDir -Parameters @{ InstallDir = 'custom-installed' } -Name 'InstallDir' -ParentPath $parent -DefaultPath 'installed'
            $expected = ConvertTo-NormalizedPath (Join-Path $parent 'custom-installed')

            $result | Should -Be $expected
        }
    }

    It 'uses an absolute parameter value without ParentPath' {
        InModuleScope -ScriptBlock {
            $parent = Join-Path $TestDrive 'parent'
            $absolute = Join-Path $TestDrive 'absolute-installed'
            New-Item -Path $parent -ItemType Directory | Out-Null
            New-Item -Path $absolute -ItemType Directory | Out-Null

            $result = Get-NormalizedNamedDir -Parameters @{ InstallDir = $absolute } -Name 'InstallDir' -ParentPath $parent -DefaultPath 'installed'
            $expected = ConvertTo-NormalizedPath $absolute

            $result | Should -Be $expected
        }
    }

    It 'removes trailing separators from the normalized result' {
        InModuleScope -ScriptBlock {
            $parent = Join-Path $TestDrive 'parent-with-trailing'
            New-Item -Path $parent -ItemType Directory | Out-Null

            $pathWithTrailingSeparator = (Join-Path $TestDrive 'absolute-with-trailing') + [System.IO.Path]::DirectorySeparatorChar
            New-Item -Path $pathWithTrailingSeparator -ItemType Directory | Out-Null

            $result = Get-NormalizedNamedDir -Parameters @{ InstallDir = $pathWithTrailingSeparator } -Name 'InstallDir' -ParentPath $parent -DefaultPath 'installed'

            $result.EndsWith([System.IO.Path]::DirectorySeparatorChar) | Should -BeFalse
        }
    }
}
```

- [ ] **Step 2: Run the focused test to verify red**

Run:

```powershell
Invoke-Pester -Path tests/Private/Get-NormalizedNamedDir.Tests.ps1
```

Expected: FAIL because `Get-NormalizedNamedDir.Tests.ps1` exists but the helper still has no standalone source file for QA; if the module can already call the nested helper, the behavioral tests may pass. The red condition for this task is also the QA discovery failure checked in Step 6.

- [ ] **Step 3: Move helper into its own file**

Create `NhcVcpkgTools/Private/Get-NormalizedNamedDir.ps1` with:

```powershell
Set-StrictMode -Version 3.0

function Get-NormalizedNamedDir {
    <#
    .SYNOPSIS
    Gets a normalized named directory path from command parameters.

    .DESCRIPTION
    Resolves a named directory setting from a parameter hashtable. If the named
    parameter is present, its value is used; otherwise DefaultPath is used. Relative
    paths are resolved under ParentPath and absolute paths are normalized directly.

    .PARAMETER Parameters
    Hashtable containing bound command parameters that may include the named directory.

    .PARAMETER Name
    Name of the directory parameter to read from Parameters.

    .PARAMETER ParentPath
    Parent directory used when the selected directory value is relative.

    .PARAMETER DefaultPath
    Relative default directory used when Parameters does not contain Name.

    .EXAMPLE
    Get-NormalizedNamedDir -Parameters @{} -Name 'InstallDir' -ParentPath 'C:\vcpkg' -DefaultPath 'installed'

    Returns the normalized path C:\vcpkg\installed.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$ParentPath,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$DefaultPath
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        if ($Parameters.ContainsKey($Name)) {
            $private:dir = $Parameters.$Name
        }
        else {
            $private:dir = $DefaultPath
        }

        if (Test-AbsolutePath -Path $dir) {
            $paths = @{ 'Path' = $dir }
            $paths += @{ 'ChildPath' = '.' }
        }
        else {
            $paths = @{ 'Path' = $ParentPath }
            $paths += @{ 'ChildPath' = $dir }
        }

        return ConvertTo-NormalizedPath(Join-RelativePath @paths)
    }
}
```

- [ ] **Step 4: Remove nested helper from Get-CommonArgument**

Delete only the `function Get-NormalizedNamedDir { ... }` block from the bottom of `NhcVcpkgTools/Private/Get-CommonArgument.ps1`. Do not change the existing calls to `Get-NormalizedNamedDir` inside `Get-CommonArgument`.

- [ ] **Step 5: Register the new private function file**

Modify `NhcVcpkgTools/NhcVcpkgTools.psm1` so `$private:PrivateFunctions` includes:

```powershell
    'Get-NormalizedNamedDir'
```

Place it with the other Get-* helpers, for example after `'Get-Executable'`.

- [ ] **Step 6: Run focused tests**

Run:

```powershell
Invoke-Pester -Path tests/Private/Get-NormalizedNamedDir.Tests.ps1
```

Expected: all tests in `Get-NormalizedNamedDir.Tests.ps1` PASS.

- [ ] **Step 7: Run QA discovery for this helper**

Run after building the module if needed:

```powershell
./build.ps1 -Tasks build
Invoke-Pester -Path tests/QA/module.tests.ps1 -Tag TestQuality
```

Expected: `Get-NormalizedNamedDir` no longer fails because the source path is null.

---

### Task 2: Add missing private-helper tests for Get-BinaryType and Test-EmptyDirectory

**Files:**
- Test: `tests/Private/Get-BinaryType.Tests.ps1`
- Test: `tests/Private/Test-EmptyDirectory.Tests.ps1`

- [ ] **Step 1: Create Get-BinaryType tests**

Create `tests/Private/Get-BinaryType.Tests.ps1` with:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-BinaryType' {
    It 'returns BinaryType.NONE for a non-executable file' {
        InModuleScope -ScriptBlock {
            $textFile = Join-Path $TestDrive 'not-a-binary.txt'
            Set-Content -Path $textFile -Value 'plain text is not a Windows executable'

            $result = Get-BinaryType -Path $textFile

            $result | Should -Be ([BinaryType]::NONE)
        }
    }

    It 'returns BinaryType.BIT64 for the current PowerShell executable' {
        InModuleScope -ScriptBlock {
            $powerShellPath = (Get-Process -Id $PID).Path

            $result = Get-BinaryType -Path $powerShellPath

            $result | Should -Be ([BinaryType]::BIT64)
        }
    }
}
```

- [ ] **Step 2: Run Get-BinaryType tests**

Run:

```powershell
Invoke-Pester -Path tests/Private/Get-BinaryType.Tests.ps1
```

Expected: PASS on modern 64-bit Windows PowerShell. If this fails because the host process is not 64-bit, use `$PSHOME\pwsh.exe` when present and only then fall back to `(Get-Process -Id $PID).Path`.

- [ ] **Step 3: Create Test-EmptyDirectory tests**

Create `tests/Private/Test-EmptyDirectory.Tests.ps1` with:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-EmptyDirectory' {
    It 'returns true for an empty directory' {
        InModuleScope -ScriptBlock {
            $directory = Join-Path $TestDrive 'empty'
            New-Item -Path $directory -ItemType Directory | Out-Null

            Test-EmptyDirectory -Path $directory | Should -BeTrue
        }
    }

    It 'returns false for a directory containing a file' {
        InModuleScope -ScriptBlock {
            $directory = Join-Path $TestDrive 'with-file'
            New-Item -Path $directory -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $directory 'file.txt') -ItemType File | Out-Null

            Test-EmptyDirectory -Path $directory | Should -BeFalse
        }
    }

    It 'returns false for a directory containing a hidden file' {
        InModuleScope -ScriptBlock {
            $directory = Join-Path $TestDrive 'with-hidden-file'
            New-Item -Path $directory -ItemType Directory | Out-Null
            $hiddenFile = New-Item -Path (Join-Path $directory 'hidden.txt') -ItemType File
            $hiddenFile.Attributes = $hiddenFile.Attributes -bor [System.IO.FileAttributes]::Hidden

            Test-EmptyDirectory -Path $directory | Should -BeFalse
        }
    }

    It 'throws for a nonexistent path' {
        InModuleScope -ScriptBlock {
            $missingPath = Join-Path $TestDrive 'missing'

            { Test-EmptyDirectory -Path $missingPath } | Should -Throw
        }
    }
}
```

- [ ] **Step 4: Run Test-EmptyDirectory tests**

Run:

```powershell
Invoke-Pester -Path tests/Private/Test-EmptyDirectory.Tests.ps1
```

Expected: the hidden-file test may FAIL because the production helper uses `Get-ChildItem` without `-Force`. That red result is valid and required by issue #21 wording about hidden files.

- [ ] **Step 5: If hidden-file test fails, make the minimal production fix**

Modify `NhcVcpkgTools/Private/Test-EmptyDirectory.ps1` so the return statement is:

```powershell
    return !(Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop | Select-Object -First 1)
```

Do not otherwise change the function.

- [ ] **Step 6: Re-run private helper tests**

Run:

```powershell
Invoke-Pester -Path tests/Private/Get-BinaryType.Tests.ps1, tests/Private/Test-EmptyDirectory.Tests.ps1
```

Expected: all tests PASS.

---

### Task 3: Expand Remove-NhcVcpkgPort error-scenario coverage

**Files:**
- Modify: `tests/Public/Remove-NhcVcpkgPort.Tests.ps1`

- [ ] **Step 1: Add issue #12 tests under a new context**

Append this context inside the existing `Describe 'Remove-NhcVcpkgPort'` block, after the existing `Context 'vcpkg exit status'` block:

```powershell
    Context 'vcpkg error scenarios' {
        It 'returns Status false and preserves arguments when vcpkg reports port not installed' {
            Mock Start-Process -ModuleName $script:moduleName {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$NoNewWindow,
                    [switch]$Wait,
                    [switch]$PassThru,
                    [switch]$WhatIf,
                    [switch]$Confirm
                )

                $script:capturedCommand = $FilePath
                $script:capturedArguments = $ArgumentList + @($NoNewWindow, $Wait, $PassThru, $WhatIf, $Confirm)
                return [pscustomobject]@{ ExitCode = 1 }
            }

            $result = Remove-NhcVcpkgPort -Ports 'not-installed' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
            $script:capturedCommand | Should -Be $script:rootInfo.Command
            $script:capturedArguments | Should -Contain 'remove'
            $script:capturedArguments | Should -Contain 'not-installed'
            $script:capturedArguments | Should -Contain '--classic'
        }

        It 'returns Status false when vcpkg fails to start' {
            Mock Start-Process -ModuleName $script:moduleName { throw 'cannot launch vcpkg' }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
        }

        It 'returns Status false for dependency conflict failures without Recurse' {
            Mock Start-Process -ModuleName $script:moduleName {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$NoNewWindow,
                    [switch]$Wait,
                    [switch]$PassThru,
                    [switch]$WhatIf,
                    [switch]$Confirm
                )

                $script:capturedCommand = $FilePath
                $script:capturedArguments = $ArgumentList + @($NoNewWindow, $Wait, $PassThru, $WhatIf, $Confirm)
                return [pscustomobject]@{ ExitCode = 1 }
            }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
            $script:capturedArguments | Should -Contain 'zlib'
            $script:capturedArguments | Should -Not -Contain '--recurse'
        }

        It 'passes Start-Process errors through the error stream when Quiet is not specified' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { Write-Error 'vcpkg stderr text'; return [pscustomobject]@{ ExitCode = 1 } }

                $errors = Invoke-Vcpkg -Command 'vcpkg' -Arguments @('remove', 'zlib') 2>&1

                $errors | Should -Not -BeNullOrEmpty
                ($errors | Out-String) | Should -Match 'vcpkg stderr text'
            }
        }

        It 'suppresses Start-Process invocation errors when Quiet is specified' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { Write-Error 'vcpkg stderr text'; return [pscustomobject]@{ ExitCode = 1 } }

                $errors = Invoke-Vcpkg -Command 'vcpkg' -Arguments @('remove', 'zlib') -Quiet 2>&1

                $errors | Should -BeNullOrEmpty
            }
        }
    }
```

- [ ] **Step 2: Run the public test file**

Run:

```powershell
Invoke-Pester -Path tests/Public/Remove-NhcVcpkgPort.Tests.ps1
```

Expected: all tests PASS or show a specific mismatch in how `Start-Process` mock errors flow through `Invoke-Vcpkg`. If the Quiet tests fail because `Invoke-Vcpkg` catches terminating errors rather than forwarding them, adjust the tests to verify the implemented contract from the spec: child process output is inherited through `-NoNewWindow`, and `Quiet` suppresses Start-Process invocation errors. Do not add stderr-buffer capture production behavior.

- [ ] **Step 3: Refactor only duplicated mock setup if it becomes noisy**

If PSScriptAnalyzer complains about duplicated parameter lists or unused parameters in test mocks, keep the mock blocks explicit but remove unused parameter names. Do not refactor production code for this task.

---

### Task 4: Integrated verification and graph update

**Files:**
- Modify: `graphify-out/` generated graph artifacts if `graphify update .` changes tracked files.
- No source changes unless verification reveals a defect.

- [ ] **Step 1: Run targeted private tests**

Run:

```powershell
Invoke-Pester -Path tests/Private/Get-NormalizedNamedDir.Tests.ps1, tests/Private/Get-BinaryType.Tests.ps1, tests/Private/Test-EmptyDirectory.Tests.ps1
```

Expected: all targeted private tests PASS.

- [ ] **Step 2: Run targeted public tests**

Run:

```powershell
Invoke-Pester -Path tests/Public/Remove-NhcVcpkgPort.Tests.ps1
```

Expected: all Remove-NhcVcpkgPort tests PASS.

- [ ] **Step 3: Build module**

Run:

```powershell
./build.ps1 -Tasks build
```

Expected: build completes successfully.

- [ ] **Step 4: Run QA TestQuality checks**

Run:

```powershell
Invoke-Pester -Path tests/QA/module.tests.ps1 -Tag TestQuality
```

Expected: TestQuality checks PASS, including unit-test discovery and Script Analyzer checks for Get-BinaryType, Test-EmptyDirectory, and Get-NormalizedNamedDir.

- [ ] **Step 5: Run canonical full test suite**

Run:

```powershell
./build.ps1 -Tasks test
```

Expected: build/test workflow completes successfully.

- [ ] **Step 6: Refresh graphify output**

Run:

```powershell
graphify update .
```

Expected: graph update completes. Stage graphify changes only if they are tracked project artifacts and not ignored files.

- [ ] **Step 7: Prepare final commit set**

Review changed files:

```powershell
git status --short
git diff --stat
```

Expected changes include the plan file, new private tests, new helper source file, loader/source updates, and public test additions. Use the `nhc-conventional-commit` skill for commit messages and do not commit without user confirmation.
