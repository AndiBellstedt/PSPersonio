@{
    # Script module or binary module file associated with this manifest
    RootModule        = 'PSPersonio.psm1'

    # Version number of this module.
    ModuleVersion     = '0.0.6'

    # ID used to uniquely identify this module
    GUID              = 'd12fa74a-f464-41fc-a4a6-2bf9d9f9c0fa'

    # Author of this module
    Author            = 'Andreas Bellstedt'

    # Company or vendor of this module
    CompanyName       = ''

    # Copyright statement for this module
    Copyright         = 'Copyright (c) 2023 Andreas Bellstedt'

    # Description of the functionality provided by this module
    Description       = 'PowerShell module for interacting with API of HR application Personio"'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules   = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '1.7.249' }
    )

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @('bin\PSPersonio.dll')

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @('xml\PSPersonio.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('xml\PSPersonio.Format.ps1xml')

    # Functions to export from this module
    FunctionsToExport = @(
        # Core
        'Connect-Personio',
        'Invoke-PersRequest',

        # Absence
        'Get-PERSAbsenceType',
        'Get-PERSAbsence',
        'New-PERSAbsence',
        'Remove-PERSAbsence',
        'Get-PERSAbsenceSummary',

        # Attendance
        'Get-PERSAttendance',

        # Employee
        'Get-PERSEmployee'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = ''

    # Variables to export from this module
    VariablesToExport = ''

    # Aliases to export from this module
    AliasesToExport   = ''

    # List of all modules packaged with this module
    ModuleList        = @()

    # List of all files packaged with this module
    FileList          = @()

    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        #Support for PowerShellGet galleries.
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @(
                "Personio", "API"
            )

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/AndiBellstedt/PSPersonio/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/AndiBellstedt/PSPersonio'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/AndiBellstedt/PSPersonio/blob/main/PSPersonio/changelog.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}