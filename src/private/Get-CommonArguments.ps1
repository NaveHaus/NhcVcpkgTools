Set-StrictMode -Version 3.0

. $PSScriptRoot\ConvertTo-NormalizedPath.ps1
. $PSScriptRoot\Get-Executable.ps1
. $PSScriptRoot\Get-DefaultTriplet.ps1
. $PSScriptRoot\Join-RelativePath.ps1
. $PSScriptRoot\Test-Executable.ps1
. $PSScriptRoot\Test-VcpkgRoot.ps1

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
    - OverlayPorts (--overlay-ports)
    - ManifestDir (--x-manifest-root)
    - DownloadDir (--downloads-root). Defaults to '<vcpkg-root>/downloads'
    - BuildDir (--x-buildtrees-root). Defaults to '<vcpkg-root>/buildtrees'
    - PackageDir (--x-packages-root). Defaults to '<vcpkg-root>/packages'
    - InstallDir (--x-install-root). Defaults to '<vcpkg-root>/installed'

    .PARAMETER Parameters
    The required hashtable of name-value pairs to extract common arguments from.

    .PARAMETER OutputDir
    An optional parent directory to use for DownloadDir, BuildDir, PackageDir, and InstallDir insted of <vcpkg-root>.

    .OUTPUTS
    Returns a hashtable with fields:
    - Command: the full vcpkg executable path
    - Arguments: An array of strings that can be used to invoke vcpkg using Start-Process.
    - RootDir: The vcpkg root directory.
    - OutputDir = @{ Path, Exists }: The output directory and whether or not it exists. Path will be the same as OutputDir if passed, or the vcpkg root directory otherwise.
    - DownloadDir = @{ Path, Exists }: The string passed to --downloads-root.
    - BuildDir = @{ Path, Exists }: The string passed to --x-buildtrees-root.
    - PackageDir = @{ Path, Exists }: The string passed to --x-packages-root.
    - InstallDir = @{ Path, Exists }: The string passed to --x-install-root.

    The "Exists" fields indicate whether or not the corresponding directory existed before this function was invoked.


    .LINK
    https://learn.microsoft.com/en-us/vcpkg/commands/common-options
    #>

    [CmdletBinding(DefaultParameterSetName = "Parameters", PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [string]$OutputDir
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        # Find the vcpkg executable and root directory:

        # Try a user-specified root first:
        $private:root = $null
        if ($Parameters.ContainsKey("RootDir")) {
            $private:dir = $Parameters.RootDir
            if (-not (Test-VcpkgRoot -Path $dir)) {
                Write-Error "The path '$dir' is not a valid vcpkg root directory."
            }
            $root = $dir
        }

        # Try a user-specified vcpkg command first:
        $private:exe = $null
        if ($Parameters.ContainsKey("Command")) {
            $private:file = $Parameters.Command
            if (-not (Test-Executable -Path $file)) {
                Write-Error "The path '$file' is not a valid vcpkg executable."
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
            Write-Error "Could not find the vcpkg executable and root directory."
        }
        if ($null -eq $root) {
            Write-Error "Could not find the vcpkg the root directory."
        }
        if ($null -eq $exe) {
            Write-Error "Could not find the vcpkg executable."
        }

        # vcpkg doesn't like trailing '\' on Windows, so resolve the path with Join-RelativePath:
        $root = Join-RelativePath -Path $root -ChildPath . -Resolve

        $private:params = @()

        # Start building up the command line:
        $params += "--vcpkg-root=`"$root`""

        $private:triplet = Get-DefaultTriplet -Parameters $Parameters
        $params += "--triplet=`"$triplet`""
        $params += "--host-triplet=`"$triplet`""
        Write-Verbose "Using host and target triplet '$triplet'"

        if ($Parameters.ContainsKey("ManifestDir")) {
            # vcpkg doesn't like trailing '\' on Windows, so use Join-RelativePath to remove them:
            $private:dir = Join-RelativePath -Path $Parameters.ManifestDir -ChildPath . -Resolve -ErrorAction Ignore
            if ($null -eq $dir) {
                Write-Error "The specified manifest directory '$ManifestDir' does not exist, is not a directory, or is inaccessible."
            }

            $manifest = Join-RelativePath -Path $dir -ChildPath 'vcpkg.json' -Resolve -ErrorAction Ignore
            if ($null -eq $manifest) {
                Write-Error "The specified manifest directory '$ManifestDir' does not exist, is not a directory, or does not contain vcpkg.json."
            }
            $params += "--x-manifest-root=`"$dir`""
            Write-Verbose "Using vcpkg.json from '$dir'"
        }

        if ($Parameters.ContainsKey("OverlayPorts")) {
            $Parameters.OverlayPorts | ForEach-Object {
                # vcpkg doesn't like trailing '\' on Windows, and Resolve-Path leaves them, so use
                # Join-RelativePath to remove them:
                $private:dir = Join-RelativePath -Path $_ -ChildPath . -Resolve -ErrorAction Ignore
                if ($null -eq $dir) {
                    Write-Error "The overlay port directory '$_' does not exist or is not a directory."
                }
                $params += "--overlay-ports=`"$dir`""
                Write-Verbose "Using overlay ports from '$dir'"
            }
        }

        # Setup the default parent for outputs:
        if ($PSBoundParameters.ContainsKey("OutputDir")) {
            $private:outdir = $OutputDir;
        }
        else {
            $private:outdir = $root
        }

        # vcpkg doesn't like trailing '\' on Windows, so remove them:
        $outdir = ConvertTo-NormalizedPath($outdir)

        # Just in case:
        if((Test-VcpkgRoot -Path $outdir) -and ($outdir -ne $root)) {
            Write-Warning "Output directory '$outdir' appears to be a vcpkg root directory, but is different from '$root'"
        }

        # Setup default paths:
        if ($Parameters.ContainsKey("DownloadDir")) {
            # vcpkg doesn't like trailing '\' on Windows, so remove them:
            $private:DownloadDir = ConvertTo-NormalizedPath($Parameters.DownloadDir)
        }
        else {
            $private:DownloadDir = Join-RelativePath -Path $outdir -ChildPath 'downloads'
        }
        $params += "--downloads-root=`"$DownloadDir`""

        if ($Parameters.ContainsKey("BuildDir")) {
            # vcpkg doesn't like trailing '\' on Windows, so remove them:
            $private:BuildDir = ConvertTo-NormalizedPath($Parameters.BuildDir)
        }
        else {
            $BuildDir = Join-RelativePath -Path $outdir -ChildPath 'buildtrees'
        }
        $params += "--x-buildtrees-root=`"$BuildDir`""

        if ($Parameters.ContainsKey("PackageDir")) {
            # vcpkg doesn't like trailing '\' on Windows, so remove them:
            $private:PackageDir = ConvertTo-NormalizedPath($Parameters.PackageDir)
        }
        else {
            $PackageDir = Join-RelativePath -Path $outdir -ChildPath 'packages'
        }
        $params += "--x-packages-root=`"$PackageDir`""

        if ($Parameters.ContainsKey("InstallDir")) {
            # vcpkg doesn't like trailing '\' on Windows, so remove them:
            $private:InstallDir = ConvertTo-NormalizedPath($Parameters.InstallDir)
        }
        else {
            $InstallDir = Join-RelativePath -Path $outdir -ChildPath 'installed'
        }
        $params += "--x-install-root=`"$InstallDir`""

        # Build up the hashtable return value:
        return @{
            Command     = $exe
            Arguments   = $params
            RootDir     = $root
            OutputDir   = @{ Path = $outdir; Exists = (Test-Path -Path $outdir -PathType Container) }
            DownloadDir = @{ Path = $DownloadDir; Exists = (Test-Path -Path $DownloadDir -PathType Container) }
            BuildDir    = @{ Path = $BuildDir; Exists = (Test-Path -Path $BuildDir -PathType Container) }
            PackageDir  = @{ Path = $PackageDir; Exists = (Test-Path -Path $PackageDir -PathType Container) } 
            InstallDir  = @{ Path = $InstallDir; Exists = (Test-Path -Path $InstallDir -PathType Container) } 
        }
    }
}