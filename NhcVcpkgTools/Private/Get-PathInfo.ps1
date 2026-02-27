Set-StrictMode -Version 3.0

. $PSScriptRoot\Join-RelativePath.ps1

function Get-PathInfo {
    <#
    .SYNOPSIS
    Returns DirectoryInfo or FileInfo for the specified path.

    .PARAMETER Path
    The path to query.

    .PARAMETER Resolve
    Raise an error if the path does not exist.

    .OUTPUTS
    System.IO.FileSystemInfo

    .NOTES
    If Path does not exist, then the Exists member of the returned object will be false.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        [switch]$Resolve
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        $private:item = Join-RelativePath -Path $Path -ChildPath .
        $private:info = Get-Item -Path $item -ErrorAction Ignore
        if ($null -ne $info) {
            return $info
        }
        elseif (-not $Resolve) {
            return [System.IO.FileInfo]::new($Path)
        }
        else {
            Write-Error "Cannot find path '$Path' because it does not exist."
        }
    }
}