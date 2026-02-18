Describe 'Test-Executable' {
    BeforeAll {
        . "$PSScriptRoot/../src/private/Test-FileNameString.ps1"
        . "$PSScriptRoot/../src/private/Test-PathString.ps1"
        . "$PSScriptRoot/../src/private/Test-Executable.ps1"
        $powershellExe = (Get-Command -Name "powershell" -CommandType Application).Source
        $powershellDir = [System.IO.Path]::GetDirectoryName($powershellExe)
        $powershellName = [System.IO.Path]::GetFileName($powershellExe)
        $tempFile = Join-Path $TestDrive "notepad.txt"
        Set-Content -Path $tempFile -Value "not an exe"
    }

    Context 'Check existing .exe file by path' {
        It 'returns true for a valid .exe file' {
            Test-Executable -Path $powershellExe | Should -BeTrue
        }
        It 'returns false for a non-executable file' {
            Test-Executable -Path $tempFile | Should -BeFalse
        }
        It 'returns false for a path that does not exist' {
            Test-Executable -Path "$TestDrive\missing.exe" | Should -BeFalse
        }
    }

    Context 'Check executable by name in directory' {
        It 'returns true for a valid executable name in known directory' {
            Test-Executable -Path $powershellDir -Name $powershellName | Should -BeTrue
        }
        It 'returns false for an invalid name in known directory' {
            { Test-Executable -Path $powershellDir -Name "notareal.exe" } | Should -Not -Throw
            Test-Executable -Path $powershellDir -Name "notareal.exe" | Should -BeFalse
        }
        It 'returns false for invalid directory' {
            Test-Executable -Path "$TestDrive\nonexistent" -Name $powershellName | Should -BeFalse
        }
    }
}