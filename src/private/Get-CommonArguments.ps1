Set-StrictMode -Version 3.0

function Get-NhcVcpkgCommonParameters {
    <#
    .SYNOPSIS
    Create an array of command vcpkg command line arguments.

    .DESCRIPTION
    This function converts recognized name-value pairs into vcpkg command line arguments and returns the result as an array.

    Currently recognized arguments:
    - Triplet (--triplet)
    - DownloadDir (--downloads-root). Defaults to './downloads'
    - BuildDir (--x-buildtrees-root). Defaults to './buildtrees'
    - PackageDir (--x-packages-root). Defaults to './packages'
    - InstallDir (--x-install-root). Defaults to './installed'
    - ManifestDir (--x-manifest-root)
    - OverlayPorts (--overlay-ports)

    .PARAMETER Parameters
    A hashtable of name-value pairs to extract common arguments from.

    .PARAMETER OutputDir
    DownloadDir, BuildDir, PackageDir, and InstallDir will be made relative to OutputDir if passed. The paths must be relative, otherwise an error is raised.

    .OUTPUTS
    An array of recognized vcpkg command line arguments.

    .LINK
    https://learn.microsoft.com/en-us/vcpkg/commands/common-options
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $false)]
        [string]$OutputDir
    )

    $private:params = @()

    $private:splat = @{}
    if ($Parameters.ContainsKey("Triplet")) {
        $splat = @{ Triplet = $Parameters.Triplet }
    }

    $private:triplet = Get-NhcVcpkgDefaultTriplet @splat
    $params += "--triplet=$triplet"
    Write-Verbose "Using target triplet '$triplet'"

    $private:outdir = $PSBoundParameters.OutputDir;

    if ($Parameters.ContainsKey("DownloadDir")) {
        $DownloadDir = $Parameters.DownloadDir
    }
    else {
        $DownloadDir = './downloads'
    }
    if ($null -ne $outdir) {
        $DownloadDir = Join-RelativePath -Path $outdir -ChildPath $DownloadDir
    }
    $params += "--downloads-root=$DownloadDir"

    if ($Parameters.ContainsKey("BuildDir")) {
        $BuildDir = $Parameters.BuildDir
    }
    else {
        $BuildDir = './buildtrees'

    }
    if ($null -ne $outdir) {
        $BuildDir = Join-RelativePath -Path $outdir -ChildPath $BuildDir
    }
    $params += "--x-buildtrees-root=$BuildDir"

    if ($Parameters.ContainsKey("PackageDir")) {
        $PackageDir = $Parameters.PackageDir
        if ($null -ne $outdir) {
            $PackageDir = Join-RelativePath -Path $outdir -ChildPath $PackageDir
        }
        $params += "--x-packages-root=$PackageDir"
    }

    if ($Parameters.ContainsKey("InstallDir")) {
        $InstallDir = $Parameters.InstallDir
    }
    else {
        $InstallDir = './installed'
    }
    if ($null -ne $outdir) {
        $InstallDir = Join-RelativePath -Path $outdir -ChildPath $InstallDir
    }
    $params += "--x-install-root=$InstallDir"

    if ($Parameters.ContainsKey("ManifestDir")) {
        $ManifestDir = $Parameters.ManifestDir
        $manifest = Join-Path -Path $ManifestDir -ChildPath 'vcpkg.json' -Resolve -ErrorAction Ignore
        if ($null = $manifest) {
            throw "The specified manifest directory '$ManifestDir' does not exist, is not a directory, or does not contain vcpkg.json."
        }
        $params += "--x-manifest-root=$ManifestDir"
    }

    if ($Parameters.ContainsKey("OverlayPorts")) {
        $Parameters.OverlayPorts | ForEach-Object {
            $path = Resolve-Path -Path $_ -Force -ErrorAction Ignore
            if ($null -eq $path) {
                throw "The overlay port directory '$_' does not exist or is not a directory."
            }
            $params += "--overlay-ports=$path"
        }
    }

    return $params
}