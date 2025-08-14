Set-StrictMode -Version 3.0

. $PSScriptRoot\Test-FileNameString.ps1
. $PSScriptRoot\Test-PathString.ps1

function Get-Executable {
    <#
    .SYNOPSIS
    Get the full path to an executable by name.

    .DESCRIPTION
    This function calls Get-Command to search for Name as an executable. If Path is passed and is an existing directory, then Name is searched for only under that directory. Only the first matching full path is returned.

    .PARAMETER Path
    Optional absolute or relative path to an existing directory. An error is raised if Path does not resolve to an existing directory.

    .PARAMETER Name
    The executable name to find in $env:PATH, or in Path if it is the path to an existing directory.

    .OUTPUTS
    A string containing the full path to the found executable.

    .NOTES
    - Get-Command is called with "-CommandType Application". Other types are not allowed or supported.
    #>

    [CmdletBinding(DefaultParameterSetName = "Name")]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Path")]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Name")]
        [string]$Name
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        if (-not (Test-FileNameString -FileName $Name)) {
            Write-Error "'$Name' is not a valid filename."
        }

        $private:old = $env:PATH
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-PathString -Path $Path)) {
                Write-Error "'$Path' is not a valid path."
            }

            if (-not (Test-Path -Path $Path -PathType Container)) {
                Write-Error "'$Path' does not exist, is inaccessbile, or is not a directory."
            }

            $private:full = Resolve-Path -Path $Path -Force
            $env:PATH = $full
        }

        try {
            $private:exe = (Get-Command -CommandType Application -Name $Name -TotalCount 1).Source
        }
        finally {
            $env:PATH = $old
        }

        return $exe
    }
}
