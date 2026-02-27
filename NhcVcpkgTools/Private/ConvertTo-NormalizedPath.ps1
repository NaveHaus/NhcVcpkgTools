Set-StrictMode -Version 3.0

. $PSScriptRoot\Join-RelativePath.ps1

function ConvertTo-NormalizedPath {
    <#
    .SYNOPSIS
    Removes '.', '..', and '\.' from Path, and if Path is relative, returns an absolute path based on the current working directory. This function works even if Path does not exist.

    .PARAMETER Path
    The absolute or relative path to normalize. An error is raised if Path contains non-path characters.

    .PARAMETER ChildPath
    An optional relative path to append to Path. An error is raised if ChildPath contains non-path characters, or if it is an absolute path.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ChildPath = '.'
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        $paths = @{ 'Path' = $Path; 'ChildPath' = $ChildPath }
        return $PSCmdLet.GetUnresolvedProviderPathFromPSPath((Join-RelativePath @paths))
    }
}