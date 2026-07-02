BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-NormalizedNamedDir' {
    It 'has its own private source file' {
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath '../../NhcVcpkgTools/Private/Get-NormalizedNamedDir.ps1'
        Test-Path -LiteralPath $sourcePath -PathType Leaf | Should -BeTrue
    }

    It 'returns the default relative path under the parent path' {
        InModuleScope -ScriptBlock {
            $parentPath = Join-Path -Path $TestDrive -ChildPath 'vcpkg-root'
            $result = Get-NormalizedNamedDir -Parameters @{} -Name 'DownloadDir' -ParentPath $parentPath -DefaultPath 'downloads'

            $result | Should -Be (Join-Path -Path $parentPath -ChildPath 'downloads')
        }
    }

    It 'returns an explicit relative path under the parent path' {
        InModuleScope -ScriptBlock {
            $parentPath = Join-Path -Path $TestDrive -ChildPath 'vcpkg-root'
            $result = Get-NormalizedNamedDir -Parameters @{ DownloadDir = 'custom-downloads' } -Name 'DownloadDir' -ParentPath $parentPath -DefaultPath 'downloads'

            $result | Should -Be (Join-Path -Path $parentPath -ChildPath 'custom-downloads')
        }
    }

    It 'returns an explicit absolute path unchanged except normalization' {
        InModuleScope -ScriptBlock {
            $parentPath = Join-Path -Path $TestDrive -ChildPath 'vcpkg-root'
            $absolutePath = Join-Path -Path $TestDrive -ChildPath 'absolute-downloads'
            $result = Get-NormalizedNamedDir -Parameters @{ DownloadDir = $absolutePath } -Name 'DownloadDir' -ParentPath $parentPath -DefaultPath 'downloads'

            $result | Should -Be $absolutePath
        }
    }

    It 'normalizes trailing separators from explicit directory paths' {
        InModuleScope -ScriptBlock {
            $parentPath = Join-Path -Path $TestDrive -ChildPath 'vcpkg-root'
            $relativePath = "custom-downloads$([System.IO.Path]::DirectorySeparatorChar)"
            $result = Get-NormalizedNamedDir -Parameters @{ DownloadDir = $relativePath } -Name 'DownloadDir' -ParentPath $parentPath -DefaultPath 'downloads'

            $result | Should -Be (Join-Path -Path $parentPath -ChildPath 'custom-downloads')
        }
    }
}




