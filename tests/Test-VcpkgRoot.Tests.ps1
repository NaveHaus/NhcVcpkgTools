Describe 'Test-VcpkgRoot' {
    BeforeAll {
    . "$PSScriptRoot/../NhcVcpkgTools/private/Join-RelativePath.ps1"
    . "$PSScriptRoot/../NhcVcpkgTools/private/Test-VcpkgRoot.ps1"
        $rootDir = Join-Path $TestDrive "vcpkgroot"
        New-Item -Path $rootDir -ItemType Directory | Out-Null
        New-Item -Path (Join-Path $rootDir ".vcpkg-root") -ItemType File | Out-Null
        $noMarkerDir = Join-Path $TestDrive "notvcpkg"
        New-Item -Path $noMarkerDir -ItemType Directory | Out-Null
        $someFile = Join-Path $TestDrive "afile.txt"
        Set-Content -Path $someFile -Value "not a directory"
    }

    Context 'Checks for .vcpkg-root marker' {
        It 'returns true for directory containing .vcpkg-root file' {
            Test-VcpkgRoot -Path $rootDir | Should -BeTrue
        }
        It 'returns false for directory without .vcpkg-root file' {
            Test-VcpkgRoot -Path $noMarkerDir | Should -BeFalse
        }
        It 'returns false for path that does not exist' {
            Test-VcpkgRoot -Path "$TestDrive\nothinghere" | Should -BeFalse
        }
        It 'returns false for a file (not a directory)' {
            Test-VcpkgRoot -Path $someFile | Should -BeFalse
        }
    }
}