function Connect-Personio {
    <#
    .Synopsis
        Connect-Personio

    .DESCRIPTION
        Connect to Personio Service

    .PARAMETER Credential
        The access token as a credential object to login
        This is the recommended way to use the function, due to security reason.

        Username has to be the Client_ID from api access manament of Personio
        Password has to be the Client_Secret from api access manament of Personio

    .PARAMETER ClientId
        The Client_ID from api access manament of Personio

        Even if prodived as a logon method, due to best practices and security reason, you should consider to use the Credential parameter to connect!

    .PARAMETER ClientSecret
        The Client_Secret from api access manament of Personio

        Even if prodived as a logon method, due to best practices and security reason, you should consider to use the Credential parameter to connect!

    .PARAMETER URL
        Name of the service to connect to.
        Default is 'https://api.personio.de' as predefined value, but you can -for whatever reason- change the uri if needed.

    .PARAMETER APIVersion
        Version of API endpoint to use
        Default is 'V1'

    .PARAMETER PassThru
        Outputs the token to the console

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Connect-Personio -Credential (Get-Credential "ClientID")

        Connects to "api.personio.de" with the specified credentials.
        Connection will be set as default connection for any further action.

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(
        DefaultParameterSetName = 'Credential',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Credential'
        )]
        [Alias("Token", "AccessToken", "APIToken")]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'PlainText'
        )]
        [Alias("Id")]
        [string]
        $ClientId,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'PlainText'
        )]
        [Alias("Secret")]
        [string]
        $ClientSecret,

        [ValidateNotNullOrEmpty()]
        [Alias("ComputerName", "Hostname", "Host", "ServerName")]
        [uri]
        $URL = 'https://api.personio.de',

        [ValidateNotNullOrEmpty()]
        [Alias("Version")]
        [string]
        $APIVersion = "v1",

        [switch]
        $PassThru
    )

    begin {
    }

    process {
    }

    end {
        # Variable preperation
        [uri]$uri = $URL.AbsoluteUri + $APIVersion.Trim('/')

        [string]$applicationIdentifier = Get-PSFConfigValue -FullName 'PSPersonio.WebClient.ApplicationIdentifier' -Fallback "PSPersonio"
        [string]$partnerIdentifier = Get-PSFConfigValue -FullName 'PSPersonio.WebClient.PartnerIdentifier' -Fallback ""

        # Security checks
        if ($PsCmdlet.ParameterSetName -eq 'PlainText') {
            Write-PSFMessage -Level Warning -Message "You use potential unsecure login method! Even if prodived as a logon method, due to best practices and security reason, you should consider to use the Credential parameter to connect. Please take care about security and try to avoid plain text credentials." -Tag "Connection", "New", "Security", "PlainText"
        }

        # Extrect credential
        if ($PsCmdlet.ParameterSetName -eq 'Credential') {
            [string]$ClientId = $Credential.UserName
            [string]$ClientSecret = $Credential.GetNetworkCredential().Password
        }

        # Invoke authentication
        Write-PSFMessage -Level Verbose -Message "Authenticate '$($ClientId)' as application '$($applicationIdentifier)' to service '$($uri.AbsoluteUri)'" -Tag "Connection", "Authentication", "New"
        $paramRestMethod = @{
            "Uri"           = "$($uri.AbsoluteUri)/auth?client_id=$($ClientId)&client_secret=$($ClientSecret)"
            "Headers"       = @{
                "X-Personio-Partner-ID" = $partnerIdentifier
                "X-Personio-App-ID"     = $applicationIdentifier
                "accept"                = "application/json"
            }
            "Method"        = "POST"
            "Verbose"       = $false
            "Debug"         = $false
            "ErrorAction"   = "Stop"
            "ErrorVariable" = "invokeError"
        }
        try {
            $response = Invoke-RestMethod @paramRestMethod
        } catch {
            Stop-PSFFunction -Message "Error invoking rest call on service '$($uri.AbsoluteUri)'. $($invokeError)" -Tag "Connection", "Authentication", "New" -EnableException $true -Cmdlet $pscmdlet
        }

        # Check response
        if ($response.success -notlike "True") {
            Stop-PSFFunction -Message "Service '$($uri.AbsoluteUri)' processes the authentication request, but response does not succeed" -Tag "Connection", "Authentication", "New" -EnableException $true -Cmdlet $pscmdlet
        } elseif (-not $response.data.token) {
            Stop-PSFFunction -Message "Something went wrong on authenticating user '$($ClientId)'. No token found in authentication respeonse. Unable login to service '$($uri.AbsoluteUri)'" -Tag "Connection", "Authentication", "New" -EnableException $true -Cmdlet $pscmdlet
        } else {
            Set-PSFConfig -Module 'PSPersonio' -Name 'API.URI' -Value $uri.AbsoluteUri
        }

        # Create output token
        Write-PSFMessage -Level Verbose -Message "Set Personio.Core.AccessToken" -Tag "Connection", "AccessToken", "New"
        $token = New-AccessToken -RawToken $response.data.token

        # Register AccessToken for further commands
        Register-AccessToken -Token $token
        Write-PSFMessage -Level Significant -Message "Connected to service '($($token.ApiUri))' with ClientId '$($token.ClientId)'. TokenId: $($token.TokenID) valid for $($token.AccessTokenLifeTime.toString())" -Tag "Connection"

        # Output if passthru
        if ($PassThru) {
            Write-PSFMessage -Level Verbose -Message "Output Personio.Core.AccessToken to console" -Tag "Connection", "AccessToken", "New"
            $token
        }

        # Cleanup
        Clear-Variable -Name paramRestMethod, uri, applicationIdentifier, partnerIdentifier, ClientId, ClientSecret, Credential, response, token -Force -WhatIf:$false -Confirm:$false -Debug:$false -Verbose:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
    }
}
