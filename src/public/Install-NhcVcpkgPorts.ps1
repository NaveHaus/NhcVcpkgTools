Set-StrictMode -Version 3.0

. $PSScriptRoot\..\private\ConvertTo-NormalizedPath.ps1
. $PSScriptRoot\..\private\Get-CommonArguments.ps1
. $PSScriptRoot\..\private\Get-TaggedOutputDir.ps1

function Install-NhcVcpkgPorts {
    <#
    .SYNOPSIS
    Build and install the requested vcpkg ports.

    .DESCRIPTION
    This function wraps the 'vcpkg install' command to provide additional functionality that is inconvenient or impossible to script using response files alone (e.g. versioned port installations). VCPKG_* environment variables are respected unless overridden by a corresponding parameter passed to the function.

    Note: Requires vcpkg 2024-11-12 or newer for '--classic' support.

    .PARAMETER Ports
    Installs only the specified ports. Note that vcpkg will be called with '--classic' to ignore a manifest file if present. Cannot be combined with All.

    .PARAMETER All
    Installs ports defined by a manifest that is found automatically by vcpkg or specified by ManifestRoot. Cannot be combined with Ports.

    .PARAMETER OutputDir
    Specifies a directory in which to build and install the selected ports. Defaults to the vcpkg root directory. The directory will be created if it does not exist. An error will be raised if OutputDir is the current directory and Tag is not passed.

    .PARAMETER Tag
    Creates a subdirectory under OutputDir in which to build and install the ports. If a non-empty string is passed, it will be used for the directory name. Otherwise, a timestamp with format "yyyyMMdd-HHmmss" will be used as the directory name. Note that the string must be a valid file name without '/' or '\'.

    .PARAMETER Quiet
    Suppresses all output from the vcpkg command, including errors.

    .PARAMETER Command
    Specifies the path to the vcpkg executable to call.

    .PARAMETER RootDir
    Specifies the <vcpkg-root> to use. If not passed, <vcpkg-root> is detected from either the passed Command or $env:VCPKG_ROOT.

    .PARAMETER Triplet
    Specifies the target triplet (e.g., x64-windows). Auto-detected if not provided.

    .PARAMETER OverlayPorts
    Specifies one or more paths to overlay ports.

    .PARAMETER OverlayTriplets
    Specifies one or more paths to overlay triplets.

    .PARAMETER ManifestDir
    Specifies the directory containing 'vcpkg.json'. Only used if All is passed.

    .PARAMETER DownloadDir
    Specifies a directory in which to store downloaded files. If relative, DownloadDir will be a subdirectory of OutputDir[/Tag]. Defaults to './downloads'.

    .PARAMETER BuildDir
    Specifies a directoryag] in which to build the ports. If relative, BuildDir will be a subdirectory of OutputDir[/Tag]. Defaults to './buildtrees'.

    .PARAMETER PackageDir
    Specifies a directory in which to store packaged ports. If relative, PackageDir will be a subdirectory of OutputDir[/Tag]. Defaults to './packages'.

    .PARAMETER InstallDir
    Specifies a directory in which to install the selected ports. If relative, InstallDir will be a subdirectory of OutputDir[/Tag]. Defaults to './installed'.

    .PARAMETER BinarySources
    Specifies one or more binary sources to use for finding and/or saving ports.

    .EXAMPLE
    Install-NhcVcpkgPorts -All -Tag ''

    Builds and installs all ports defined by the default manifest file to './build/<yyyyMMdd-HHmmss>' for the default target triplet.

    .EXAMPLE
    Install-NhcVcpkgPorts -All -Tag 1.0.0 -ManifestDir './config'

    Builds and installs all ports defined by './config/vcpkg.json' to './build/<yyyyMMdd-HHmmss>' for the default target triplet.

    .EXAMPLE
    Install-NhcVcpkgPorts -Ports zlib -OutputDir 'c:/vcpkg-release' -Triplet x64-windows-static

    Builds and installs zlib and its dependencies to 'c:/vcpkg-release' for the x64-windows-static triplet.

    .EXAMPLE
    Install-NhcVcpkgPorts -All -RootDir '/vcpkg/2025-07-25' -OutputDir '/vcpkg-releases/2025-07-25' -Triplet x64-linux

    Builds and installs all ports defined by the default manifest to '/vcpkg-releases/2025-07-25' for the x64-linux triplet.

    .OUTPUTS
    Returns a hashtable with fields:
    - Command: the full vcpkg executable path
    - Arguments: An array of strings that can be used to invoke vcpkg using Start-Process.
    - RootDir: The vcpkg root directory.
    - BaseDir = @{ Path, Exists }: OutputDir without the Tag if OutputDir was passed, $null otherwise.
    - OutputDir = @{ Path, Exists }: The output directory including the Tag if it was passed or generated.
    - DownloadDir = @{ Path, Exists }: The string passed to --downloads-root.
    - BuildDir = @{ Path, Exists }: The string passed to --x-buildtrees-root.
    - PackageDir = @{ Path, Exists }: The string passed to --x-packages-root.
    - InstallDir = @{ Path, Exists }: The string passed to --x-install-root.
    - Tag: The tag if one was passed or generated, $null otherwise.

    The "Exists" fields indicate whether or not the corresponding directory existed before this function was invoked.

    .LINK
    https://learn.microsoft.com/en-us/vcpkg/commands/install
    #>

    [CmdletBinding(DefaultParameterSetName = "Ports", SupportsShouldProcess = $true)]
    param (
        [Parameter(ParameterSetName = "Ports", Mandatory = $true, Position = 0)]
        [string[]]$Ports,

        [Parameter(ParameterSetName = "All", Mandatory = $true)]
        [switch]$All,

        [string]$OutputDir,

        [AllowEmptyString()]
        [string]$Tag,

        [Parameter(ParameterSetName = "All")]
        [string]$ManifestDir,

        [switch]$Quiet,
        [string]$Command,
        [string]$Triplet,
        [string]$RootDir,
        [string]$DownloadDir,
        [string]$BuildDir,
        [string]$PackageDir,
        [string]$InstallDir,
        [string[]]$OverlayPorts,
        [string[]]$OverlayTriplets,
        [string[]]$BinarySources
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {
        # Directory arguments required by vcpkg install:
        $private:required = @( 'DownloadDir', 'BuildDir', 'PackageDir', 'InstallDir' )

        # Directories potentially created by vcpkg install:
        $private:created = @( 'BaseDir', 'ParentDir' ) + $required

        # Generate a custom ParentDir from OutputDir if requested (the default is <vcpkg-root> or RootDir):
        $private:splat = $null
        if ($PSBoundParameters.ContainsKey("OutputDir")) {
            $splat += @{ OutputDir = $OutputDir }
        }
        if ($PSBoundParameters.ContainsKey("Tag")) {
            $splat += @{ Tag = $Tag }
        }
        $private:tagged = Get-TaggedOutputDir @splat -Normalize -AllowCwd:$false
        $splat = $null

        # Return BaseDir and Tag with $config:
        $private:config = @{}
        $config += @{ BaseDir = $tagged.BaseDir }
        $config += @{ Tag = $tagged.Tag }

        # Build the common vcpkg arguments list:
        $tagged.OutputDir ??= @{ Path = ''; Exists = $false }
        # Note: OutputDir must be passed as ParentDir so required directories (above) are created under either the default <vcpkg-root> or the caller-defined output directory.
        $config += Get-CommonArguments -Parameters $PSBoundParameters -Directories $required -ParentDir $tagged.OutputDir.Path

        $private:exe = $config.Command
        $private:verb = 'install'

        $private:params = @()
        $params += $verb
        $params += "--no-print-usage"
        $params += $config.Arguments

        $private:target = $config.ParentDir.Path
        Write-Verbose "Installing to '$target'"

        if ($PSCmdlet.ShouldProcess($target, 'vcpkg install')) {
            Write-Verbose "Executing '$exe $params'"
        }
        else {
            Write-Host "Whatif: Would execute '$exe $params'"
            $params += "--dry-run"
        }

        if ($Quiet) {
            Start-Process -FilePath $exe -ArgumentList $params -NoNewWindow -Wait -WhatIf:$false -Confirm:$false 2>&1 | Out-Null
        }
        else {
            Start-Process -FilePath $exe -ArgumentList $params -NoNewWindow -Wait -WhatIf:$false -Confirm:$false
        }

        # Try to clean up after --dry-run:
        if ($WhatIfPreference) {
            # Try to clean up created output subdirectories:
            $private:todo = $created
            $private:ignore = $config.RootDir
            $todo | ForEach-Object {
                if (-not $config.ContainsKey($_)) {
                    Write-Warning "Missing expected key '$_' in `$config; ignoring"
                }
                else {
                    $private:dir = $config[$_]
                    if ($null -ne $dir) {
                        $private:clean = $dir.Path
                        if (-not $dir.Exists) {
                            # Only clean up if the path was created:
                            if (Test-Path -Path $clean -PathType Container) {
                                # Just in case:
                                if ($clean -ne $ignore) {
                                    Write-Verbose "Cleaning up output directory '$clean' for dry run"
                                    Remove-Item -Path $clean -Recurse -Force -WhatIf:$false -Confirm:$false
                                }
                            }
                        }
                        else {
                            Write-Verbose "Not removing existing directory '$clean'"
                        }
                    }
                }
            }
        }

        return $config
    }
}