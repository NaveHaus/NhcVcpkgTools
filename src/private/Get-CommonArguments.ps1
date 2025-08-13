Set-StrictMode -Version 3.0

function Get-CommonArguments {
    <#
    .SYNOPSIS
    Generate an array of common vcpkg command line arguments.

    .DESCRIPTION
    This function generates an array of strings that can be used to call vcpkg with common arguments configured in Parameters. The first array entry is the vcpkg command itself.

    The path to the vcpkg executable is detected in the following order:
    - From Parameters.Command. An error is raised if the path does not resolve to an existing executable.
    - From Parameters.RootDir/vcpkg.
    - From $env:VCPKG_ROOT/vcpkg.
    - From $env:PATH.

    The vcpkg root directory is detected in the following order:
    - From Parameters.RootDir. An error is raised if the path does not resolve to a directory containing a file named .vcpkg-root.
    - From the directory containing Parameters.Command if it contains a file named .vcpkg-root.
    - From $env:VCPKG_ROOT. An error is raised if the path does not resolve to a directory containing a file named .vcpkg-root.

    Currently recognized parameters:
    - Command (specify the vcpkg executable)
    - RootDir (--vcpkg-root)
    - Triplet (--triplet)
    - DownloadDir (--downloads-root). Defaults to '<vcpkg-root>/downloads'
    - BuildDir (--x-buildtrees-root). Defaults to '<vcpkg-root>/buildtrees'
    - PackageDir (--x-packages-root). Defaults to '<vcpkg-root>/packages'
    - InstallDir (--x-install-root). Defaults to '<vcpkg-root>/installed'
    - ManifestDir (--x-manifest-root)
    - OverlayPorts (--overlay-ports)

    .PARAMETER Verb
    The required vcpkg verb (command) to be called.

    Currently recognized verbs:
    - install
    - export

    .PARAMETER Parameters
    The required hashtable of name-value pairs to extract common arguments from.

    .PARAMETER OutputDir
    An optional parent directory to use for DownloadDir, BuildDir, PackageDir, and InstallDir insted of <vcpkg-root>.

    .OUTPUTS
    - An array of strings that can be used to invoke vcpkg with common arguments.
    - The detected vcpkg root directory.

    .LINK
    https://learn.microsoft.com/en-us/vcpkg/commands/common-options
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("install", "export")]
        [hashtable]$Verb,

        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable]$Parameters
    )

    # Find the vcpkg executable and root directory:

    # Try a user-specified root first:
    $private:root = $null
    if ($Parameters.ContainsKey("RootDir")) {
        $private:dir = $Parameters.RootDir
        if (-not (Test-VcpkgRoot -Path $dir)) {
            throw "The path '$dir' is not a valid vcpkg root directory."
        }
        $root = Resolve-Path -Path $dir -Force
    }

    # Try a user-specified vcpkg command first:
    $private:exe = $null
    if ($Parameters.ContainsKey("Command")) {
        $private:file = $Parameters.Command
        if (-not (Test-Executable -Path $file)) {
            throw "The path '$file' is not a valid vcpkg executable."
        }
        $exe = Resolve-Path -Path $file -Force
    }

    # If $root is undefined but $exe is defined, try to set $root from the parent directory of $exe:
    if (($null -eq $root) -and -not ($null -eq $exe)) {
        $private:dir = [System.IO.Path]::GetDirectoryName($exe)
        if (Test-VcpkgRoot -Path $dir) {
            $root = $dir
        }
    }

    # If $exe is undefined but $root is defined, try to set $exe from $root:
    if (($null -eq $exe) -and -not ($null -eq $root)) {
        $exe = Get-Executable -Path $root -Name 'vcpkg'
    }

    # If both $root and $exe are still undefined, try to set them from $env:VCPKG_ROOT:
    if (($null -eq $root) -and ($null -eq $exe)) {
        $private:dir = $env:VCPKG_ROOT
        if (-not [System.String]::IsNullOrEmpty($dir)) {
            if (Test-VcpkgRoot -Path $dir) {
                $root = $dir
                $exe = Get-Executable -Path $root -Name 'vcpkg'
            }
        }
    }

    # No joy.
    if (($null -eq $root) -or ($null -eq $exe)) {
        throw "Could not find the vcpkg executable and root directory."
    }
    if ($null -eq $root) {
        throw "Could not find the vcpkg the root directory."
    }
    if ($null -eq $exe) {
        throw "Could not find the vcpkg executable."
    }


    $private:params = @()

    # Start building up the command line:
    params += $exe
    params += $Verb
    params += "--vcpkg-root=$root"

    $private:triplet = Get-DefaultTriplet -Parameters $Parameters
    $params += "--triplet=$triplet"
    Write-Verbose "Using target triplet '$triplet'"

    if ($Parameters.ContainsKey("ManifestDir")) {
        $ManifestDir = $Parameters.ManifestDir
        $manifest = Join-Path -Path $ManifestDir -ChildPath 'vcpkg.json' -Resolve -ErrorAction Ignore
        if ($null = $manifest) {
            throw "The specified manifest directory '$ManifestDir' does not exist, is not a directory, or does not contain vcpkg.json."
        }
        $params += "--x-manifest-root=$ManifestDir"
        Write-Verbose "Using vcpkg.json from '$ManifestDir'"
    }

    if ($Parameters.ContainsKey("OverlayPorts")) {
        $Parameters.OverlayPorts | ForEach-Object {
            $path = Resolve-Path -Path $_ -Force -ErrorAction Ignore
            if ($null -eq $path) {
                throw "The overlay port directory '$_' does not exist or is not a directory."
            }
            $params += "--overlay-ports=$path"
            Write-Verbose "Using overlay ports from '$path'"
        }
    }

    # Setup the default parent for outputs:
    if ($PSBoundParameters.ContainsKey("OutputDir")) {
        $private:outdir = $PSBoundParameters.OutputDir;
    }
    else {
        $private:outdir = $root
    }

    # Setup default paths:
    if ($Parameters.ContainsKey("DownloadDir")) {
        $DownloadDir = $Parameters.DownloadDir
    }
    else {
        $DownloadDir = Join-RelativePath -Path $outdir -ChildPath 'downloads'
    }
    $params += "--downloads-root=$DownloadDir"

    if ($Parameters.ContainsKey("BuildDir")) {
        $BuildDir = $Parameters.BuildDir
    }
    else {
        $BuildDir = Join-RelativePath -Path $outdir -ChildPath 'buildtrees'
    }
    $params += "--x-buildtrees-root=$BuildDir"

    if ($Parameters.ContainsKey("PackageDir")) {
        $PackageDir = $Parameters.PackageDir
    }
    else {
        $PackageDir = Join-RelativePath -Path $outdir -ChildPath 'packages'
    }
    $params += "--x-packages-root=$PackageDir"

    if ($Parameters.ContainsKey("InstallDir")) {
        $InstallDir = $Parameters.InstallDir
    }
    else {
        $InstallDir = Join-RelativePath -Path $outdir -ChildPath 'installed'
    }
    $params += "--x-install-root=$InstallDir"

    return $params, $root
}