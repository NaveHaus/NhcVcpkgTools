BeforeAll {
    . "$PSScriptRoot/Bootstrap-NhcVcpkgTools.ps1"
}

Describe 'Bootstrap-NhcVcpkgTools helper functions' -Tags 'bootstrap' {
    It 'is a no-op when module is already imported' {
        Mock Get-Module {
            [pscustomobject]@{ Name = 'NhcVcpkgTools' }
        } -ParameterFilter { $Name -eq 'NhcVcpkgTools' -and -not $ListAvailable }

        Mock Get-Module {
            [pscustomobject]@{ Name = 'NhcVcpkgTools' }
        } -ParameterFilter { $Name -eq 'NhcVcpkgTools' -and $ListAvailable }

        Mock Invoke-BootstrapBuild { throw 'Should not build' }
        Mock Import-Module {}
        Mock Set-ModuleUnderTest {}
        Mock Remove-ModuleUnderTest { throw 'Should not clean up' }

        $result = Enter-NhcVcpkgToolsTest
        $result.Name | Should -Be 'NhcVcpkgTools'

        Should -Invoke Get-Module -Times 1 -ParameterFilter { $Name -eq 'NhcVcpkgTools' -and $ListAvailable }
        Should -Invoke Import-Module -Times 1
        Should -Invoke Set-ModuleUnderTest -Times 1
    }

    It 'triggers noop build and imports module when not importable' {
        Mock Get-Module {
            return $null
        } -ParameterFilter { $Name -eq 'NhcVcpkgTools' -and -not $ListAvailable }

        Mock Get-Module {
            return $null
        } -ParameterFilter { $Name -eq 'NhcVcpkgTools' -and $ListAvailable }

        Mock Invoke-BootstrapBuild {}
        Mock Import-Module {}
        Mock Set-ModuleUnderTest {}
        Mock Remove-ModuleUnderTest { throw 'Should not clean up' }

        Enter-NhcVcpkgToolsTest -SkipImport | Out-Null

        Should -Invoke Import-Module -Times 1 -ParameterFilter { $Name -eq 'NhcVcpkgTools' }
        Should -Invoke Invoke-BootstrapBuild -Times 1
    }

    It 'applies module-scoped defaults for Mock, Should, and InModuleScope' {
        Mock Invoke-BootstrapBuild {}
        Mock Import-Module {}

        Enter-NhcVcpkgToolsTest | Out-Null

        Get-Module -Name 'NhcVcpkgTools' | Should -Be $null
        'InModuleScope:ModuleName', 'Mock:ModuleName', 'Should:ModuleName' |
        ForEach-Object {
            $PSDefaultParameterValues[$_] | Should -Be 'NhcVcpkgTools'
        }
    }

    It 'removes module-scoped defaults for Mock, Should, and InModuleScope' {
        Exit-NhcVcpkgToolsTest

        'InModuleScope:ModuleName', 'Mock:ModuleName', 'Should:ModuleName' |
        ForEach-Object {
            $PSDefaultParameterValues[$_] | Should -Be $null
        }
    }
}
