BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-CommonArguments' {
    BeforeEach {
        Mock Test-VcpkgRoot { return $true }
        Mock Test-Executable { return $true }
        Mock Get-Executable { return 'vcpkg.exe' }
        Mock ConvertTo-NormalizedPath { param($Path) return $Path }
        Mock Resolve-Path { param($Path) return $Path }
    }

    Context 'Basic Functionality' {
        It 'should throw an error if Command is invalid' {
            InModuleScope -ScriptBlock {
                $params = @{ Command = 'invalid-exe' }
                { Get-CommonArguments -Parameters $params } | Should -Throw
            }
        }

        It 'should detect root from RootDir and Command' {
            InModuleScope -ScriptBlock {
                $rootDir = (Get-Location).ProviderPath
                $exePath = Join-Path -Path $rootDir -ChildPath 'vcpkg.exe'
                Mock Get-Executable { return $exePath }
                $params = @{ RootDir = $rootDir; Command = $exePath }
                $result = Get-CommonArguments -Parameters $params
                $result.RootDir | Should -Be $rootDir
                $result.Command | Should -Be $exePath
            }
        }

        It 'should include classic mode when Ports key is present' {
            InModuleScope -ScriptBlock {
                $params = @{ Ports = 'zlib'; RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Should -Contain '--classic'
            }
        }

        It 'should include feature flags when All key is present' {
            InModuleScope -ScriptBlock {
                $params = @{ All = $true; RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Where-Object { $_ -like '*manifest*' } | Should -Not -BeNullOrEmpty
            }
        }

        It 'should include output directories with correct flags' {
            InModuleScope -ScriptBlock {
                $rootDir = (Get-Location).ProviderPath
                $params = @{
                    RootDir     = $rootDir
                    Command     = 'vcpkg.exe'
                    DownloadDir = 'customdownloads'
                    BuildDir    = 'custombuildtrees'
                    PackageDir  = 'custompackages'
                    InstallDir  = 'custominstalled'
                }
                $expectedDownloadDir = Join-Path -Path $rootDir -ChildPath 'customdownloads'
                $expectedBuildDir = Join-Path -Path $rootDir -ChildPath 'custombuildtrees'
                $expectedPackageDir = Join-Path -Path $rootDir -ChildPath 'custompackages'
                $expectedInstallDir = Join-Path -Path $rootDir -ChildPath 'custominstalled'
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Should -Contain "--downloads-root=`"$expectedDownloadDir`""
                $result.Arguments | Should -Contain "--x-buildtrees-root=`"$expectedBuildDir`""
                $result.Arguments | Should -Contain "--x-packages-root=`"$expectedPackageDir`""
                $result.Arguments | Should -Contain "--x-install-root=`"$expectedInstallDir`""
            }
        }
    }

    Context 'Outdated Parameter' {
        It 'should include --outdated flag when Outdated key is present and truthy' {
            InModuleScope -ScriptBlock {
                $params = @{ Outdated = $true; RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Should -Contain '--outdated'
            }
        }

        It 'should NOT include --outdated flag when Outdated key is not present' {
            InModuleScope -ScriptBlock {
                $params = @{ RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Should -Not -Contain '--outdated'
            }
        }
    }

    Context 'Recurse Parameter' {
        It 'should include --recurse flag when Recurse key is present and truthy' {
            InModuleScope -ScriptBlock {
                $params = @{ Recurse = $true; RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Should -Contain '--recurse'
            }
        }

        It 'should NOT include --recurse flag when Recurse key is not present' {
            InModuleScope -ScriptBlock {
                $params = @{ RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
                $result = Get-CommonArguments -Parameters $params
                $result.Arguments | Should -Not -Contain '--recurse'
            }
        }
    }

    Context 'String Path Returns' {
        It 'should return all Path values as strings in the result hashtable' {
            InModuleScope -ScriptBlock {
                $rootDir = (Get-Location).ProviderPath
                $params = @{
                    RootDir = $rootDir
                    Command = 'vcpkg.exe'
                }
                $result = Get-CommonArguments -Parameters $params
                
                # Verify Command and RootDir are strings
                $result.Command | Should -BeOfType [string]
                $result.RootDir | Should -BeOfType [string]
                
                # Verify all directory Path values are strings
                $result.ParentDir.Path | Should -BeOfType [string]
                $result.DownloadDir.Path | Should -BeOfType [string]
                $result.BuildDir.Path | Should -BeOfType [string]
                $result.PackageDir.Path | Should -BeOfType [string]
                $result.InstallDir.Path | Should -BeOfType [string]
            }
        }
    }
}