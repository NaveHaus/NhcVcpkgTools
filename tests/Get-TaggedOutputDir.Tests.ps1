Describe 'Get-TaggedOutputDir' {
    BeforeAll {
        . "$PSScriptRoot/../src/private/ConvertTo-NormalizedPath.ps1"
        . "$PSScriptRoot/../src/private/Get-PathInfo.ps1"
        . "$PSScriptRoot/../src/private/Join-RelativePath.ps1"
        . "$PSScriptRoot/../src/private/Test-PathString.ps1"
        . "$PSScriptRoot/../src/private/Test-FileNameString.ps1"
        . "$PSScriptRoot/../src/private/Get-TaggedOutputDir.ps1"
        $baseDir = Join-Path $TestDrive "base"
        New-Item -Path $baseDir -ItemType Directory | Out-Null
    }

    Context 'Basic Functionality' {
        It 'returns expected structure when OutputDir is provided' {
            $result = Get-TaggedOutputDir -OutputDir $baseDir
            $result | Should -BeOfType 'Hashtable'
            $result.BaseDir.Path | Should -Be $baseDir
            $result.BaseDir.Exists | Should -BeTrue
            $result.OutputDir.Path | Should -Be $baseDir
            $result.OutputDir.Exists | Should -BeTrue
            $result.Tag | Should -BeNullOrEmpty
        }

        It 'creates tagged subdirectory when OutputDir and Tag provided' {
            $tag = "mytag"
            $result = Get-TaggedOutputDir -OutputDir $baseDir -Tag $tag
            $expectedDir = Join-Path $baseDir $tag
            $result.OutputDir.Path | Should -Be $expectedDir
            $result.Tag | Should -Be $tag
        }

        It 'throws error if Tag contains invalid characters' {
            { Get-TaggedOutputDir -OutputDir $baseDir -Tag 'bad/tag' } | Should -Throw
        }

        It 'throws error if neither OutputDir nor Tag is provided' {
            $result = Get-TaggedOutputDir
            $result.BaseDir | Should -BeNull
            $result.OutputDir | Should -BeNull
            $result.Tag | Should -BeNull
        }
    }

    Context 'Current Directory Handling' {
        It 'throws error if OutputDir resolves to current directory and AllowCwd is not set' {
            { Get-TaggedOutputDir -OutputDir (Get-Location) } | Should -Throw
        }
        It 'allows current directory if AllowCwd is set' {
            $result = Get-TaggedOutputDir -OutputDir (Get-Location) -AllowCwd
            $result.OutputDir.Path | Should -Be (Get-Location).Path
        }
    }
}