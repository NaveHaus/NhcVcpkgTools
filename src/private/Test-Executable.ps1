Set-StrictMode -Version 3.0

. $PSScriptRoot\Test-FileNameString.ps1
. $PSScriptRoot\Test-PathString.ps1

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

        Write-Verbose "Testing '$name' in path '$dir'"

        $private:old = $env:PATH
        $env:PATH = $dir
        $private:exedir = $null
        try {
            $private:exe = (Get-Command -CommandType Application -Name $name -TotalCount 1).Source
            if ($null -ne $exe) {
                $exe = Resolve-Path -Path $exe -Force
                $private:exedir = [System.IO.Path]::GetDirectoryName($exe)
            }
        }
        finally {
            $env:PATH = $old
        }

        # Only match if the executable was found in the requested parent directory:
        if ($null -eq $exedir) {
            Write-Verbose "Executable '$name' not found"
            return $false
        }
        else {
            Write-Verbose "Found exeutable '$name' in '$exedir'"
            return $exedir -eq $dir
        }
    }
}