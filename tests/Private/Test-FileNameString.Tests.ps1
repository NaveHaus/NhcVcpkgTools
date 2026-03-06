BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-FileNameString' {
    Context 'Valid file names' {
        It 'returns true for a simple file name' {
            InModuleScope -ScriptBlock {
                Test-FileNameString -FileName "file.txt" | Should -BeTrue
            }
        }
        It 'returns true for a file name with underscores and numbers' {
            InModuleScope -ScriptBlock {
                Test-FileNameString -FileName "my_file_123" | Should -BeTrue
            }
        }
        It 'returns true for a file name with spaces' {
            InModuleScope -ScriptBlock {
                Test-FileNameString -FileName "file name.txt" | Should -BeTrue
            }
        }
    }

    Context 'Invalid file names' {
        It 'returns false for a name with multiple invalid chars' {
            InModuleScope -ScriptBlock {
                Test-FileNameString -FileName "bad:name|file.txt" | Should -BeFalse
            }
        }
    }
}
