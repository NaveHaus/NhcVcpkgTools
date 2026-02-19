Describe 'Test-PathString' {
    BeforeAll {
        . "$PSScriptRoot/../NhcVcpkgTools/private/Test-PathString.ps1"
    }

    Context 'Valid paths' {
        It 'returns true for a typical Windows path' {
            Test-PathString -Path "C:\Users\user\file.txt" | Should -BeTrue
        }
        It 'returns true for a relative path' {
            Test-PathString -Path ".\myfolder\file.txt" | Should -BeTrue
        }
        It 'returns true for a unix-style path' {
            Test-PathString -Path "/home/user/file.txt" | Should -BeTrue
        }
        It 'returns true for a path with spaces' {
            Test-PathString -Path "C:\Some Folder\file.txt" | Should -BeTrue
        }
        # Remove empty string test: PowerShell cannot bind empty string to mandatory [string] param
    }

    Context 'Invalid paths' {
        $invalidChars = [System.IO.Path]::GetInvalidPathChars()
        foreach ($char in $invalidChars) {
            if (
                $null -ne $char -and
                $char -is [char] -and
                [char]::IsControl($char) -eq $false -and
                $char -notin @('|', '\', '/', ':', '*', '?', '"', '<', '>')
            ) {
                It ("returns false for invalid path containing '{0}'" -f $char) {
                    Test-PathString -Path ("folder{0}file.txt" -f $char) | Should -BeFalse
                }
            }
        }
        It 'returns false for a path with multiple invalid chars' {
            Test-PathString -Path "bad:path|file.txt" | Should -BeFalse
        }
    }
}