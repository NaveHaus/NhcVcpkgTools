BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Test-EmptyDirectory' {
    It 'returns true for an empty directory' {
        InModuleScope -ScriptBlock {
            $directory = Join-Path $TestDrive 'empty'
            New-Item -Path $directory -ItemType Directory | Out-Null

            Test-EmptyDirectory -Path $directory | Should -BeTrue
        }
    }

    It 'returns false for a directory containing a file' {
        InModuleScope -ScriptBlock {
            $directory = Join-Path $TestDrive 'with-file'
            New-Item -Path $directory -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $directory 'file.txt') -ItemType File | Out-Null

            Test-EmptyDirectory -Path $directory | Should -BeFalse
        }
    }

    It 'returns false for a directory containing a hidden file' {
        InModuleScope -ScriptBlock {
            $directory = Join-Path $TestDrive 'with-hidden-file'
            New-Item -Path $directory -ItemType Directory | Out-Null
            $hiddenFile = New-Item -Path (Join-Path $directory 'hidden.txt') -ItemType File
            $hiddenFile.Attributes = $hiddenFile.Attributes -bor [System.IO.FileAttributes]::Hidden

            Test-EmptyDirectory -Path $directory | Should -BeFalse
        }
    }

    It 'throws for a nonexistent path' {
        InModuleScope -ScriptBlock {
            $missingPath = Join-Path $TestDrive 'missing'

            { Test-EmptyDirectory -Path $missingPath } | Should -Throw
        }
    }
}