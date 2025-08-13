Set-StrictMode -Version 3.0

function Test-FileNameString {
    <#
    .SYNOPSIS
    Returns $true if FileName contains only valid file name characters, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FileName
    )

    return $FileName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1
}
