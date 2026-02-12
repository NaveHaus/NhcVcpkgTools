BeforeAll {
    . "$PSScriptRoot/../src/private/Get-CommonArguments.ps1"
}

Describe 'Get-CommonArguments' {
    Context 'Basic Functionality' {
        It 'should throw an error if Command is invalid' {
            $params = @{ Command = 'invalid-exe' }
            { Get-CommonArguments -Parameters $params } | Should -Throw
        }

        It 'should detect root from RootDir and Command' {
            $rootDir = (Get-Location).ProviderPath
            $exePath = Join-Path -Path $rootDir -ChildPath 'vcpkg.exe'
            # Mock Test-VcpkgRoot and Test-Executable to simulate environment
            Mock Test-VcpkgRoot { return $true }
            Mock Test-Executable { return $true }
            Mock Get-Executable { return $exePath }
            $params = @{ RootDir = $rootDir; Command = $exePath }
            $result = Get-CommonArguments -Parameters $params
            $result.RootDir | Should -Be $rootDir
            $result.Command | Should -Be $exePath
        }

        It 'should include classic mode when Ports key is present' {
            $params = @{ Ports = $true; RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
            Mock Test-VcpkgRoot { return $true }
            Mock Test-Executable { return $true }
            Mock Get-Executable { return 'vcpkg.exe' }
            $result = Get-CommonArguments -Parameters $params
            $result.Arguments | Should -Contain '--classic'
        }

        It 'should include feature flags when All key is present' {
            $params = @{ All = $true; RootDir = (Get-Location).ProviderPath; Command = 'vcpkg.exe' }
            Mock Test-VcpkgRoot { return $true }
            Mock Test-Executable { return $true }
            Mock Get-Executable { return 'vcpkg.exe' }
            $result = Get-CommonArguments -Parameters $params
            $result.Arguments | Where-Object { $_ -like '*manifest*' } | Should -Not -BeNullOrEmpty
        }

        It 'should include output directories with correct flags' {
            $params = @{
                RootDir = (Get-Location).ProviderPath
                Command = 'vcpkg.exe'
                DownloadDir = 'customdownloads'
                BuildDir = 'custombuildtrees'
                PackageDir = 'custompackages'
                InstallDir = 'custominstalled'
            }
            Mock Test-VcpkgRoot { return $true }
            Mock Test-Executable { return $true }
            Mock Get-Executable { return 'vcpkg.exe' }
            Mock ConvertTo-NormalizedPath { param($Path) return $Path }
            $result = Get-CommonArguments -Parameters $params
            $result.Arguments | Should -Contain '--downloads-root=`"customdownloads`"'
            $result.Arguments | Should -Contain '--x-buildtrees-root=`"custombuildtrees`"'
            $result.Arguments | Should -Contain '--x-packages-root=`"custompackages`"'
            $result.Arguments | Should -Contain '--x-install-root=`"custominstalled`"'
        }
    }
}