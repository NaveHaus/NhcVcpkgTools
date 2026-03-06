BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'ConvertTo-NormalizedPath' {
    Context 'Basic Functionality' {
        It 'should normalize simple relative path to absolute' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-NormalizedPath -Path '.'
                $expected = (Get-Location).ProviderPath
                $result | Should -Be $expected
            }
        }

        It 'should correctly combine Path and ChildPath' {
            InModuleScope -ScriptBlock {
                $parent = (Get-Location).ProviderPath
                $child = 'subfolder'
                $result = ConvertTo-NormalizedPath -Path $parent -ChildPath $child
                $expected = Join-Path -Path $parent -ChildPath $child
                # Note: The function normalizes, so the result and expected may differ in format, but result should end with child path
                $result | Should -BeLike "*$expected"
            }
        }

        It 'should normalize paths with dot segments' {
            InModuleScope -ScriptBlock {
                $path = Join-Path -Path (Get-Location).ProviderPath -ChildPath 'folder\.\subfolder\..'
                $result = ConvertTo-NormalizedPath -Path $path
                $expected = Join-Path -Path (Get-Location).ProviderPath -ChildPath 'folder'
                $result | Should -Be $expected
            }
        }

        It 'should throw an error for invalid Path characters' {
            InModuleScope -ScriptBlock {
                { ConvertTo-NormalizedPath -Path 'invalid:path:*?' } | Should -Throw
            }
        }

        It 'should throw an error for absolute ChildPath' {
            InModuleScope -ScriptBlock {
                $absChild = (Get-Location).ProviderPath
                { ConvertTo-NormalizedPath -Path '.' -ChildPath $absChild } | Should -Throw
            }
        }
    }
}
