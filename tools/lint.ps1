#Requires -Version 7.4
#Requires -Modules PSScriptAnalyzer

[CmdletBinding()]
param(
    [ValidateSet('local', 'github')]
    [string]$Mode = 'local',

    [string]$SettingsPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\PSScriptAnalyzerSettings.psd1'),

    [string]$RepoRoot = (Join-Path -Path $PSScriptRoot -ChildPath '..')
)

Set-StrictMode -Version Latest

function Resolve-RepoRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $repoRootFull = [System.IO.Path]::GetFullPath($RepoRoot)
    $candidateFull = [System.IO.Path]::GetFullPath($Path)

    $repoRootWithSeparator = $repoRootFull.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar

    if (
        $candidateFull.Equals($repoRootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        $candidateFull.StartsWith($repoRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        $relative = [System.IO.Path]::GetRelativePath($repoRootFull, $candidateFull)
        return $relative.Replace('\', '/')
    }

    return $Path.Replace('\', '/')
}

function Get-LintTargetFile {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($RepoRoot)

    $scope = @(
        @{ RelativePath = 'NhcVcpkgTools'; Extensions = @('.ps1', '.psm1', '.psd1') }
        @{ RelativePath = 'tests'; Extensions = @('.ps1') }
        @{ RelativePath = 'tools'; Extensions = @('.ps1') }
    )

    $collected = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $scope) {
        $targetPath = Join-Path -Path $resolvedRoot -ChildPath $entry.RelativePath
        if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
            continue
        }

        $entry.Extensions = @($entry.Extensions)
        foreach ($file in Get-ChildItem -Path $targetPath -Recurse -File) {
            if ($entry.Extensions -contains $file.Extension) {
                $collected.Add($file.FullName)
            }
        }
    }

    return [string[]]@($collected | Sort-Object -Unique)
}

function Format-GitHubAnnotation {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [psobject]$Diagnostic,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $severity = switch ($Diagnostic.Severity) {
        'Error' { 'error' }
        'Warning' { 'warning' }
        default { 'notice' }
    }

    $properties = [System.Collections.Generic.List[string]]::new()

    if ($Diagnostic.ScriptPath) {
        $properties.Add('file=' + (Resolve-RepoRelativePath -Path $Diagnostic.ScriptPath -RepoRoot $RepoRoot))
    }

    if ($Diagnostic.PSObject.Properties.Name -contains 'Line' -and $Diagnostic.Line) {
        $properties.Add('line=' + $Diagnostic.Line)
    }

    if ($Diagnostic.PSObject.Properties.Name -contains 'Column' -and $Diagnostic.Column) {
        $properties.Add('col=' + $Diagnostic.Column)
    }

    $message = "[$($Diagnostic.RuleName)] $($Diagnostic.Message)"

    if ($properties.Count -gt 0) {
        return "::$severity $($properties -join ',')::$message"
    }

    return "::$severity::$message"
}

function Format-LocalDiagnostic {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [psobject]$Diagnostic,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $path = if ($Diagnostic.ScriptPath) {
        Resolve-RepoRelativePath -Path $Diagnostic.ScriptPath -RepoRoot $RepoRoot
    }
    else {
        '<unknown>'
    }

    $line = if ($Diagnostic.PSObject.Properties.Name -contains 'Line' -and $Diagnostic.Line) {
        $Diagnostic.Line
    }
    else {
        '?'
    }

    return "[$($Diagnostic.Severity)] $($Diagnostic.RuleName): $($Diagnostic.Message) (${path}:$line)"
}

function Invoke-LintRunner {
    [CmdletBinding()]
    param(
        [ValidateSet('local', 'github')]
        [string]$Mode = 'local',

        [Parameter(Mandatory)]
        [string]$SettingsPath,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $targetFiles = @(Get-LintTargetFile -RepoRoot $RepoRoot)

    $diagnostics = @()
    if ($targetFiles.Count -gt 0) {
        foreach ($targetFile in $targetFiles) {
            $diagnostics += @(Invoke-ScriptAnalyzer -Path $targetFile -Settings $SettingsPath)
        }
    }

    $outputLines = @(
        foreach ($diagnostic in $diagnostics) {
            if ($Mode -eq 'github') {
                Format-GitHubAnnotation -Diagnostic $diagnostic -RepoRoot $RepoRoot
            }
            else {
                Format-LocalDiagnostic -Diagnostic $diagnostic -RepoRoot $RepoRoot
            }
        }
    )

    $hasBlockingFindings = $false
    foreach ($diagnostic in $diagnostics) {
        if ($diagnostic.Severity -in @('Warning', 'Error')) {
            $hasBlockingFindings = $true
            break
        }
    }

    [pscustomobject]@{
        TargetFiles  = $targetFiles
        Diagnostics  = $diagnostics
        OutputLines  = $outputLines
        ExitCode     = $(if ($hasBlockingFindings) { 1 } else { 0 })
        Mode         = $Mode
        SettingsPath = $SettingsPath
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Invoke-LintRunner -Mode $Mode -SettingsPath $SettingsPath -RepoRoot $RepoRoot

    foreach ($line in $result.OutputLines) {
        Write-Output $line
    }

    exit $result.ExitCode
}