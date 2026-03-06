BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Get-TaggedOutputDir' {
    Context 'Basic Functionality' {
        It 'returns expected structure when OutputDir is provided' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base"
                New-Item -Path $baseDir -ItemType Directory | Out-Null

                $result = Get-TaggedOutputDir -OutputDir $baseDir
                $result | Should -BeOfType 'Hashtable'
                $result.BaseDir.Path | Should -Be $baseDir
                $result.BaseDir.Exists | Should -BeTrue
                $result.OutputDir.Path | Should -Be $baseDir
                $result.OutputDir.Exists | Should -BeTrue
                $result.Tag | Should -BeNullOrEmpty
            }
        }

        It 'creates tagged subdirectory when OutputDir and Tag provided' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base-tag"
                New-Item -Path $baseDir -ItemType Directory | Out-Null

                $tag = "mytag"
                $result = Get-TaggedOutputDir -OutputDir $baseDir -Tag $tag
                $expectedDir = Join-Path $baseDir $tag
                $result.OutputDir.Path | Should -Be $expectedDir
                $result.Tag | Should -Be $tag
            }
        }

        It 'throws error if Tag contains invalid characters' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base-invalid"
                New-Item -Path $baseDir -ItemType Directory | Out-Null

                { Get-TaggedOutputDir -OutputDir $baseDir -Tag 'bad/tag' } | Should -Throw
            }
        }

        It 'returns nulls if neither OutputDir nor Tag is provided' {
            InModuleScope -ScriptBlock {
                $result = Get-TaggedOutputDir
                $result.BaseDir | Should -BeNull
                $result.OutputDir | Should -BeNull
                $result.Tag | Should -BeNull
            }
        }
    }

    Context 'Current Directory Handling' {
        It 'throws error if OutputDir resolves to current directory and AllowCwd is not set' {
            InModuleScope -ScriptBlock {
                { Get-TaggedOutputDir -OutputDir (Get-Location) } | Should -Throw
            }
        }
        It 'allows current directory if AllowCwd is set' {
            InModuleScope -ScriptBlock {
                $result = Get-TaggedOutputDir -OutputDir (Get-Location) -AllowCwd
                $result.OutputDir.Path | Should -Be (Get-Location).Path
            }
        }
    }
}