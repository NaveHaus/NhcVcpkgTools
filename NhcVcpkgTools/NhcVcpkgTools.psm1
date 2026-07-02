<#
Module file to allow loading the module from a local clone without building a
distributable module. This is recreated when building a distributable module.
#>

# Explicitly load required functions:
$private:Root = $PSScriptRoot

$private:PrivateFunctions = @(
    'ConvertTo-NormalizedPath'
    'Get-BinaryType'
    'Get-CommonArgument'
    'Get-DefaultTriplet'
    'Get-NormalizedNamedDir'
    'Get-Executable'
    'Get-PathInfo'
    'Get-TaggedOutputDir'
    'Invoke-Vcpkg'
    'Join-RelativePath'
    'Test-AbsolutePath'
    'Test-Executable'
    'Test-FileNameString'
    'Test-PathString'
    'Test-VcpkgRoot'
)

$private:PublicFunctions = @(
    'Export-NhcVcpkgPort'
    'Install-NhcVcpkgPort'
    'Remove-NhcVcpkgPort'
)

$private:PublicVariables = @(
    'g_NhcVcpkgValidExportFormats'
)

# Legacy plural aliases retained for backward compatibility. The Set-Alias
# statements live in the corresponding Public function files.
$private:PublicAliases = @(
    'Export-NhcVcpkgPorts'
    'Install-NhcVcpkgPorts'
    'Remove-NhcVcpkgPorts'
)

$PrivateFunctions | ForEach-Object {
    $private:path = Join-Path -Path $Root -ChildPath 'Private' -AdditionalChildPath ("{0}.ps1" -f $_)
    . $path
}

$PublicFunctions | ForEach-Object {
    $private:path = Join-Path -Path $Root -ChildPath 'Public' -AdditionalChildPath ("{0}.ps1" -f $_)
    . $path
}

# Only export public functions:
Export-ModuleMember -Function $PublicFunctions
Export-ModuleMember -Variable $PublicVariables
Export-ModuleMember -Alias $PublicAliases
