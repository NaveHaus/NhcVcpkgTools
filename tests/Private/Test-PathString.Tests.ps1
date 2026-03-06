BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-PathString' {
    Context 'Valid paths' {
        It 'returns true for a typical Windows path' {
            InModuleScope -ScriptBlock {
                Test-PathString -Path "C:\Users\user\file.txt" | Should -BeTrue
            }
        }
        It 'returns true for a relative path' {
            InModuleScope -ScriptBlock {
                Test-PathString -Path ".\myfolder\file.txt" | Should -BeTrue
            }
        }
        It 'returns true for a unix-style path' {
            InModuleScope -ScriptBlock {
                Test-PathString -Path "/home/user/file.txt" | Should -BeTrue
            }
        }
        It 'returns true for a path with spaces' {
            InModuleScope -ScriptBlock {
                Test-PathString -Path "C:\Some Folder\file.txt" | Should -BeTrue
            }
        }
    }

    Context 'Invalid paths' {
        $invalidChars = [System.IO.Path]::GetInvalidPathChars()
        foreach ($char in $invalidChars) {
            if (
                $null -ne $char -and
                $char -is [char] -and
                [char]::IsControl($char) -eq $false -and
                $char -notin @('|', '\\', '/', ':', '*', '?', '"', '<', '>')
            ) {
                It ("returns false for invalid path containing '{0}'" -f $char) {
                    InModuleScope -ScriptBlock {
                        Test-PathString -Path ("folder{0}file.txt" -f $char) | Should -BeFalse
                    }
                }
            }
        }
        It 'returns false for a path with multiple invalid chars' {
            InModuleScope -ScriptBlock {
                Test-PathString -Path "bad:path|file.txt" | Should -BeFalse
            }
        }
    }
}
