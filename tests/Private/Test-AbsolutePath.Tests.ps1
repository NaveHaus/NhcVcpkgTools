BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-AbsolutePath' {
    Context 'Validates absolute and relative paths' {
        It 'returns true for absolute Windows path' {
            InModuleScope -ScriptBlock {
                Test-AbsolutePath -Path "C:\Windows" | Should -BeTrue
            }
        }
        It 'returns false for relative path' {
            InModuleScope -ScriptBlock {
                Test-AbsolutePath -Path "foo\bar" | Should -BeFalse
            }
        }
        It 'returns true for UNC root path' {
            InModuleScope -ScriptBlock {
                Test-AbsolutePath -Path "\\server\share" | Should -BeTrue
            }
        }
        It 'returns false for current directory relative path' {
            InModuleScope -ScriptBlock {
                Test-AbsolutePath -Path ".\something" | Should -BeFalse
            }
        }
    }
}
