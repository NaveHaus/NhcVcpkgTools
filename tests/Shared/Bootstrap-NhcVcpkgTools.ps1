Set-StrictMode -Version 3.0

function Invoke-BootstrapBuild {
    # Redirect all streams to $null, except the error stream (stream 2)
    & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    if (-not $?) {
        throw 'Failed to build NhcVcpkgTools with build.ps1 -Tasks noop.'
    }
}

function Set-ModuleUnderTest {
    [CmdletBinding()]
    param(
        [string]$Name
    )

    'InModuleScope:ModuleName', 'Mock:ModuleName', 'Should:ModuleName' |
    ForEach-Object {
        $PSDefaultParameterValues[$_] = $Name
    }
}

function Remove-ModuleUnderTest {
    [CmdletBinding()]
    param(
        [string]$Name
    )

    'InModuleScope:ModuleName', 'Mock:ModuleName', 'Should:ModuleName' |
    ForEach-Object {
        $mut = $PSDefaultParameterValues[$_]
        if ($Name -ne $mut) {
            throw "Expected '$_ = $Name', got '$mut'"
        }
        $PSDefaultParameterValues.Remove($_)
    }
}

function Enter-NhcVcpkgToolsTest {
    $script:moduleName = 'NhcVcpkgTools'

    if (Get-Module -Name $script:moduleName) {
        $script:g_moduleWasPreLoaded = $true
    }

    # If the module is not found, run the build task 'noop'.
    else {
        if (-not (Get-Module -Name $script:moduleName -ListAvailable)) {
            Invoke-BootstrapBuild
            $script:g_moduleWasPreLoaded = $false
        }

        # Re-import the module using force to get any code changes between runs.
        Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
    }

    # Setup module-specific testing:
    Set-ModuleUnderTest -Name $script:moduleName

    return Get-Module -Name $script:moduleName
}

function Exit-NhcVcpkgToolsTest {
    Remove-ModuleUnderTest -Name $script:moduleName
    if (-not $script:g_moduleWasPreLoaded) {
        Remove-Module -Name $script:moduleName -ErrorAction SilentlyContinue
    }
}