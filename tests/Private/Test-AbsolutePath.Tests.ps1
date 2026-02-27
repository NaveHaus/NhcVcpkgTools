Describe 'Test-AbsolutePath' {
    BeforeAll {
    . "$PSScriptRoot/../../NhcVcpkgTools/Private/Test-AbsolutePath.ps1"
    }

    Context 'Validates absolute and relative paths' {
        It 'returns true for absolute Windows path' {
            Test-AbsolutePath -Path "C:\Windows" | Should -BeTrue
        }
        It 'returns false for relative path' {
            Test-AbsolutePath -Path "foo\bar" | Should -BeFalse
        }
        It 'returns true for UNC root path' {
            Test-AbsolutePath -Path "\\server\share" | Should -BeTrue
        }
        It 'returns false for current directory relative path' {
            Test-AbsolutePath -Path ".\something" | Should -BeFalse
        }
    }

    Context 'Edge cases' {
        # Removed empty string test: PowerShell cannot bind empty string to mandatory [string] param
    }
}
