BeforeAll {
    $script:sourceRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\..\NhcVcpkgTools' | Convert-Path

    # Import from source in a child process so the module already loaded in this
    # session (built or source) is left untouched.
    $probe = {
        param($ModulePath)
        $module = Import-Module -Name $ModulePath -Force -PassThru -ErrorAction Stop
        [pscustomobject]@{
            ModuleBase        = $module.ModuleBase
            Functions         = @(& $module { Get-Command -Module $args[0] -CommandType Function } $module.Name | ForEach-Object Name)
            ExportedFunctions = @($module.ExportedFunctions.Keys)
            ExportedAliases   = @($module.ExportedAliases.Keys)
        }
    }
    $script:sourceModule = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -Command $probe -args $script:sourceRoot
}

Describe 'Source-mode import' {
    # Discovery-time: names of the top-level functions defined by the scripts in
    # each source folder. Scripts that define no function (such as the module
    # header) contribute none.
    $sourceRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\..\NhcVcpkgTools' | Convert-Path
    $getDefinedFunctions = {
        param($Folder)
        Get-ChildItem -Path (Join-Path $sourceRoot $Folder) -Filter '*.ps1' -File | ForEach-Object {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
            $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object Name
        }
    }
    $publicNames = @(& $getDefinedFunctions 'Public')
    $privateNames = @(& $getDefinedFunctions 'Private')

    It 'imports the module from the source tree' {
        $script:sourceModule.ModuleBase | Should -Be $script:sourceRoot
    }

    It 'provides private function <_> in module scope' -ForEach $privateNames {
        $script:sourceModule.Functions | Should -Contain $_ -Because 'NhcVcpkgTools.psm1 must load every private function'
    }

    It 'provides public function <_> in module scope' -ForEach $publicNames {
        $script:sourceModule.Functions | Should -Contain $_ -Because 'NhcVcpkgTools.psm1 must load every public function'
    }

    It 'exports only the public functions' -TestCases @(@{ PublicNames = $publicNames }) {
        @($script:sourceModule.ExportedFunctions | Sort-Object) | Should -Be @($PublicNames | Sort-Object)
    }

    It 'exports only the legacy plural aliases of the public functions' -TestCases @(@{ PublicNames = $publicNames }) {
        @($script:sourceModule.ExportedAliases | Sort-Object) | Should -Be @($PublicNames | ForEach-Object { "${_}s" } | Sort-Object)
    }
}
