BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-VcpkgRoot' {
    Context 'Checks for .vcpkg-root marker' {
        It 'returns true for directory containing .vcpkg-root file' {
            InModuleScope -ScriptBlock {
                $rootDir = Join-Path $TestDrive "vcpkgroot"
                New-Item -Path $rootDir -ItemType Directory | Out-Null
                New-Item -Path (Join-Path $rootDir ".vcpkg-root") -ItemType File | Out-Null
                Test-VcpkgRoot -Path $rootDir | Should -BeTrue
            }
        }
        It 'returns false for directory without .vcpkg-root file' {
            InModuleScope -ScriptBlock {
                $noMarkerDir = Join-Path $TestDrive "notvcpkg"
                New-Item -Path $noMarkerDir -ItemType Directory | Out-Null
                Test-VcpkgRoot -Path $noMarkerDir | Should -BeFalse
            }
        }
        It 'returns false for path that does not exist' {
            InModuleScope -ScriptBlock {
                Test-VcpkgRoot -Path "$TestDrive\nothinghere" | Should -BeFalse
            }
        }
        It 'returns false for a file (not a directory)' {
            InModuleScope -ScriptBlock {
                $someFile = Join-Path $TestDrive "afile.txt"
                Set-Content -Path $someFile -Value "not a directory"
                Test-VcpkgRoot -Path $someFile | Should -BeFalse
            }
        }
    }
}
