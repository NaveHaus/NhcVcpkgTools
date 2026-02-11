Set-StrictMode -Version 3.0

function Test-EmptyDirectory {
    <#
    .SYNOPSIS
    Returns $true if Path is empty (including hidden files), $false otherwise.

    .DESCRIPTION
    If $Path is a directory, this function returns $true if it is empty, $false othewise. $Path must be an existing directory or an error is raised.
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    return !(Get-ChildItem -LiteralPath $Path -ErrorAction Stop | Select-Object -First 1)
}
