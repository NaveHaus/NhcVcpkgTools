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

            $result = Export-NhcVcpkgPorts -Ports 'zlib' -Raw -Quiet -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -OutputDir $script:outputDir -Tag 'run'

            $result.Status | Should -BeFalse
        }

        It 'returns Status true when vcpkg exits zero' {
            $result = Export-NhcVcpkgPorts -Ports 'zlib' -Raw -Quiet -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -OutputDir $script:outputDir -Tag 'run'

            $result.Status | Should -BeTrue
        }
    }
}
