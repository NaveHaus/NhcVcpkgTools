Set-StrictMode -Version 3.0

function Get-TaggedOutputDir {
    <#
    .SYNOPSIS
    Generates a vcpkg output path based on OutputDir and Tag.

    .DESCRIPTION
    This function creates a standardized path for vcpkg commands that generate output. At least one of OutputDir or Tag must be passed, otherwise an error is raised. By default, an error is generated if the output directory resolves to the current working directory, as this is undesirable in mnay cases. Pass AllowCwd to allow the function to return Get-Location.

    .PARAMETER OutputDir
    The base output directory. 

    .PARAMETER Tag
    Add a named subdirectory under OutputDir. If a string is specified, it will be used for the directory name. Otherwise, a timestamp with format "yyMMdd-hhmmss" will be used as the directory name. Note that the string must be a valid file name without '/' or '\'.

    .PARAMETER AllowCwd
    If passed, the output of Get-Location is allowed for OutputDir.

    .OUTPUTS
    Strings holding the generated OutputDir and Tag.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [AllowEmptyString()]
        [string]$Tag,

        [switch]$AllowCwd
    )

    $private:outdir = $null
    if ($PSBoundParameters.ContainsKey("OutputDir")) {
        $outdir = $PSBoundParameters.OutputDir
    }

    $private:tag = $null
    if ($PSBoundParameters.ContainsKey("Tag")) {
        $tag = $PSBoundParameters.Tag
        if ([string]::IsNullOrWhiteSpace($tag)) {
            $private:tag = Get-Date -Format "yyMMdd-hhmmss"
        }

        # Validate the tag (note that checking a generated timestamp is intentional):
        if ($private:tag.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ne -1) {
            throw "The tag '$tag' contains invalid characters."
        }
    }

    # Combine $outdir and $tag if both are defined:
    if (-not [string]::IsNullOrWhiteSpace($tag)) {
        if ($null -eq $outdir) {
            $outdir = $tag
        }
        else {
            $outdir = Join-Path -Path $outdir -ChildPath $tag
        }
    }

    if ($null -eq $outdir) {
        throw "At least one of OutputDir or Tag is required."
    }

    # Disallow the current working directory by default:
    if (-not $PSBoundParameters.AllowCwd) {
        $private:cwd = Get-Location
        $private:resolved = Resolve-Path -Path $OutputDir -Force -ErrorAction Ignore
        if ("$resolved" -eq "$cwd") {
            throw "Cannot output to the current working directory."
        }
    }

    return $outdir, $tag
}