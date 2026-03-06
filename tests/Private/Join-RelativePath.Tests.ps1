BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Join-RelativePath' {
    Context 'Joining valid paths' {
        It 'joins base and child path correctly' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base"
                New-Item -Path $baseDir -ItemType Directory | Out-Null
                $childName = "file.txt"
                $result = Join-RelativePath -Path $baseDir -ChildPath $childName
                $result | Should -Be (Join-Path $baseDir $childName)
            }
        }
    }

    Context 'Invalid input handling' {
        It 'throws error if ChildPath is absolute' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base2"
                New-Item -Path $baseDir -ItemType Directory | Out-Null
                $fullPath = Join-Path $baseDir 'file.txt'
                { Join-RelativePath -Path $baseDir -ChildPath $fullPath } | Should -Throw
            }
        }

        It 'throws error if Path is invalid' {
            InModuleScope -ScriptBlock {
                { Join-RelativePath -Path 'bad|path' -ChildPath 'file.txt' } | Should -Throw
            }
        }

        It 'throws error if ChildPath is invalid' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base3"
                New-Item -Path $baseDir -ItemType Directory | Out-Null
                { Join-RelativePath -Path $baseDir -ChildPath 'bad|name' } | Should -Throw
            }
        }
    }

    Context 'Resolve behavior' {
        It 'succeeds if combined path exists and Resolve is set' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base4"
                New-Item -Path $baseDir -ItemType Directory | Out-Null
                $childName = "file.txt"
                $fullPath = Join-Path $baseDir $childName
                Set-Content -Path $fullPath -Value "test"

                $result = Join-RelativePath -Path $baseDir -ChildPath $childName -Resolve
                $result | Should -Be $fullPath
            }
        }

        It 'throws error if combined path does not exist and Resolve is set' {
            InModuleScope -ScriptBlock {
                $baseDir = Join-Path $TestDrive "base5"
                New-Item -Path $baseDir -ItemType Directory | Out-Null
                { Join-RelativePath -Path $baseDir -ChildPath "notfound.txt" -Resolve } | Should -Throw
            }
        }
    }
}
