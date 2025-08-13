Set-StrictMode -Version 3.0

function Test-VcpkgRoot {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    $private:dir = Resolve-Path -Path $Path -Force -ErrorAction Ignore
    if($null -eq $dir) {
        return $false
    }

    try {
        Join-Path -Path $dir -ChildPath '.vcpkg-root' -Resolve -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}