Set-StrictMode -Version 3.0

function Test-FileNameString {
    <#
    .SYNOPSIS
    Returns $true if Path contains only valid file name characters, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return $Path.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1
}
