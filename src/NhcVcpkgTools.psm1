# Explicitly load required functions:
$private:Root = $PSScriptRoot

$private:PrivateFunctions = @(
    'Get-CommonArguments'
    'Get-DefaultTriplet'
    'Get-Executable'
    'Get-TaggedOutputDir'
    'Join-RelativePath'
    'Test-AbsolutePath'
    'Test-FileNameString'
    'Test-Executable'
    'Test-PathString'
    'Test-VcpkgRoot'
)

$private:PublicFunctions = @(
    'Export-NhcVcpkgPorts'
    'Install-NhcVcpkgPorts'
)

$PrivateFunctions | ForEach-Object {
    $private:path = Join-Path -Path $Root -ChildPath 'private' -AdditionalChildPath ("{0}.ps1" -f $_)
    . $path
}

$PublicFunctions | ForEach-Object {
    $private:path = Join-Path -Path $Root -ChildPath 'public' -AdditionalChildPath ("{0}.ps1" -f $_)
    . $path
}

# Only export public functions:
Export-ModuleMember -Function $PublicFunctions