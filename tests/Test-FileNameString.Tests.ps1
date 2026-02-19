Describe 'Test-FileNameString' {
    BeforeAll {
        . "$PSScriptRoot/../NhcVcpkgTools/private/Test-FileNameString.ps1"
    }

    Context 'Valid file names' {
        It 'returns true for a simple file name' {
            Test-FileNameString -FileName "file.txt" | Should -BeTrue
        }
        It 'returns true for a file name with underscores and numbers' {
            Test-FileNameString -FileName "my_file_123" | Should -BeTrue
        }
        It 'returns true for a file name with spaces' {
            Test-FileNameString -FileName "file name.txt" | Should -BeTrue
        }
        # Remove empty string test: PowerShell cannot bind empty string to mandatory [string] param
    }

    Context 'Invalid file names' {
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        foreach ($char in $invalidChars) {
            if (
                $null -ne $char -and
                $char -is [char] -and
                [char]::IsControl($char) -eq $false -and
                $char -notin @('|', '\', '/', ':', '*', '?', '"', '<', '>')
            ) {
                It ("returns false for invalid file name containing '{0}'" -f $char) {
                    Test-FileNameString -FileName ("file{0}.txt" -f $char) | Should -BeFalse
                }
            }
        }
        It 'returns false for a name with multiple invalid chars' {
            Test-FileNameString -FileName "bad:name|file.txt" | Should -BeFalse
        }
    }
}