Set-StrictMode -Version 3.0

. $PSScriptRoot\Test-FileNameString.ps1
. $PSScriptRoot\Test-PathString.ps1
. $PSScriptRoot\Get-BinaryType.ps1

function Test-Executable {
    <#
    .SYNOPSIS
    Determine if a path to a file is an executable.

    .DESCRIPTION
    If Path is a file, this function determines if Path is an executable. Otherwise, it determines if Name exists as an executable under Path treated as a directory.

    .PARAMETER Path
    An absolute or relative path to an existing file or a directory. Name must be passed if Path is a directory.

    .PARAMETER Name
    If Path is a directory, this is the name of the executable to find.

    .NOTES
    - Get-Command is called with "-CommandType Application". Other types are not allowed or supported.
    - To find an executable by full path on Windows, Path must end in ".exe".
    #>

    [CmdletBinding(DefaultParameterSetName = "Path")]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name')]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Name')]
        [string]$Name
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        # Need the full path:
        $private:full = Resolve-Path -Path $Path -Force -ErrorAction Ignore

        # Doesn't exist:
        if ($null -eq $full) {
            return $false
        }

        # Temporarily add the parent directory to the path and see if Get-Command can find the
        # executable by name:
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            if (-not (Test-FileNameString -FileName $Name)) {
                return $false
            }
            if (-not (Test-Path -Path $full -PathType Container)) {
                return $false
            }
            $private:dir = $full
            $private:name = $Name
        }
        else {
            if (-not (Test-Path -Path $full -PathType Leaf)) {
                return $false
            }
            $private:dir = [System.IO.Path]::GetDirectoryName($full)
            $private:name = [System.IO.Path]::GetFileName($full)
        }
        Write-Host "Testing '$dir / $name'"
        $private:exe = Join-Path -Path $dir -ChildPath $name
        Write-Host "Got '$exe'"
        Write-Verbose "Testing '$exe'"

        $result = Get-BinaryType -Path $exe
        return ($result -ne 'NONE')
    }
}