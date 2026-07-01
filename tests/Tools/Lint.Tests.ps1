BeforeAll {
    . "$PSScriptRoot/../../tools/lint.ps1"
}

Describe 'lint runner' {
    Context 'github mode annotation output' {
        It 'formats diagnostics as compact GitHub annotations' {
            $repoRoot = Join-Path -Path $TestDrive -ChildPath 'repo'
            $diagnosticPath = Join-Path -Path $repoRoot -ChildPath 'NhcVcpkgTools/Public/Test.ps1'

            Mock Get-LintTargetFile {
                $diagnosticPath
            }

            Mock Invoke-ScriptAnalyzer {
                @(
                    [pscustomobject]@{
                        Severity   = 'Warning'
                        RuleName   = 'PSUseApprovedVerbs'
                        Message    = 'Use an approved verb.'
                        ScriptPath = $diagnosticPath
                        Line       = 12
                        Column     = 7
                    }
                )
            }

            $result = Invoke-LintRunner -Mode github -RepoRoot $repoRoot -SettingsPath 'dummy-settings.psd1'

            $result.OutputLines | Should -HaveCount 1
            $result.OutputLines[0] | Should -Be '::warning file=NhcVcpkgTools/Public/Test.ps1,line=12,col=7::[PSUseApprovedVerbs] Use an approved verb.'
        }
    }

    Context 'exit code policy' {
        It 'returns non-zero when warnings or errors exist' {
            Mock Get-LintTargetFile {
                'NhcVcpkgTools/Public/Test.ps1'
            }

            Mock Invoke-ScriptAnalyzer {
                @(
                    [pscustomobject]@{
                        Severity   = 'Warning'
                        RuleName   = 'PSUseApprovedVerbs'
                        Message    = 'Use an approved verb.'
                        ScriptPath = 'NhcVcpkgTools/Public/Test.ps1'
                        Line       = 1
                        Column     = 1
                    }
                )
            }

            $result = Invoke-LintRunner -Mode local -RepoRoot $TestDrive -SettingsPath 'dummy-settings.psd1'

            $result.ExitCode | Should -Be 1
        }

        It 'returns zero when there are no findings' {
            Mock Get-LintTargetFile {
                'NhcVcpkgTools/Public/Test.ps1'
            }

            Mock Invoke-ScriptAnalyzer {
                @()
            }

            $result = Invoke-LintRunner -Mode local -RepoRoot $TestDrive -SettingsPath 'dummy-settings.psd1'

            $result.ExitCode | Should -Be 0
        }
    }

    Context 'analysis scope' {
        It 'includes only targeted directories and extensions' {
            $repoRoot = Join-Path -Path $TestDrive -ChildPath 'repo'

            $targetModuleFile = Join-Path -Path $repoRoot -ChildPath 'NhcVcpkgTools/Public/Export-NhcVcpkgPort.ps1'
            $targetModuleManifest = Join-Path -Path $repoRoot -ChildPath 'NhcVcpkgTools/NhcVcpkgTools.psd1'
            $targetTestFile = Join-Path -Path $repoRoot -ChildPath 'tests/Private/Get-Executable.Tests.ps1'
            $targetToolFile = Join-Path -Path $repoRoot -ChildPath 'tools/lint.ps1'

            $nonTargetOpenSpec = Join-Path -Path $repoRoot -ChildPath 'openspec/changes/add-linter/tasks.md'
            $nonTargetGitHooks = Join-Path -Path $repoRoot -ChildPath '.git/hooks/pre-commit'
            $nonTargetRootScript = Join-Path -Path $repoRoot -ChildPath 'build.ps1'

            foreach ($file in @(
                $targetModuleFile,
                $targetModuleManifest,
                $targetTestFile,
                $targetToolFile,
                $nonTargetOpenSpec,
                $nonTargetGitHooks,
                $nonTargetRootScript
            )) {
                $null = New-Item -Path $file -ItemType File -Force
            }

            $files = Get-LintTargetFile -RepoRoot $repoRoot

            $files | Should -Contain $targetModuleFile
            $files | Should -Contain $targetModuleManifest
            $files | Should -Contain $targetTestFile
            $files | Should -Contain $targetToolFile
            $files | Should -Not -Contain $nonTargetOpenSpec
            $files | Should -Not -Contain $nonTargetGitHooks
            $files | Should -Not -Contain $nonTargetRootScript
        }
    }

    Context 'repo-relative path normalization' {
        It 'normalizes paths inside the repository to repo-relative form' {
            $repoRoot = Join-Path -Path $TestDrive -ChildPath 'repo'
            $absolutePath = Join-Path -Path $repoRoot -ChildPath 'NhcVcpkgTools/Public/Export-NhcVcpkgPort.ps1'

            $relative = Resolve-RepoRelativePath -Path $absolutePath -RepoRoot $repoRoot

            $relative | Should -Be 'NhcVcpkgTools/Public/Export-NhcVcpkgPort.ps1'
        }
    }

    Context 'default settings path' {
        It 'uses the repository default ScriptAnalyzer settings path' {
            $lintScriptPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lint.ps1')).Path

            $capturedSettingsPath = & {
                param($ScriptPath)

                . $ScriptPath
                $SettingsPath
            } $lintScriptPath

            $expectedSettingsPath = Join-Path -Path (Split-Path -Path $lintScriptPath -Parent) -ChildPath '..\PSScriptAnalyzerSettings.psd1'
            $expectedSettingsPath = [System.IO.Path]::GetFullPath($expectedSettingsPath)

            [System.IO.Path]::GetFullPath($capturedSettingsPath) | Should -Be $expectedSettingsPath
        }
    }

    Context 'local mode output' {
        It 'formats diagnostics as rich local output' {
            $repoRoot = Join-Path -Path $TestDrive -ChildPath 'repo'
            $diagnosticPath = Join-Path -Path $repoRoot -ChildPath 'tools/lint.ps1'

            Mock Get-LintTargetFile {
                $diagnosticPath
            }

            Mock Invoke-ScriptAnalyzer {
                @(
                    [pscustomobject]@{
                        Severity   = 'Warning'
                        RuleName   = 'PSUseApprovedVerbs'
                        Message    = 'Use an approved verb.'
                        ScriptPath = $diagnosticPath
                        Line       = 42
                        Column     = 2
                    }
                )
            }

            $result = Invoke-LintRunner -Mode local -RepoRoot $repoRoot -SettingsPath 'dummy-settings.psd1'

            $result.OutputLines | Should -HaveCount 1
            $result.OutputLines[0] | Should -Be '[Warning] PSUseApprovedVerbs: Use an approved verb. (tools/lint.ps1:42)'
        }
    }
}
