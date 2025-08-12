Set-StrictMode -Version 3.0

function Get-NhcVcpkgDefaultTriplet {
    <#
    .SYNOPSIS
    Returns returns the first defined of $Triplet, $env:VCPKG_DEFAULT_TRIPLET, or a detected triplet.

    .PARAMETER Triplet
    Specifies the target triplet (e.g., x64-windows).

    .OUTPUTS
    A string containing the detected vcpkg triplet.

    .NOTES
    - Only Windows, Linux, and Darwin are currently recognized as the OS.
    - Only x32, x64, and arm architectures are currently recognized.
    #>

    param (
        [Parameter(Mandatory = $false)]
        [string]$Triplet
    )

    $private:detected = $null
    if ($PSBoundParameters.ContainsKey("Triplet")) {
        $detected = $PSBoundParameters.Triplet
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
                    throw "Unrecognized OS '$os'."
                }
            }
        }
    }

    return $detected
}