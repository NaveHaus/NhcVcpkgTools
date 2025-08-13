Set-StrictMode -Version 3.0

function Install-NhcVcpkgPorts {
    <#
    .SYNOPSIS
    Build and install the requested vcpkg ports.

    .DESCRIPTION
    This function wraps the `vcpkg install` command to provide additional functionality that is inconvenient or impossible to script using response files alone (e.g. versioned builds). By default, the path is used to find the vcpkg executable, but this behavior can be overridden by the Vcpkg parameter. Also, VCPKG_* environment variables are respected unless overridden by a corresponding parameter passed to the function.

    Note: Requires vcpkg 2024-11-12 or newer for '--classic' support.

    .PARAMETER OutputDir
    Specifies a directory in which to build and install the selected ports. Defaults to the vcpkg root directory. The directory will be created if it does not exist. An error will be raised if OutputDir is the current directory and Tag is not specified.

    .PARAMETER Tag
    Creates a subdirectory under OutputDir in which to build and install the ports. If a string is specified, it will be used for the directory name.
    Otherwise, a timestamp with format "yyMMdd-hhmmss" will be used as the directory name. Note that the string must be a valid file name without '/' or '\'.

    .PARAMETER Quiet
    Suppresses all output from the vcpkg command, including errors.

    .PARAMETER Ports
    Installs only the specified ports. Note that vcpkg will be called with '--classic' to ignore a manifest file if present. Cannot be combined with All.

    .PARAMETER All
    Installs ports defined by a manifest that is found automatically by vcpkg or specified by ManifestRoot. Cannot be combined with Ports.

    .PARAMETER Command
    Specifies the path to the vcpkg executable to call.

    .PARAMETER Triplet
    Specifies the target triplet (e.g., x64-windows). Auto-detected if not provided.

    .PARAMETER RootDir
    Specifies the vcpkg root path to use.

    .PARAMETER DownloadDir
    Specifies a subdirectory of OutputDir[/Tag] in which to store downloaded files. If OutputDir is specified, DownloadDir must be relative. Defaults to './downloads'.

    .PARAMETER BuildDir
    Specifies a subdirectory of OutputDir[/Tag] in which to build the ports. If OutputDir is specified, BuildDir must be relative. Defaults to './buildtrees'.

    .PARAMETER PackageDir
    Specifies a subdirectory of OutputDir[/Tag] in which to store packaged ports. If OutputDir is specified, PackageDir must be relative. Defaults to './packages'.

    .PARAMETER InstallDir
    Specifies a subdirectory of OutputDir[/Tag] in which to install the selected ports. If OutputDir is specified, InstallDir must be relative. Defaults to './installed'.

    .PARAMETER ManifestDir
    Specifies the directory containing 'vcpkg.json'. Only used if All is passed.

    .PARAMETER OverlayPorts
    Specifies one or more paths to overlay ports.

    .EXAMPLE
    Install-NhcVcpkgPorts -All -Tag

    Builds and installs all ports defined by the default manifest file to './build/<yyMMdd-hhmmss>' for the default target triplet.

    .EXAMPLE
    Install-NhcVcpkgPorts -All -Tag 1.0.0 -ManifestDir './config'

    Builds and installs all ports defined by './config/vcpkg.json' to './build/<yyMMdd-hhmmss>' for the default target triplet.

    .EXAMPLE
    Install-NhcVcpkgPorts -Ports zlib -OutputDir 'c:/vcpkg-release' -Triplet x64-windows-static

    Builds and installs zlib and its dependencies to 'c:/vcpkg-release' for the x64-windows-static triplet.

    .EXAMPLE
    Install-NhcVcpkgPorts -All -RootDir '/vcpkg/2025-07-25' -OutputDir '/vcpkg-releases/2025-07-25' -Triplet x64-linux

    Builds and installs all ports defined by the default manifest to '/vcpkg-releases/2025-07-25' for the x64-linux triplet.

    .OUTPUTS
    Strings holding the generated OutputDir and Tag.

    .LINK
    https://learn.microsoft.com/en-us/vcpkg/commands/export
    #>

    [CmdletBinding(DefaultParameterSetName = "Ports", SupportsShouldProcess = $true)]
    param (
        [Parameter(ParameterSetName = "Ports", Mandatory = $true, Position = 0)]
        [string[]]$Ports,

        [Parameter(ParameterSetName = "All", Mandatory = $true)]
        [switch]$All,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$OutputDir,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [AllowEmptyString()][string]$Tag,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [switch]$Quiet,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$Vcpkg,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$Triplet,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$RootDir,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$BuildDir,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$InstallDir,

        [Parameter(ParameterSetName = "All")]
        [string]$ManifestDir,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string[]]$OverlayPorts
    )

    # Generate a custom OutputDir for installs:
    $private:splat = $null
    $private:outdir = $null
    $private:tag = $null
    if ($PSBoundParameters.ContainsKey("OutputDir")) {
        $splat.OutputDir = $PSBoundParameters.OutputDir
    }
    if ($PSBoundParameters.ContainsKey("Tag")) {
        $splat.Tag = $PSBoundParameters.Tag
    }

    if ($null -ne $splat) {
        $private:outdir, $private:tag = Get-TaggedOutputDir @splat -AllowCwd:$false
    }

    $cmdline, $root = Get-CommonArguments -Verb 'install' -OutputDir $outdir -Parameters $PSBoundParameters

    if ($null -eq $outdir) {
        $outdir = $root
    }

    Write-Verbose "Using output directory '$outdir'"

    $cmd = $cmdline -join ' '
    if ($PSCmdlet.ShouldProcess('vcpkg install')) {
        Write-Verbose "Executing '$cmd'"
    }
    else {
        Write-Host "Whatif: Would execute '$cmd'"
        $cmd += " --dry-run"
    }

    if ($Quiet) {
        & $cmd 2>&1 | Out-Null
    }
    else {
        & $cmd
    }

    return $outdir, $tag
}