Set-StrictMode -Version 3.0

function Export-NhcVcpkgPorts {
    <#
    .SYNOPSIS
    Exports installed vcpkg ports.

    .DESCRIPTION
    This function wraps the `vcpkg export` command to provide additional functionality that is inconvenient or impossible to script using response files alone (e.g. versioned exports). By default, the path is used to find the vcpkg executable, but this behavior can be overridden by the Vcpkg parameter. Also, VCPKG_* environment variables are respected unless overridden by a corresponding parameter passed to the function.

    Note: Requires vcpkg 2024-11-12 or newer for '--classic' support.

    .PARAMETER Ports
    Exports only the specified ports. Note that vcpkg will be called with '--classic' to ignore a manifest file if present. Cannot be combined with All.

    .PARAMETER All
    Exports all installed ports. Cannot be combined with Ports.

    .PARAMETER Format
    Specify the export format:
    - Raw  - Export to the './export' directory. This is the default format.
    - 7zip - Export to a .7z file.
    - Zip  - Export to a .zip file.
    - Tgz  - Export to a .tgz file.

    .PARAMETER OutputDir
    Specifies a directory for the export. Defaults to './export' for raw exports and the current working directory for file-based exports. The directory will be created if it does not exist. An error will be raised if a raw export is requested, OutputDir is the current directory, and Tag is not specified.

    .PARAMETER Tag
    Creates a subdirectory under OutputDir for the export. If a string is specified, it will be used for the directory name. Otherwise, a timestamp with format "yyMMdd-hhmmss" will be used as the directory name. Note that the string must be a valid file name without '/' or '\'.

    .PARAMETER Output
    Specifies the base name for a file export. If not specified, the default is 'vcpkg-export'. Note that Output is ignored for raw exports.

    .PARAMETER Quiet
    Suppresses all output from the vcpkg command, including errors.

    .PARAMETER Vcpkg
    Specifies the path to the vcpkg executable to call.

    .PARAMETER Triplet
    Specifies the target triplet (e.g., x64-windows). Auto-detected if not provided.

    .PARAMETER RootDir
    Specifies the vcpkg root path to use.

    .PARAMETER InstallDir
    Specifies the path to the installed ports. The path must exist.

    .PARAMETER ManifestDir
    Specifies the directory containing 'vcpkg.json'. Only used if All is passed.

    .PARAMETER OverlayPorts
    Specifies one or more paths to overlay ports.

    .EXAMPLE
    Export-NhcVcpkgPorts -All -Format zip -Tag

    Exports all installed ports from $VCPKG_ROOT/installed to './<yyMMdd-hhmmss>/vcpkg-export.zip'.

    .EXAMPLE
    Export-NhcVcpkgPorts -Ports fmt -Format zip -Output 'fmt-release'

    Export 'fmt' from $VCPKG_ROOT/installed to './fmt-release.zip'.

    .EXAMPLE
    Export-NhcVcpkgPorts -Ports boost-filesystem,fmt -Format tgz -Triplet x64-linux

    Exports only 'boost-filesystem' and 'fmt' ports from $VCPKG_ROOT/installed for the x64-linux triplet to './vcpkg-export.tgz'.

    .EXAMPLE
    Export-NhcVcpkgPorts -Ports zlib -InstallDir '/vcpkg-data/installed' -OutputDir '.' -Tag

    Raw export of 'zlib' from '/vcpkg-data/installed' to './<yyMMdd-hhmmss>/...' using the default root for version control.

    .EXAMPLE
    Export-NhcVcpkgPorts -Ports zlib -RootDir '/vcpkg-root' -OutputDir '.' -Tag

    Raw export of 'zlib' from '/vcpkg-root/installed' to './<yyMMdd-hhmmss>/...'.

    .EXAMPLE
    Export-NhcVcpkgPorts -Ports zlib -Format 7zip -RootDir '/vcpkg-root' -OutputDir '.' -Output 'zlib-current' -Tag

    Export 'zlib' from '/vcpkg-root/installed' to './<yyMMdd-hhmmss>/zlib-current.7z'.

    .EXAMPLE
    Export-NhcVcpkgPorts -Ports zlib -Format tgz -Vcpkg '/vcpkg-root/vcpkg' -RootDir '/vcpkg-root' -Tag

    Export 'zlib' from '/vcpkg-root/installed' to './export/<yyMMdd-hhmmss>/vcpkg-export.tgz'.

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

        [ValidateSet("raw", "7zip", "zip", "nuget")]
        [string]$Format = "raw",

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$OutputDir,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [AllowEmptyString()][string]$Tag,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string]$Output,

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
        [string]$InstallDir,

        [Parameter(ParameterSetName = "All")]
        [string]$ManifestDir,

        [Parameter(ParameterSetName = "Ports")]
        [Parameter(ParameterSetName = "All")]
        [string[]]$OverlayPorts
    )

    $private:splat = @{ Vcpkg = $PSBoundParameters.Vcpkg }
    $private:exe = Find-NhcVcpkgCommand @splat

    $private:verb = 'export'
    $private:params = @()
    $private:splat = @{}

    # Force classic mode if ports are specified, manifest mode otherwise:
    if ($PSBoundParameters.ContainsKey("Ports")) {
        $params += $PSBoundParameters["Ports"]
        $params += "--classic"
    }
    else {
        $params += "--x-all-installed"
    }

    if ($PSBoundParameters.ContainsKey("RootDir")) {
        $splat = @{ RootDir = $PSBoundParameters.RootDir }
    }
    $private:vcpkg_root = Get-NhcVcpkgRoot @splat
    $params += "--vcpkg-root=$vcpkg_root"
    Write-Verbose "Using vcpkg root at '$vcpkg_root'"

    # Generate OutputDir for exports:
    $splat = @{ OutputDir = $PSBoundParameters.OutputDir; Tag = $PSBoundParameters.Tag }
    if ($Format -ieq "raw") {
        if (-not $PSBoundParameters.ContainsKey("OutputDir")) {
            $splat.OutputDir = './export'
        }

        # Cannot raw export directly to the current working directory:
        else {
            $splat.AllowCwd = $false
        }
    }
    else {
        if (-not $PSBoundParameters.ContainsKey("OutputDir")) {
            $splat.OutputDir = Get-Location
        }
    }
    $private:outdir, $private:tag = Get-TaggedOutputDir @splat

    # Add --output only for archive formats
    if ($PSBoundParameters.ContainsKey("Output") -and $Format -ine "raw") {
        $params += "--output=$Output"
    }

    $params += Get-NhcVcpkgCommonParameters -Parameters $PSBoundParameters

    if ($WhatIfPreference) {
        $params += "--dry-run"
    }

    $params += @(
        "--$Format"
    )


    # Create the output directory if needed:
    if (-not (Test-Path $outdir)) {
        if ($WhatIfPreference) {
            Write-Host "WhatIf: Would create output directory '$outdir'"
        }
        else {
            Write-Verbose "Creating output directory '$outdir'"
            New-Item -ItemType Directory -Path $outdir | Out-Null
        }
    }

    if ($WhatIfPreference) {
        Write-Host "Whatif: Would execute $exe $verb $($params -join ' ')"
    }
    else {
        Write-Verbose "Executing $exe $cmd $($params -join ' ')"
    }

    if ($Quiet) {
        & $exe $verb @params 2>&1 | Out-Null
    }
    else {
        & $exe $verb @params
    }

    return $outdir, $tag
}