Describe 'Join-RelativePath' {
    BeforeAll {
        . "$PSScriptRoot/../src/private/Test-AbsolutePath.ps1"
        . "$PSScriptRoot/../src/private/Test-PathString.ps1"
        . "$PSScriptRoot/../src/private/Test-FileNameString.ps1"
        . "$PSScriptRoot/../src/private/Join-RelativePath.ps1"
        $baseDir = Join-Path $TestDrive "base"
        New-Item -Path $baseDir -ItemType Directory | Out-Null
        $childName = "file.txt"
        $fullPath = Join-Path $baseDir $childName
        Set-Content -Path $fullPath -Value "test"
    }

    Context 'Joining valid paths' {
        It 'joins base and child path correctly' {
            $result = Join-RelativePath -Path $baseDir -ChildPath $childName
            $result | Should -Be (Join-Path $baseDir $childName)
        }
    }

    Context 'Invalid input handling' {
        It 'throws error if ChildPath is absolute' {
            { Join-RelativePath -Path $baseDir -ChildPath $fullPath } | Should -Throw
        }

        It 'throws error if Path is invalid' {
            { Join-RelativePath -Path 'bad|path' -ChildPath $childName } | Should -Throw
        }

        It 'throws error if ChildPath is invalid' {
            { Join-RelativePath -Path $baseDir -ChildPath 'bad|name' } | Should -Throw
        }
    }

    Context 'Resolve behavior' {
        It 'succeeds if combined path exists and Resolve is set' {
            $result = Join-RelativePath -Path $baseDir -ChildPath $childName -Resolve
            $result | Should -Be (Join-Path $baseDir $childName)
        }

        It 'throws error if combined path does not exist and Resolve is set' {
            { Join-RelativePath -Path $baseDir -ChildPath "notfound.txt" -Resolve } | Should -Throw
        }
    }
}