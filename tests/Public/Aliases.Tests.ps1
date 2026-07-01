BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Public cmdlet naming' {
    It 'exports the singular function <Name>' -ForEach @(
        @{ Name = 'Export-NhcVcpkgPort' }
        @{ Name = 'Install-NhcVcpkgPort' }
        @{ Name = 'Remove-NhcVcpkgPort' }
    ) {
        $command = Get-Command -Module $script:moduleName -Name $Name -CommandType Function -ErrorAction SilentlyContinue
        $command | Should -Not -BeNullOrEmpty -Because 'the module must export the singular-noun cmdlet'
    }

    It 'exposes the legacy plural alias <Alias> -> <Target>' -ForEach @(
        @{ Alias = 'Export-NhcVcpkgPorts'; Target = 'Export-NhcVcpkgPort' }
        @{ Alias = 'Install-NhcVcpkgPorts'; Target = 'Install-NhcVcpkgPort' }
        @{ Alias = 'Remove-NhcVcpkgPorts'; Target = 'Remove-NhcVcpkgPort' }
    ) {
        $resolved = Get-Command -Module $script:moduleName -Name $Alias -CommandType Alias -ErrorAction SilentlyContinue
        $resolved | Should -Not -BeNullOrEmpty -Because 'the old plural name must remain usable as an alias'
        $resolved.ResolvedCommand.Name | Should -Be $Target
    }
}
