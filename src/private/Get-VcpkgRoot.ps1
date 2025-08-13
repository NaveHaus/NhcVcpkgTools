Set-StrictMode -Version 3.0

function Get-VcpkgRoot {
    <#
    .SYNOPSIS
    Returns RootDir if passed and it contains a .vcpkg-root file, or $env:VCPKG_ROOT otherwise.

    .PARAMETER RootDir
    A string containing a directory to test.

    .OUTPUTS
    A string containing the path to a vcpkg root.
    #>

    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$RootDir
    )

    # Detect or set the root directory:
    $private:root = $PSBoundParameters.RootDir
    if ($null -eq $root) {
        $root = $env:VCPKG_ROOT
    }
    if ($null -eq $root) {
        throw "Could not determine the vcpkg root directory; set VCPKG_ROOT or pass RootDir as a parameter."
    }

    try {
        Join-Path -Path $root -ChildPath '.vcpkg-root' -Resolve -ErrorAction Stop | Out-Null
        $root = Resolve-Path -Path $root -Force -ErrorAction Stop
    }
    catch {
        throw "The directory '$root' does not exist or is not a vcpkg root directory."
    }

    return $root
}