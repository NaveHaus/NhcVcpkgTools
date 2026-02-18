Set-StrictMode -Version 3.0

function Get-BinaryType {
    <#
    .SYNOPSIS
        Gets the binary executable type for a file.
    .DESCRIPTION
        PowerShell wrapper around the GetBinaryType Windows API that inspects the file header
        and reports the binary file type (e.g., 32-bit Windows app, 64-bit Windows app,
        16-bit DOS/Windows app, etc.).
    .PARAMETER Path
        Path to inspect.
    .EXAMPLE
        # Reports the file type of C:\Windows\Explorer.exe:
        Get-BinaryType C:\Windows\Explorer.exe
    .NOTES
        Author:      Battleship, Aaron Margosis
        Inspiration: http://pinvoke.net/default.aspx/kernel32/GetBinaryType.html
        Modified:    Demian Nave: simplify parameters, fix minor errors, normalize variable names, clean up outputs.
    .LINK
        http://wonkysoftware.appspot.com
    #>

    [CmdletBinding(ConfirmImpact = 'none')]
    param
    (
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]  $Path
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }

        try {
            # Add the enum for the binary types
            # Using more user friendly names since they won't likely be used outside this context
            $private:enum = @'
            public enum BinaryType
            {
                NONE  = -1, // Not an executable type.
                BIT32 = 0,  // A 32-bit Windows-based application,                       SCS_32BIT_BINARY
                DOS   = 1,  // An MS-DOS - based application,                            SCS_DOS_BINARY
                WOW   = 2,  // A 16-bit Windows-based application,                       SCS_WOW_BINARY
                PIF   = 3,  // A PIF file that executes an MS-DOS based application,     SCS_PIF_BINARY
                POSIX = 4,  // A POSIX based application,                                SCS_POSIX_BINARY
                OS216 = 5,  // A 16-bit OS/2-based application,                          SCS_OS216_BINARY
                BIT64 = 6   // A 64-bit Windows-based application,                       SCS_64BIT_BINARY
            }
'@

            Add-Type -TypeDefinition $enum -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose -Message '[enum] BinaryType already defined'
        }

        try {
            # create the win32 signature
            $private:funcsig = @'
          [DllImport("kernel32.dll")]
          public static extern bool GetBinaryType(
                              string lpApplicationName,
                              ref int lpBinaryType
          );
'@

            # Create a new type that lets us access the Windows API function
            Add-Type -MemberDefinition $funcsig -Name BinaryType -Namespace PFWin32Utils -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose -message 'GetBinaryType() already defined'
        } #type already been loaded, do nothing
    }

    process {
        $private:full = Resolve-Path -Path $Path -Force -ErrorAction Ignore
        $private:type = -1
        [PFWin32Utils.BinaryType]::GetBinaryType($full, [ref] $type) | Out-Null
        return [BinaryType] $type
    }
}