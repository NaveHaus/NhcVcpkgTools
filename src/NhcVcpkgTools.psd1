# Module manifest for module 'NhcVcpkgTools'
@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'NhcVcpkgTools.psm1'

    # Version number of this module.
    ModuleVersion        = '0.1.0'

    # Supported PSEditions
    CompatiblePSEditions = @( 'Core' )

    # ID used to uniquely identify this module
    GUID                 = 'dedcb851-3924-4abc-8013-c2e895685ca5'

    # Author of this module
    Author               = 'Demian M. Nave'

    # Company or vendor of this module
    CompanyName          = 'NaveHaus Consulting LLC'

    # Copyright statement for this module
    Copyright            = '(c) NaveHaus Consulting LLC. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Tools for working with vcpkg from PowerShell.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.2'

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(
        'Export-NhcVcpkgPorts'
        'Install-NhcVcpkgPorts'
    )

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

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