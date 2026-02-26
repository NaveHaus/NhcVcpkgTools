Describe 'Install-NhcVcpkgPorts' {
    BeforeAll {
        . "$PSScriptRoot/../NhcVcpkgTools/public/Install-NhcVcpkgPorts.ps1"

        function New-TestVcpkgRoot {
            $rootDir = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString())
            New-Item -Path $rootDir -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $rootDir '.vcpkg-root') -ItemType File | Out-Null
            $command = Join-Path $rootDir 'vcpkg.exe'
            New-Item -Path $command -ItemType File | Out-Null

            return @{ RootDir = $rootDir; Command = $command }
        }
    }

    BeforeEach {
        $script:capturedArguments = $null
        $script:capturedCommand = $null
        $script:triplet = 'x64-windows'
        $script:rootInfo = New-TestVcpkgRoot

        Mock Test-Executable { return $true }
        Mock Start-Process {
            param(
                [string]$FilePath,
                [object[]]$ArgumentList,
                [switch]$NoNewWindow,
                [switch]$Wait,
                [switch]$WhatIf,
                [switch]$Confirm
            )

            $script:capturedCommand = $FilePath
            $script:capturedArguments = $ArgumentList
            return $null
        }
    }

    Context 'Classic ports install' {
        It 'builds classic arguments with root and triplet' {
            $null = Install-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $expectedRoot = ConvertTo-NormalizedPath -Path $script:rootInfo.RootDir
            $script:capturedArguments | Should -Contain 'install'
            $script:capturedArguments | Should -Contain 'zlib'
            $script:capturedArguments | Should -Contain '--classic'
            $script:capturedArguments | Should -Contain "--vcpkg-root=`"$expectedRoot`""
            $script:capturedArguments | Should -Contain "--triplet=`"$script:triplet`""
            $script:capturedArguments | Should -Contain "--host-triplet=`"$script:triplet`""
        }
    }

    Context 'Manifest install arguments' {
        It 'adds manifest feature flags for -All' {
            $null = Install-NhcVcpkgPorts -All -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Contain '--feature-flags="manifest,versions"'
            $script:capturedArguments | Should -Not -Contain '--classic'
        }
    }

    Context 'Output directory shaping' {
        It 'derives parent and output paths from OutputDir and Tag' {
            $outputDir = Join-Path $TestDrive 'output'
            New-Item -Path $outputDir -ItemType Directory | Out-Null

            $result = Install-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -OutputDir $outputDir -Tag 'release' |
                Where-Object { $_ -is [hashtable] } |
                Select-Object -Last 1

            $expectedBase = ConvertTo-NormalizedPath -Path $outputDir
            $expectedParent = ConvertTo-NormalizedPath -Path (Join-Path $outputDir 'release')

            $result.BaseDir.Path | Should -Be $expectedBase
            $result.Tag | Should -Be 'release'
            $result.ParentDir.Path | Should -Be $expectedParent
            $result.DownloadDir.Path | Should -Be (ConvertTo-NormalizedPath -Path (Join-Path $expectedParent 'downloads'))
            $result.BuildDir.Path | Should -Be (ConvertTo-NormalizedPath -Path (Join-Path $expectedParent 'buildtrees'))
            $result.PackageDir.Path | Should -Be (ConvertTo-NormalizedPath -Path (Join-Path $expectedParent 'packages'))
            $result.InstallDir.Path | Should -Be (ConvertTo-NormalizedPath -Path (Join-Path $expectedParent 'installed'))
        }
    }

    Context 'Option flags' {
        It 'includes binary source and toggle flags' {
            $binarySources = @('files,c:/cache,readwrite', 'clear;files,d:/vcpkg,read')

            $null = Install-NhcVcpkgPorts -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -BinarySources $binarySources -CachedOnly -Editable -ExactVersions

            $script:capturedArguments | Should -Contain "--binarysource=`"$($binarySources[0])`""
            $script:capturedArguments | Should -Contain "--binarysource=`"$($binarySources[1])`""
            $script:capturedArguments | Should -Contain '--only-binarycaching'
            $script:capturedArguments | Should -Contain '--editable'
            $script:capturedArguments | Should -Contain '--x-abi-tools-use-exact-versions'
        }
    }
}
