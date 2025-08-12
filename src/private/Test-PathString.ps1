Set-StrictMode -Version 3.0

function Test-PathString {
    <#
    .SYNOPSIS
    Returns $true if Path contains only valid path characters, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return $Path.IndexOfAny([System.IO.Path]::GetInvalidPathChars()) -eq -1
}