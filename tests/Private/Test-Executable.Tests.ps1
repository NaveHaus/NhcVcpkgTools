BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-Executable' {
    Context 'Check existing .exe file by path' {
        It 'returns true for a valid .exe file' {
            InModuleScope -ScriptBlock {
                $powershellExe = (Get-Command -Name "powershell" -CommandType Application).Source
                Test-Executable -Path $powershellExe | Should -BeTrue
            }
        }
        It 'returns false for a non-executable file' {
            InModuleScope -ScriptBlock {
                $tempFile = Join-Path $TestDrive "notepad.txt"
                Set-Content -Path $tempFile -Value "not an exe"
                Test-Executable -Path $tempFile | Should -BeFalse
            }
        }
        It 'returns false for a path that does not exist' {
            InModuleScope -ScriptBlock {
                Test-Executable -Path "$TestDrive\missing.exe" | Should -BeFalse
            }
        }
    }

    Context 'Check executable by name in directory' {
        It 'returns true for a valid executable name in known directory' {
            InModuleScope -ScriptBlock {
                $powershellExe = (Get-Command -Name "powershell" -CommandType Application).Source
                $powershellDir = [System.IO.Path]::GetDirectoryName($powershellExe)
                $powershellName = [System.IO.Path]::GetFileName($powershellExe)
                Test-Executable -Path $powershellDir -Name $powershellName | Should -BeTrue
            }
        }
        It 'returns false for an invalid name in known directory' {
            InModuleScope -ScriptBlock {
                $powershellExe = (Get-Command -Name "powershell" -CommandType Application).Source
                $powershellDir = [System.IO.Path]::GetDirectoryName($powershellExe)
                { Test-Executable -Path $powershellDir -Name "notareal.exe" } | Should -Not -Throw
                Test-Executable -Path $powershellDir -Name "notareal.exe" | Should -BeFalse
            }
        }
        It 'returns false for invalid directory' {
            InModuleScope -ScriptBlock {
                $powershellName = [System.IO.Path]::GetFileName((Get-Command -Name "powershell" -CommandType Application).Source)
                Test-Executable -Path "$TestDrive\nonexistent" -Name $powershellName | Should -BeFalse
            }
        }
    }
}
