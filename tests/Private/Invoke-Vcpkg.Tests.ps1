BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Invoke-Vcpkg' {
    Context 'Exit code handling' {
        It 'returns $true when vcpkg exits with code 0' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 0 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install', 'zlib') | Should -BeTrue
            }
        }

        It 'returns $false when vcpkg exits with a non-zero code' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 1 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install', 'zlib') | Should -BeFalse
            }
        }

        It 'returns $false when Start-Process throws (launch failure)' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { throw 'cannot launch' }
                Invoke-Vcpkg -Command 'missing' -Arguments @('install') | Should -BeFalse
            }
        }

        It 'passes -PassThru and -Wait to Start-Process' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 0 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install') | Out-Null
                Should -Invoke Start-Process -Times 1 -ParameterFilter {
                    $PassThru -and $Wait
                }
            }
        }

        It 'forwards Environment to Start-Process when provided' {
            InModuleScope -ScriptBlock {
                Mock Start-Process { return [pscustomobject]@{ ExitCode = 0 } }
                Invoke-Vcpkg -Command 'vcpkg' -Arguments @('install') -Environment @{ FOO = 'bar' } | Out-Null
                Should -Invoke Start-Process -Times 1 -ParameterFilter {
                    $null -ne $Environment -and $Environment['FOO'] -eq 'bar'
                }
            }
        }
    }
}
