Set-StrictMode -Version 3.0

. $PSScriptRoot\ConvertTo-NormalizedPath.ps1
. $PSScriptRoot\Get-Executable.ps1
. $PSScriptRoot\Get-DefaultTriplet.ps1
. $PSScriptRoot\Join-RelativePath.ps1
. $PSScriptRoot\Test-AbsolutePath.ps1
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
    - Ports (enables --classic)
    - All (enabled --feature-flags=manifest,versions)
    - RootDir (--vcpkg-root)
    - Triplet (--triplet)
    - OverlayPorts (--overlay-ports[])
    - OverlayTriplets (--overlay-triplets[])
    - ManifestDir (--x-manifest-root)
    - OutputDir (--output-dir). No default.
    - DownloadDir (--downloads-root). Defaults to '<vcpkg-root>/downloads'
    - BuildDir (--x-buildtrees-root). Defaults to '<vcpkg-root>/buildtrees'
    - PackageDir (--x-packages-root). Defaults to '<vcpkg-root>/packages'
    - InstallDir (--x-install-root). Defaults to '<vcpkg-root>/installed'
    - BinarySources (--binarysource[])
    - CachedOnly (--only-binarycaching)
    - Editable (--editable)

    .PARAMETER Parameters
    The required hashtable of name-value pairs to extract common arguments from.

    .PARAMETER Directories
    Specifies which directories should be added to the vcpkg command line. This parameter is case-sensitive. Must be one or more of:
    - OutputDir
    - DownloadDir
    - BuildDir
    - PackageDir
    - InstallDir

    The default list is 'DownloadDir', 'BuildDir', 'PackageDir', 'InstallDir'. 'OutputDir' must be specifically requested, and an error is raised if OutputDir is not passed in Parameters. Also note that OutputDir is not returned.

    .PARAMETER ParentDir
    An optional parent directory to use for DownloadDir, BuildDir, PackageDir, and InstallDir. The default is <vcpkg-root>. May be an empty string, in which case <vcpkg-root> is used as the output directory.

    .OUTPUTS
    Returns a hashtable with fields:
    - Command: the full vcpkg executable path
    - Arguments: An array of strings that can be used to invoke vcpkg using Start-Process.
    - RootDir: The vcpkg root directory.
    - ParentDir = @{ Path, Exists }: The parent directory and whether or not it exists. Path will be the normalized ParentDir if passed, or the normalized vcpkg root directory otherwise.
    - DownloadDir = @{ Path, Exists }: The string passed to --downloads-root.
    - BuildDir = @{ Path, Exists }: The string passed to --x-buildtrees-root.
    - PackageDir = @{ Path, Exists }: The string passed to --x-packages-root.
    - InstallDir = @{ Path, Exists }: The string passed to --x-install-root.

    The "Exists" fields indicate whether or not the corresponding directory existed before this function was invoked. If Directories is passed, only the specified directories are returned.

    .LINK
    https://learn.microsoft.com/en-us/vcpkg/commands/common-options
    #>

    [CmdletBinding(DefaultParameterSetName = "Parameters", PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $false)]
        [ValidateSet("OutputDir", "DownloadDir", "BuildDir", "PackageDir", "InstallDir", IgnoreCase = $false)]
        [string[]]$Directories = @( "DownloadDir", "BuildDir", "PackageDir", "InstallDir" ),

        [AllowEmptyString()]
        [string]$ParentDir
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

        # Force classic mode if ports are specified, manifest mode if all ports are selected:
        if ($Parameters.ContainsKey("Ports")) {
            $params += $Parameters.Ports
            $params += "--classic"
        }
        elseif ($Parameters.ContainsKey("All")) {
            $params += "--feature-flags=`"manifest,versions`""
        }

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

        if ($Parameters.ContainsKey("OverlayTriplets")) {
            $Parameters.OverlayTriplets | ForEach-Object {
                # vcpkg doesn't like trailing '\' on Windows, and Resolve-Path leaves them, so use
                # Join-RelativePath to remove them:
                $private:dir = Join-RelativePath -Path $_ -ChildPath . -Resolve -ErrorAction Ignore
                if ($null -eq $dir) {
                    Write-Error "The overlay port directory '$_' does not exist or is not a directory."
                }
                $params += "--overlay-triplets=`"$dir`""
                Write-Verbose "Using overlay triplets from '$dir'"
            }
        }

        # Setup the default parent for outputs:
        $private:parent = $root
        if ($PSBoundParameters.ContainsKey("ParentDir")) {
            if (-not [System.String]::IsNullOrEmpty($ParentDir)) {
                $private:parent = $ParentDir;
            }
        }

        # vcpkg doesn't like trailing '\' on Windows, so remove them:
        $parent = ConvertTo-NormalizedPath($parent)

        # Just in case:
        if ((Test-VcpkgRoot -Path $parent) -and ($parent -ne $root)) {
            Write-Warning "Parent directory '$parent' appears to be a vcpkg root directory, but is different from '$root'"
        }

        $result = @{
            Command   = $exe
            RootDir   = $root
            ParentDir = @{ Path = $parent; Exists = (Test-Path -Path $parent -PathType Container) }
        }

        # Setup default output paths:
        if ($Directories.Contains("DownloadDir")) {
            $private:DownloadDir = Get-NormalizedNamedDir -Parameters $Parameters -Name 'DownloadDir' -ParentPath $parent -DefaultPath 'downloads'
            $params += "--downloads-root=`"$DownloadDir`""
            $result += @{
                DownloadDir = @{
                    Path   = $DownloadDir
                    Exists = (Test-Path -Path $DownloadDir -PathType Container)
                }
            }
        }

        if ($Directories.Contains("BuildDir")) {
            $private:BuildDir = Get-NormalizedNamedDir -Parameters $Parameters -Name 'BuildDir' -ParentPath $parent -DefaultPath 'buildtrees'
            $params += "--x-buildtrees-root=`"$BuildDir`""
            $result += @{
                BuildDir = @{
                    Path   = $BuildDir
                    Exists = (Test-Path -Path $BuildDir -PathType Container) 
                }
            }
        }

        if ($Directories.Contains("PackageDir")) {
            $private:PackageDir = Get-NormalizedNamedDir -Parameters $Parameters -Name 'PackageDir' -ParentPath $parent -DefaultPath 'packages'
            $params += "--x-packages-root=`"$PackageDir`""
            $result += @{
                PackageDir = @{
                    Path   = $PackageDir
                    Exists = (Test-Path -Path $PackageDir -PathType Container) 
                } 
            }
        }

        if ($Directories.Contains("InstallDir")) {
            $private:InstallDir = Get-NormalizedNamedDir -Parameters $Parameters -Name 'InstallDir' -ParentPath $parent -DefaultPath 'installed'

            $params += "--x-install-root=`"$InstallDir`""
            $result += @{
                InstallDir = @{
                    Path   = $InstallDir
                    Exists = (Test-Path -Path $InstallDir -PathType Container) 
                } 
            }
        }

        # Include OutputDir if requested:
        if ($Directories.Contains("OutputDir")) {
            $private:OutputDir = $null
            if ($Parameters.ContainsKey("OutputDir")) {
                $OutputDir = ConvertTo-NormalizedPath($Parameters.OutputDir)
            }
            if ($null -eq $OutputDir) {
                Write-Error "OutputDir was not passed in Parameters or is null"
            }
            $params += "--output-dir=`"$OutputDir`""
        }

        if ($Parameters.ContainsKey("BinarySources")) {
            $Parameters.BinarySources | ForEach-Object {
                $params += "--binarysource=`"$_`""
                Write-Verbose "Adding binary source '$_'"
            }
        }

        if ($Parameters.ContainsKey("CachedOnly")) {
            $params += "--only-binarycaching"
        }

        if ($Parameters.ContainsKey("Editable")) {
            $params += "--editable"
        }

        # Done:
        $result += @{ Arguments = $params }
        return $result
    }
}

function Get-NormalizedNamedDir {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$ParentPath,
        [Parameter(Mandatory = $true, Position = 3)]
        [string]$DefaultPath
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        if ($Parameters.ContainsKey($Name)) {
            $private:dir = $Parameters.$Name
        }
        else {
            $private:dir = $DefaultPath
        }

        if (Test-AbsolutePath -Path $dir) {
            $paths = @{ 'Path' = $dir }
            $paths += @{ 'ChildPath' = '.' }
        }
        else {
            $paths = @{ 'Path' = $ParentPath }
            $paths += @{ 'ChildPath' = $dir }
        }

        # vcpkg doesn't like trailing '\' on Windows, so remove them:
        return ConvertTo-NormalizedPath(Join-RelativePath @paths)
    }
}