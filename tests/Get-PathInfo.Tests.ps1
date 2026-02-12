Describe 'Get-PathInfo' {
    BeforeAll {
        . "$PSScriptRoot/../src/private/Join-RelativePath.ps1"
        . "$PSScriptRoot/../src/private/Get-PathInfo.ps1"
        $testFile = Join-Path $TestDrive 'testfile.txt'
        Set-Content -Path $testFile -Value 'hello'
    }

    Context 'Existing Path' {
        It 'returns FileInfo for an existing file with Exists = True' {
            $info = Get-PathInfo -Path $testFile
            $info | Should -BeOfType 'System.IO.FileInfo'
            $info.Exists | Should -BeTrue
            $info.Name | Should -Be 'testfile.txt'
        }
    }

    Context 'Nonexistent Path without Resolve' {
        It 'returns FileInfo with Exists = False for a nonexistent file' {
            $info = Get-PathInfo -Path "$TestDrive/nonexistent.txt"
            $info | Should -BeOfType 'System.IO.FileInfo'
            $info.Exists | Should -BeFalse
        }
    }

    Context 'Nonexistent Path with Resolve' {
        It 'throws error for nonexistent file when Resolve is set' {
            { Get-PathInfo -Path "$TestDrive/nope.txt" -Resolve } | Should -Throw
        }
    }
}