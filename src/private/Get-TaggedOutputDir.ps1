Set-StrictMode -Version 3.0

. $PSScriptRoot\ConvertTo-NormalizedPath.ps1
. $PSScriptRoot\Get-PathInfo.ps1
. $PSScriptRoot\Join-RelativePath.ps1
. $PSScriptRoot\Test-PathString.ps1

function Get-TaggedOutputDir {
    <#
    .SYNOPSIS
    Generates a vcpkg output path based on OutputDir and Tag.

    .DESCRIPTION
    This function creates a standardized path for vcpkg commands that generate output. At least one of OutputDir or Tag must be passed, otherwise an error is raised. By default, an error is generated if the output directory resolves to the current working directory, as this is undesirable in mnay cases. Pass AllowCwd to allow the function to return Get-Location.

    .PARAMETER OutputDir
    The base output directory.

    .PARAMETER Tag
    Add a named subdirectory under OutputDir. If a non-empty string is specified, it will be used for the directory name. Otherwise, a timestamp with format "yyMMdd-hhmmss" will be used as the directory name. Note that the string must be a valid file name without '/' or '\'.

    .PARAMETER Normalize
    If passed, the returned paths are normalized by calling CovnertTo-NormalizedPath.

    .PARAMETER AllowCwd
    If passed, the output of Get-Location is allowed for OutputDir.

    .OUTPUTS
    Returns a hashtable with fields:
    - BaseDir = @{ Path, Exists }: OutputDir without the Tag if OutputDir was passed.
    - OutputDir = @{ Path, Exists }: The computed output directory, including Tag if it was passed or generated.
    - Tag: The tag if one was passed or generated.

    The "Exists" hashtable field indicates whether or not the corresponding directory existed before this function was invoked.

    .NOTES
    If an output directory was not generated, then OutputDir, BaseDir and Tag will be $null.
    #>

    [CmdletBinding()]
    param (
        [AllowEmptyString()]
        [string]$OutputDir,

        [AllowEmptyString()]
        [string]$Tag,

        [switch]$Normalize,
        [switch]$AllowCwd
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }
    }

    process {

        $private:outdir = $null
        $private:basedir = $null
        if ($PSBoundParameters.ContainsKey("OutputDir")) {
            if (-not [string]::IsNullOrWhiteSpace($OutputDir)) {
                $outdir = $OutputDir
                $basedir = $outdir
            }
        }

        $private:outtag = $null
        if ($PSBoundParameters.ContainsKey("Tag")) {
            $outtag = $Tag
            if ([string]::IsNullOrWhiteSpace($outtag)) {
                $outtag = Get-Date -Format "yyMMdd-hhmmss"
            }

            # Validate the tag (note that checking a generated timestamp is intentional):
            if (-not (Test-FileNameString -FileName $outtag)) {
                Write-Error "The tag '$outtag' contains invalid characters."
            }
        }

        $result = @{
            BaseDir   = $null
            OutputDir = $null
            Tag       = $null
        }

        # Stop if no output directory can be computed:
        if (($null -eq $outdir) -and ($null -eq $outtag)) {
            return $result
        }
        elseif ($null -eq $outdir) {
            $outdir = $outtag
        }
        elseif ($null -ne $outtag) {
            $outdir = Join-RelativePath -Path $outdir -ChildPath $outtag
        }

        # Disallow the current working directory by default:
        if (-not $AllowCwd) {
            $private:cwd = Join-RelativePath -Path (Get-Location) -ChildPath . -Resolve
            $private:resolved = Join-RelativePath -Path $outdir -ChildPath . -Resolve -ErrorAction Ignore
            if ("$resolved" -eq "$cwd") {
                Write-Error "Cannot output to the current working directory."
            }
        }

        # Check for existing directories:
        $private:info = Get-PathInfo -Path $basedir
        if ($info.Exists -and -not $info.PSIsContainer) {
            Write-Error "Existing path '$basedir' is not a directory"
        }
        else {
            if ($Normalize) {
                $basedir = ConvertTo-NormalizedPath -Path $basedir
            }
            $result.BaseDir = @{ Path = $basedir; Exists = $info.Exists }
        }

        # Check for existing directories:
        $private:info = Get-PathInfo -Path $outdir
        if ($info.Exists -and -not $info.PSIsContainer) {
            Write-Error "Existing path '$outdir' is not a directory"
        }
        else {
            if ($Normalize) {
                $outdir = ConvertTo-NormalizedPath -Path $outdir
            }
            $result.OutputDir = @{ Path = $outdir; Exists = $info.Exists }
        }

        if ($null -ne $outtag) {
            $result.Tag = $outtag
        }

        return $result
    }
}