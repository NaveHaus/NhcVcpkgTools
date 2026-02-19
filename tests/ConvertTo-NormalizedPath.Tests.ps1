BeforeAll {
    . "$PSScriptRoot/../NhcVcpkgTools/private/ConvertTo-NormalizedPath.ps1"
}

Describe 'ConvertTo-NormalizedPath' {
    Context 'Basic Functionality' {
        It 'should normalize simple relative path to absolute' {
            $result = ConvertTo-NormalizedPath -Path '.'
            $expected = (Get-Location).ProviderPath
            $result | Should -Be $expected
        }

        It 'should correctly combine Path and ChildPath' {
            $parent = (Get-Location).ProviderPath
            $child = 'subfolder'
            $result = ConvertTo-NormalizedPath -Path $parent -ChildPath $child
            $expected = Join-Path -Path $parent -ChildPath $child
            # Note: The function normalizes, so the result and expected may differ in format, but result should end with child path
            $result | Should -BeLike "*$expected"
        }

        It 'should normalize paths with dot segments' {
            $path = Join-Path -Path (Get-Location).ProviderPath -ChildPath 'folder\.\subfolder\..'
            $result = ConvertTo-NormalizedPath -Path $path
            $expected = Join-Path -Path (Get-Location).ProviderPath -ChildPath 'folder'
            $result | Should -Be $expected
        }

        It 'should throw an error for invalid Path characters' {
            { ConvertTo-NormalizedPath -Path 'invalid:path:*?' } | Should -Throw
        }

        It 'should throw an error for absolute ChildPath' {
            $absChild = (Get-Location).ProviderPath
            { ConvertTo-NormalizedPath -Path '.' -ChildPath $absChild } | Should -Throw
        }
    }
}