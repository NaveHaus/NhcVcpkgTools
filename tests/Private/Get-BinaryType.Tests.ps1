BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-BinaryType' {
    It 'returns BinaryType.NONE for a non-executable file' {
        InModuleScope -ScriptBlock {
            $textFile = Join-Path $TestDrive 'not-a-binary.txt'
            Set-Content -Path $textFile -Value 'plain text is not a Windows executable'

            $result = Get-BinaryType -Path $textFile

            $result | Should -Be ([BinaryType]::NONE)
        }
    }

    It 'returns BinaryType.BIT64 for a stable 64-bit PowerShell executable' {
        InModuleScope -ScriptBlock {
            $candidatePaths = @((Get-Process -Id $PID).Path)
            $pwshPath = Join-Path $PSHOME 'pwsh.exe'
            if (Test-Path -LiteralPath $pwshPath) {
                $candidatePaths += $pwshPath
            }

            $result = $null
            foreach ($candidatePath in ($candidatePaths | Where-Object { $_ } | Select-Object -Unique)) {
                $candidateResult = Get-BinaryType -Path $candidatePath
                if ($candidateResult -eq [BinaryType]::BIT64) {
                    $result = $candidateResult
                    break
                }
            }

            $result | Should -Be ([BinaryType]::BIT64)
        }
    }
}