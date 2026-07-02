BeforeAll {
    . "$PSScriptRoot/../Shared/Bootstrap-NhcVcpkgTools.ps1"
    Enter-NhcVcpkgToolsTest
}

AfterAll {
    Exit-NhcVcpkgToolsTest
}

Describe 'Remove-NhcVcpkgPort' {
    BeforeAll {
        function New-TestVcpkgRoot {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper, not a user-facing cmdlet')]
            param()

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
        $script:capturedNoNewWindow = $null
        $script:triplet = 'x64-windows'
        $script:rootInfo = New-TestVcpkgRoot

        Mock Test-Executable -ModuleName $script:moduleName { return $true }
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
            $script:capturedArguments = $ArgumentList + @($NoNewWindow, $Wait, $WhatIf, $Confirm)
            return [pscustomobject]@{ ExitCode = 0 }
        }
    }

    Context 'Function discoverability' {
        It 'is discoverable via Get-Command' {
            $command = Get-Command Remove-NhcVcpkgPort -Module NhcVcpkgTools -ErrorAction SilentlyContinue
            $command | Should -Not -BeNullOrEmpty
            $command.Name | Should -Be 'Remove-NhcVcpkgPort'
        }
    }

    Context 'Parameter sets' {
        It 'accepts -Ports parameter and passes port names to vcpkg remove' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib', 'fmt' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Contain 'zlib'
            $script:capturedArguments | Should -Contain 'fmt'
        }

        It 'accepts -Outdated switch and passes --outdated flag to vcpkg' {
            $null = Remove-NhcVcpkgPort -Outdated -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Contain '--outdated'
        }

        It 'rejects -Ports and -Outdated used together' {
            { Remove-NhcVcpkgPort -Ports 'zlib' -Outdated -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command } |
            Should -Throw -ErrorId 'AmbiguousParameterSet*'
        }
    }

    Context 'Recurse switch' {
        It 'includes --recurse flag when -Recurse is specified' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib' -Recurse -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Contain '--recurse'
        }

        It 'does not include --recurse flag when -Recurse is not specified' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Not -Contain '--recurse'
        }
    }

    Context 'Common arguments' {
        It 'passes -RootDir as --vcpkg-root to vcpkg' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $expectedRoot = (Resolve-Path -Path $script:rootInfo.RootDir).ProviderPath
            $script:capturedArguments | Should -Contain "--vcpkg-root=`"$expectedRoot`""
        }

        It 'passes -Triplet as --triplet to vcpkg' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Contain "--triplet=`"$script:triplet`""
        }

        It 'passes -OverlayPorts paths as --overlay-ports to vcpkg' {
            $overlayPath = Join-Path $TestDrive 'overlay-ports'
            New-Item -Path $overlayPath -ItemType Directory | Out-Null

            $null = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -OverlayPorts $overlayPath

            $expectedPath = (Resolve-Path -Path $overlayPath).ProviderPath
            $script:capturedArguments | Should -Contain "--overlay-ports=`"$expectedPath`""
        }

        It 'passes -InstallDir as --x-install-root to vcpkg' {
            $installPath = Join-Path $TestDrive 'custom-installed'
            New-Item -Path $installPath -ItemType Directory | Out-Null

            $null = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -InstallDir $installPath

            $expectedPath = (Resolve-Path -Path $installPath).ProviderPath
            $script:capturedArguments | Should -Contain "--x-install-root=`"$expectedPath`""
        }
    }

    Context 'ShouldProcess support' {
        It 'declares SupportsShouldProcess in CmdletBinding' {
            $command = Get-Command Remove-NhcVcpkgPort -Module NhcVcpkgTools
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'includes --dry-run flag when -WhatIf is specified' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -WhatIf

            $script:capturedArguments | Should -Contain '--dry-run'
        }
    }

    Context 'Quiet switch' {
        It 'accepts -Quiet switch parameter' {
            $command = Get-Command Remove-NhcVcpkgPort -Module NhcVcpkgTools
            $quietParam = $command.Parameters['Quiet']

            $quietParam | Should -Not -BeNullOrEmpty
            $quietParam.SwitchParameter | Should -BeTrue
        }

        It 'binds and executes when -Quiet is specified' {
            { Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -Quiet } | Should -Not -Throw

            $script:capturedCommand | Should -Not -BeNullOrEmpty
        }

        It 'suppresses non-terminating Start-Process error records only when -Quiet is specified' {
            Mock Start-Process -ModuleName $script:moduleName {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$NoNewWindow,
                    [switch]$Wait,
                    [switch]$PassThru,
                    [switch]$WhatIf,
                    [switch]$Confirm
                )

                $null = $FilePath, $ArgumentList, $NoNewWindow, $Wait, $PassThru, $WhatIf, $Confirm
                Write-Error -Message 'simulated Start-Process error record' -ErrorAction Continue
                return [pscustomobject]@{ ExitCode = 1 }
            }

            InModuleScope -ModuleName $script:moduleName -Parameters @{ Command = $script:rootInfo.Command } -ScriptBlock {
                param($Command)

                $redirectAll = '2' + '>&1'
                $quietInvocation = [scriptblock]::Create(@"
param(`$Command)
& {
    Invoke-Vcpkg -Command `$Command -Arguments @('remove', 'zlib') -Quiet $redirectAll
}
"@)

                $loudInvocation = [scriptblock]::Create(@"
param(`$Command)
& {
    Invoke-Vcpkg -Command `$Command -Arguments @('remove', 'zlib') $redirectAll
}
"@)

                $quietOutput = @(& $quietInvocation $Command)
                $loudOutput = @(& $loudInvocation $Command)

                $quietErrors = @($quietOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
                $loudErrors = @($loudOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })

                $quietErrors | Should -BeNullOrEmpty
                $loudErrors | Should -Not -BeNullOrEmpty
                ($quietOutput | Where-Object { $_ -is [bool] }) | Should -BeFalse
                ($loudOutput | Where-Object { $_ -is [bool] }) | Should -BeFalse
            }
        }

        It 'passes Quiet through to Invoke-Vcpkg and returns failed status when vcpkg fails' {
            $script:capturedQuiet = $null

            Mock Invoke-Vcpkg -ModuleName $script:moduleName {
                param(
                    [string]$Command,
                    [object[]]$Arguments,
                    [switch]$Quiet
                )

                $script:capturedCommand = $Command
                $script:capturedArguments = $Arguments
                $script:capturedQuiet = $Quiet
                return $false
            }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -Quiet

            $result.Status | Should -BeFalse
            $script:capturedCommand | Should -Be $script:rootInfo.Command
            $script:capturedArguments | Should -Contain 'remove'
            $script:capturedQuiet | Should -BeTrue
            Should -Invoke Invoke-Vcpkg -ModuleName $script:moduleName -Times 1 -ParameterFilter {
                $Quiet
            }
        }
    }

    Context 'Force switch' {
        It 'accepts -Force switch parameter' {
            $command = Get-Command Remove-NhcVcpkgPort -Module NhcVcpkgTools
            $forceParam = $command.Parameters['Force']

            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.SwitchParameter | Should -BeTrue
        }

        It 'suppresses confirmation prompts when -Force is specified without explicit -Confirm' {
            $originalConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'Low'

            try {
                $null = Remove-NhcVcpkgPort -Ports 'zlib' -Force -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

                $script:capturedCommand | Should -Not -BeNullOrEmpty
                $script:capturedArguments | Should -Not -Contain '--dry-run'
            }
            finally {
                $ConfirmPreference = $originalConfirmPreference
            }
        }

        It 'preserves explicit -Confirm behavior when -Force is also specified' {
            $originalConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'Low'

            try {
                $null = Remove-NhcVcpkgPort -Ports 'zlib' -Force -Confirm:$false -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

                $script:capturedCommand | Should -Not -BeNullOrEmpty
                $ConfirmPreference | Should -Be 'Low'
            }
            finally {
                $ConfirmPreference = $originalConfirmPreference
            }
        }

        It 'performs dry-run when -Force and -WhatIf are both specified' {
            $null = Remove-NhcVcpkgPort -Ports 'zlib' -Force -WhatIf -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $script:capturedArguments | Should -Contain '--dry-run'
        }

        It "sets `$ConfirmPreference = 'None' only in local scope when -Force is specified" {
            $originalConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'Low'

            try {
                $null = Remove-NhcVcpkgPort -Ports 'zlib' -Force -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

                $ConfirmPreference | Should -Be 'Low'

                $command = Get-Command Remove-NhcVcpkgPort -Module NhcVcpkgTools
                $command.Definition | Should -Match 'if \(\$Force -and -not \$PSBoundParameters\.ContainsKey\(''Confirm''\)\)'
                $command.Definition | Should -Match '\$ConfirmPreference = ''None'''
            }
            finally {
                $ConfirmPreference = $originalConfirmPreference
            }
        }
    }

    Context 'Ports parameter validation' {
        It 'rejects empty Ports array' {
            { Remove-NhcVcpkgPort -Ports @() } |
            Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'rejects null Ports value' {
            { Remove-NhcVcpkgPort -Ports $null } |
            Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'accepts valid single port value' {
            { Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet } | Should -Not -Throw
            $script:capturedArguments | Should -Contain 'zlib'
        }
    }

    Context 'Return value structure' {
        It 'returns hashtable with Command as string path' {
            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result | Should -BeOfType [hashtable]
            $result.Command | Should -BeOfType [string]
            $result.Command | Should -Not -BeNullOrEmpty
        }

        It 'returns hashtable with Arguments as array' {
            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            , $result.Arguments | Should -BeOfType [array]
            $result.Arguments | Should -Contain 'zlib'
            $result.Arguments | Should -Contain '--classic'
        }

        It 'returns hashtable with RootDir as string path' {
            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.RootDir | Should -BeOfType [string]
            $result.RootDir | Should -Not -BeNullOrEmpty
        }

        It 'returns hashtable with InstallDir containing Path and Exists keys' {
            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.InstallDir | Should -BeOfType [hashtable]
            $result.InstallDir.ContainsKey('Path') | Should -BeTrue
            $result.InstallDir.ContainsKey('Exists') | Should -BeTrue
            $result.InstallDir.Path | Should -BeOfType [string]
            $result.InstallDir.Exists | Should -BeOfType [bool]
        }

        It 'returns Status as true on successful execution' {
            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeTrue
        }

        It 'returns Status as false when vcpkg fails' {
            Mock Start-Process {
                $global:LASTEXITCODE = 1
                throw "vcpkg failed"
            }


            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet -ErrorAction SilentlyContinue

            $result.Status | Should -BeFalse
        }
    }

    Context 'vcpkg exit status' {
        It 'returns Status false when vcpkg exits non-zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 1 } }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
        }

        It 'returns Status true when vcpkg exits zero' {
            Mock Start-Process -ModuleName $script:moduleName { return [pscustomobject]@{ ExitCode = 0 } }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeTrue
        }
    }

    Context 'vcpkg error scenarios' {
        It 'returns Status false when vcpkg fails to start' {
            Mock Start-Process -ModuleName $script:moduleName { throw 'cannot launch vcpkg' }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
        }

        It 'omits --recurse for dependency conflict failures when -Recurse is not specified' {
            Mock Start-Process -ModuleName $script:moduleName {
                param(
                    [string]$FilePath,
                    [object[]]$ArgumentList,
                    [switch]$NoNewWindow,
                    [switch]$Wait,
                    [switch]$PassThru,
                    [switch]$WhatIf,
                    [switch]$Confirm
                )

                $script:capturedCommand = $FilePath
                $script:capturedArguments = $ArgumentList + @($NoNewWindow, $Wait, $PassThru, $WhatIf, $Confirm)
                return [pscustomobject]@{ ExitCode = 1 }
            }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
            $script:capturedCommand | Should -Be $script:rootInfo.Command
            $script:capturedArguments | Should -Contain 'remove'
            $script:capturedArguments | Should -Contain 'zlib'
            $script:capturedArguments | Should -Contain '--classic'
            $script:capturedArguments | Should -Not -Contain '--recurse'
        }

        It 'inherits child console output through Start-Process without stderr capture' {
            Mock Start-Process -ModuleName $script:moduleName {
                param(
                    [object[]]$ArgumentList,
                    [switch]$NoNewWindow,
                    [switch]$Wait,
                    [switch]$PassThru,
                    [switch]$WhatIf,
                    [switch]$Confirm
                )

                $script:capturedArguments = $ArgumentList + @($NoNewWindow, $Wait, $PassThru, $WhatIf, $Confirm)
                $script:capturedNoNewWindow = $NoNewWindow
                return [pscustomobject]@{ ExitCode = 1 }
            }

            $result = Remove-NhcVcpkgPort -Ports 'zlib' -RootDir $script:rootInfo.RootDir -Command $script:rootInfo.Command -Triplet $script:triplet

            $result.Status | Should -BeFalse
            $script:capturedArguments | Should -Contain 'remove'
            $script:capturedNoNewWindow | Should -BeTrue
        }
    }
}
