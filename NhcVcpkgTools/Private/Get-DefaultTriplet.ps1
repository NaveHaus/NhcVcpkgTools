Set-StrictMode -Version 3.0

function Get-DefaultTriplet {
    <#
    .SYNOPSIS
    Returns returns the first defined of $Triplet, $env:VCPKG_DEFAULT_TRIPLET, or a detected triplet.

    .PARAMETER Triplet
    Specifies the target triplet (e.g., x64-windows).

    .PARAMETER Parameters
    Specifies a hashtable of name-value pairs in which to lookup the Triplet parameter.

    .OUTPUTS
    A string containing the detected vcpkg triplet.

    .NOTES
    - Only Windows, Linux, and Darwin are currently recognized as the OS.
    - Only x32, x64, and arm architectures are currently recognized.
    #>

    [CmdletBinding(DefaultParameterSetName = "Triplet")]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "Triplet")]
        [string]$Triplet,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Parameters")]
        [hashtable]$Parameters
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        $private:detected = $null
        if ($PSCmdlet.ParameterSetName -eq "Parameters") {
            if ($Parameters.ContainsKey("Triplet")) {
                $detected = $Parameters.Triplet
            }
        }

        else {
            if ($PSBoundParameters.ContainsKey("Triplet")) {
                $detected = $Triplet
            }
        }

        if ([string]::IsNullOrWhiteSpace($detected)) {
            $private:detected = $env:VCPKG_DEFAULT_TRIPLET;
            if ([string]::IsNullOrWhiteSpace($detected)) {
                $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
                $os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription

                switch -Regex ($os) {
                    "windows" { $detected = "$arch-windows" }
                    "linux" { $detected = "$arch-linux" }
                    "darwin|macos" { $detected = "$arch-osx" }
                    default {
                        Write-Error "Unrecognized OS '$os'."
                    }
                }
            }
        }

        return $detected
    }
}