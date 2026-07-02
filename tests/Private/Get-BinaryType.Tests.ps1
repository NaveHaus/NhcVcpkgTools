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

    It 'returns BinaryType.BIT64 for a stable 64-bit PowerShell executable' -Skip:(-not $IsWindows) {
        InModuleScope -ScriptBlock {
            $candidatePaths = @((Get-Process -Id $PID).Path)
            $pwshPath = Join-Path $PSHOME 'pwsh.exe'
            if (Test-Path -LiteralPath $pwshPath) {
                $candidatePaths += $pwshPath
            }

            $candidateResults = @()
            $result = $null
            foreach ($candidatePath in ($candidatePaths | Where-Object { $_ } | Select-Object -Unique)) {
                $candidateResult = Get-BinaryType -Path $candidatePath
                $candidateResults += [pscustomobject]@{
                    Path = $candidatePath
                    BinaryType = $candidateResult
                }
                if ($candidateResult -eq [BinaryType]::BIT64) {
                    $result = $candidateResult
                    break
                }
            }

            if ($result -ne [BinaryType]::BIT64) {
                $details = ($candidateResults | ForEach-Object { "$($_.Path) => $($_.BinaryType)" }) -join '; '
                throw "Expected at least one candidate to resolve to BinaryType.BIT64, but none did. Candidates: $details"
            }

            $result | Should -Be ([BinaryType]::BIT64)
        }
    }
}
