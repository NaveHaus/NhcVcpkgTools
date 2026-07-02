Set-StrictMode -Version 3.0

function Get-NormalizedNamedDir {
    <#
    .SYNOPSIS
    Returns a normalized directory path from a named parameter or default relative path.

    .DESCRIPTION
    Get-NormalizedNamedDir reads a named directory value from a parameter hashtable. If the
    named parameter is absent, the supplied default path is used instead. Absolute paths are
    normalized directly, and relative paths are combined with ParentPath before normalization.

    .PARAMETER Parameters
    The hashtable that may contain the named directory value.

    .PARAMETER Name
    The key to read from Parameters.

    .PARAMETER ParentPath
    The parent path used when the selected directory path is relative.

    .PARAMETER DefaultPath
    The relative path used when Parameters does not contain Name.

    .EXAMPLE
    Get-NormalizedNamedDir -Parameters @{ DownloadDir = 'custom-downloads' } -Name 'DownloadDir' -ParentPath 'C:\vcpkg' -DefaultPath 'downloads'

    Returns the normalized path 'C:\vcpkg\custom-downloads'.

    .OUTPUTS
    System.String. The normalized directory path.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$ParentPath,
        [Parameter(Mandatory = $true, Position = 3)]
        [string]$DefaultPath
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        if ($Parameters.ContainsKey($Name)) {
            $private:dir = $Parameters.$Name
        }
        else {
            $private:dir = $DefaultPath
        }

        if (Test-AbsolutePath -Path $dir) {
            $paths = @{ 'Path' = $dir }
            $paths += @{ 'ChildPath' = '.' }
        }
        else {
            $paths = @{ 'Path' = $ParentPath }
            $paths += @{ 'ChildPath' = $dir }
        }

        # vcpkg doesn't like trailing '\' on Windows, so remove them:
        return ConvertTo-NormalizedPath(Join-RelativePath @paths)
    }
}
