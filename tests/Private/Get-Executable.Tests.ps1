BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-Executable' {
    Context 'Basic Functionality' {
        It 'returns full path for a known executable in system PATH' {
            InModuleScope -ScriptBlock {
                $exe = Get-Executable -Name 'powershell'
                $exe | Should -BeOfType 'System.String'
                $exe | Should -Match 'powershell'
                Test-Path $exe | Should -BeTrue
            }
        }

        It 'throws error for invalid Name input' {
            InModuleScope -ScriptBlock {
                { Get-Executable -Name '<<<invalid!name>>>' } | Should -Throw
            }
        }
    }
}
