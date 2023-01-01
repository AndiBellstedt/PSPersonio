<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'PSPersonio' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

#region Module configurations
Set-PSFConfig -Module 'PSPersonio' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'PSPersonio' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -Module 'PSPersonio' -Name 'WebClient.PartnerIdentifier' -Value "" -Initialize -Validation 'string' -Description "WebRequest header value - X-Personio-Partner-ID: The partner identifier"
Set-PSFConfig -Module 'PSPersonio' -Name 'WebClient.ApplicationIdentifier' -Value "PSPersonio" -Initialize -Validation 'string' -Description "WebRequest header value - X-Personio-App-ID: The application identifier that integrates with Personio"

Set-PSFConfig -Module 'PSPersonio' -Name 'API.URI' -Value "" -Initialize -Validation 'string' -Description "Base URI for API requests"
#endregion Module configurations



#region Module variables
New-Variable -Name PersonioToken -Scope Script -Visibility Public -Description "Variable for registered access token. This is for convinience use with the commands in the module" -Force

#endregion Module variables
