Set-StrictMode -Version 3.0

function Find-NhcVcpkgCommand {
    <#
    .SYNOPSIS
    Locate the vcpkg executable on the path or at a specified location.

    .PARAMETER Vcpkg
    Specifies the path to the vcpkg executable.

    .EXAMPLE
    Find-NhcVcpkgCommand

    Find vcpkg using $env:PATH.

    .EXAMPLE
    Find-NhcVcpkgCommand -Vcpkg '/vcpkg-root/vcpkg'

    If /vcpkg-root/vcpkg exists and is an executable, return it.

    .OUTPUTS
    A string containing the path to the vcpkg command.

    .NOTES
    No attempt is made to verify that the command is actually a vcpkg driver.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Vcpkg
    )

    if ($PSBoundParameters.ContainsKey("Vcpkg")) {
        $exe = (Get-Command -CommandType Application -Name $Vcpkg -ErrorAction Ignore).Source
        if ($null -eq $exe) {
            throw "The specified vcpkg command '$Vcpkg' does not exist or is not executable."
        }
    }
    else {
        $exe = (Get-Command -CommandType Application -Name vcpkg -ErrorAction Ignore).Source
        if ($null -eq $exe) {
            throw "Cannot find the vcpkg command on the path."
        }
    }

    return $exe
}