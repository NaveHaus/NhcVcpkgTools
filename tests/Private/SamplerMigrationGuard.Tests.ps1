BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Sampler migration guards' {
    It 'unit tests do not dot-source module source scripts' {
        $repositoryRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')
        $unitTestFiles = Get-ChildItem -Path (Join-Path $repositoryRoot 'tests/Public'), (Join-Path $repositoryRoot 'tests/Private') -Filter '*.Tests.ps1' -File -Recurse
        $forbiddenPattern = '^\s*\.\s+.*NhcVcpkgTools[\\/](Public|Private)[\\/].*\.ps1'

        $violations = foreach ($testFile in $unitTestFiles) {
            $content = Get-Content -Path $testFile.FullName
            if ($content -match $forbiddenPattern) {
                $testFile.FullName
            }
        }

        $violations | Should -BeNullOrEmpty
    }

    It 'module function scripts do not use runtime sibling dot-sourcing' {
        $repositoryRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')
        $functionScriptFiles = Get-ChildItem -Path (Join-Path $repositoryRoot 'NhcVcpkgTools/Public'), (Join-Path $repositoryRoot 'NhcVcpkgTools/Private') -Filter '*.ps1' -File
        $forbiddenPattern = '^\s*\.\s+.*\.ps1\s*$'

        $violations = foreach ($file in $functionScriptFiles) {
            $content = Get-Content -Path $file.FullName
            if ($content -match $forbiddenPattern) {
                $file.FullName
            }
        }

        $violations | Should -BeNullOrEmpty
    }

    It 'module function scripts do not declare #Requires -Version' {
        $repositoryRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')
        $functionScriptFiles = Get-ChildItem -Path (Join-Path $repositoryRoot 'NhcVcpkgTools/Public'), (Join-Path $repositoryRoot 'NhcVcpkgTools/Private') -Filter '*.ps1' -File |
            Where-Object { $_.Name -ne '00ModuleHeader.ps1' }
        $forbiddenPattern = '(?im)^\s*#Requires\s+-Version\b'

        $violations = foreach ($file in $functionScriptFiles) {
            $content = Get-Content -Path $file.FullName -Raw
            if ($content -match $forbiddenPattern) {
                $file.FullName
            }
        }

        $violations | Should -BeNullOrEmpty
    }
}
