Set-StrictMode -Version 3.0

function Test-AbsolutePath {
    <#
    .SYNOPSIS
    Returns $true if Path is absolute, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::IsPathRooted($Path)
}