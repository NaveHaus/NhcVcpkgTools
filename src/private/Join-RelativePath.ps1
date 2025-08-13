Set-StrictMode -Version 3.0

function Join-RelativePath {
    <#
    .SYNOPSIS
    Create a new path path by combining Path with a relative path in ChildPath.

    .PARAMETER Path
    The absolute or relative root to append ChildPath to. An error is raised if Path contains non-path characters.

    .PARAMETER ChildPath
    The path to append to Path. An error is raised if ChildPath contains non-path characters, or if it is an absolute path.

    .PARAMETER Resolve
    If passed, the combined path must exist or an error is raised.
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ChildPath,

        [switch]$Resolve
    )

    if (-not (Test-PathString -Path $Path)) {
        throw "Base path '$Path' is invalid."
    }

    if (-not (Test-PathString -Path $ChildPath)) {
        throw "Child path '$ChildPath' is invalid."
    }

    if (Test-AbsolutePath -Path $ChildPath) {
        throw "Cannot make absolute path '$ChildPath' relative to '$Path'."
    }

    return Join-Path -Path $Path -ChildPath $ChildPath -Resolve:$Resolve
}