Describe 'Get-Executable' {
    BeforeAll {
    . "$PSScriptRoot/../NhcVcpkgTools/private/Test-FileNameString.ps1"
    . "$PSScriptRoot/../NhcVcpkgTools/private/Test-PathString.ps1"
    . "$PSScriptRoot/../NhcVcpkgTools/private/Get-Executable.ps1"
    }

    Context 'Basic Functionality' {
        It 'returns full path for a known executable in system PATH' {
            $exe = Get-Executable -Name 'powershell'
            $exe | Should -BeOfType 'System.String'
            $exe | Should -Match 'powershell'
            Test-Path $exe | Should -BeTrue
        }

        It 'throws error for invalid Name input' {
            { Get-Executable -Name '<<<invalid!name>>>' } | Should -Throw
        }
    }
}