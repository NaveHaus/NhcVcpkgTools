Set-StrictMode -Version 3.0

function Invoke-Vcpkg {
    <#
    .SYNOPSIS
    Runs the vcpkg executable and reports whether it exited successfully.

    .DESCRIPTION
    Wraps Start-Process so the real child exit code is captured via -PassThru.
    Returns $true only when vcpkg exits with code 0; returns $false on a
    non-zero exit code or if the process fails to launch. ErrorAction 'Stop'
    on Start-Process ensures a launch failure surfaces as a terminating error
    caught here, independent of the caller's $ErrorActionPreference.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [hashtable]$Environment,

        [switch]$Quiet
    )

    $private:splat = @{
        FilePath     = $Command
        ArgumentList = $Arguments
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        WhatIf       = $false
        Confirm      = $false
        ErrorAction  = 'Stop'
    }
    if ($null -ne $Environment) {
        $splat['Environment'] = $Environment
    }

    try {
        if ($Quiet) {
            $private:proc = Start-Process @splat 2>$null
        }
        else {
            $private:proc = Start-Process @splat
        }
        return ($null -ne $proc) -and (0 -eq $proc.ExitCode)
    }
    catch {
        # vcpkg failed to launch - report failure without rethrowing.
        return $false
    }
}
