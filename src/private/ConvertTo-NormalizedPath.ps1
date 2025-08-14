Set-StrictMode -Version 3.0

. $PSScriptRoot\Join-RelativePath.ps1

function ConvertTo-NormalizedPath {
    <#
    .SYNOPSIS
    Removes '.', '..', and '\.' from Path, and if Path is relative, returns an absolute path based on the current working directory. This function works even if Path does not exist.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    begin {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }

    process {
        # [System.IO.Path]::GetFullPath((Join-Path))
        return $PSCmdLet.GetUnresolvedProviderPathFromPSPath((Join-RelativePath -Path $Path -ChildPath .))
    }
}