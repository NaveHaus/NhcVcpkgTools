Set-StrictMode -Version 3.0

. $PSScriptRoot\Join-RelativePath.ps1

function Test-VcpkgRoot {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    $private:dir = Join-RelativePath -Path $Path -ChildPath . -Resolve -ErrorAction Ignore
    if ($null -eq $dir) {
        return $false
    }

    try {
        Join-RelativePath -Path $dir -ChildPath '.vcpkg-root' -Resolve -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}