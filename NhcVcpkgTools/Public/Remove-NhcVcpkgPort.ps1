Set-StrictMode -Version 3.0

function Remove-NhcVcpkgPort {
    <#
    .SYNOPSIS
    Removes installed vcpkg ports.

    .DESCRIPTION
    This function wraps the 'vcpkg remove' command to provide consistent parameter handling
    and PowerShell integration with ShouldProcess support.

    .PARAMETER Ports
    Removes only the specified ports. Cannot be combined with Outdated.

    .PARAMETER Outdated
    Removes all outdated ports. Cannot be combined with Ports.

    .PARAMETER Recurse
    Removes packages that depend on the specified packages.

    .PARAMETER Command
    Specifies the path to the vcpkg executable to call.

    .PARAMETER RootDir
    Specifies the <vcpkg-root> to use. If not passed, <vcpkg-root> is detected from either Command or $env:VCPKG_ROOT.

    .PARAMETER Triplet
    Specifies the target triplet.

    .PARAMETER OverlayPorts
    Specifies overlay ports paths.

    .PARAMETER OverlayTriplets
    Specifies overlay triplets paths.

    .PARAMETER InstallDir
    Specifies where ports are installed. Defaults to <vcpkg-root>/installed.

    .PARAMETER Quiet
    Suppresses all output from the vcpkg command, including errors.

    .PARAMETER Force
    Suppresses confirmation prompts unless -Confirm is explicitly specified.

    .EXAMPLE
    Remove-NhcVcpkgPort -Ports 'zlib', 'fmt'
    Removes the specified ports.

    .EXAMPLE
    Remove-NhcVcpkgPort -Outdated
    Removes all outdated ports.

    .EXAMPLE
    Remove-NhcVcpkgPort -Ports 'zlib' -Recurse -WhatIf
    Shows what would be removed including dependencies without actually removing.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Ports', SupportsShouldProcess = $true)]
    [OutputType([hashtable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'The WhatIf preview must always reach the console; Write-Information is silent by default.')]
    param(
        [Parameter(ParameterSetName = 'Ports')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Ports,

        [Parameter(ParameterSetName = 'Outdated')]
        [switch]$Outdated,

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [string]$Command,

        [Parameter()]
        [string]$RootDir,

        [Parameter()]
        [string]$Triplet,

        [Parameter()]
        [string[]]$OverlayPorts,

        [Parameter()]
        [string[]]$OverlayTriplets,

        [Parameter()]
        [string]$InstallDir,

        [Parameter()]
        [switch]$Quiet,

        [Parameter()]
        [switch]$Force
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }

        if ($Force -and -not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = 'None'
        }
    }

    process {
        # Directory arguments required by vcpkg remove:
        $private:required = @( 'InstallDir' )

        # Build the common vcpkg arguments list:
        $private:config = @{}
        $config += Get-CommonArgument -Parameters $PSBoundParameters -Directories $required

        $private:exe = $config.Command
        $private:verb = 'remove'

        $private:params = @()
        $params += $verb
        $params += $config.Arguments

        $private:target = $config.InstallDir.Path
        Write-Verbose "Removing ports from '$target'"

        if ($PSCmdlet.ShouldProcess($target, 'vcpkg remove')) {
            Write-Verbose "Executing '$exe $params'"
        }
        else {
            Write-Host "Whatif: Would execute '$exe $params'"
            $params += '--dry-run'
        }

        # Execute vcpkg
        $config.Status = Invoke-Vcpkg -Command $exe -Arguments $params -Quiet:$Quiet

        return $config
    }
}

Set-Alias -Name Remove-NhcVcpkgPorts -Value Remove-NhcVcpkgPort
