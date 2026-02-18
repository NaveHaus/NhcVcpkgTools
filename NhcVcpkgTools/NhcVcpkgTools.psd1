# Module manifest for module 'NhcVcpkgTools'
@{
    RootModule           = 'NhcVcpkgTools.psm1'
    ModuleVersion        = '0.1.0'
    CompatiblePSEditions = @( 'Core' )
    GUID                 = 'dedcb851-3924-4abc-8013-c2e895685ca5'
    Author               = 'Demian M. Nave'
    CompanyName          = 'NaveHaus Consulting LLC'
    Copyright            = '(c) NaveHaus Consulting LLC.'
    Description          = 'Tools for working with vcpkg from PowerShell.'
    PowerShellVersion    = '7.2'
    RequiredModules      = @()
    AliasesToExport      = @()
    FunctionsToExport    = @(
        'Export-NhcVcpkgPorts'
        'Install-NhcVcpkgPorts'
    )

    VariablesToExport    = @(
        'g_NhcVcpkgValidExportFormats'
    )

    PrivateData          = @{
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/NaveHaus/NhcVcpkgTools/blob/master/LICENSE'

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable
    } # End of PrivateData hashtable
}