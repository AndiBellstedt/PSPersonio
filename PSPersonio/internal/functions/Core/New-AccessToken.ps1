function New-AccessToken {
    <#
    .SYNOPSIS
        Create access token

    .DESCRIPTION
        Create access token

    .PARAMETER RawToken
        The RawToken data from personio service

    .PARAMETER ClientId
        The "UserName" of the API Token from personio service is used as "ClientId" within the service

    .EXAMPLE
        PS C:\> New-AccessToken -RawToken $rawToken -ClientId $ClientId

        Creates a Personio.Core.AccessToken from variable $rawToken
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [cmdletbinding(PositionalBinding = $true)]
    [OutputType([Personio.Core.AccessToken])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $RawToken,

        [String]
        $ClientId
    )

    $_date = Get-Date

    # Convert token to data object
    if ($RawToken.Contains(".") -and $RawToken.StartsWith("eyJ")) {
        # When API service give a JWT Token object
        Write-PSFMessage -Level System -Message "Decode token data" -Tag "AccessToken", "Create"
        $tokenInfo = ConvertFrom-JWTtoken -Token $RawToken
    } else {
        # Starting on June 2023 personio decides to step away from JWT tokens and began to invent a not parseable, service specific format
        $tokenInfo = [PSCustomObject]@{
            Id                   = (New-Guid)
            ClientId             = $ClientId
            ApplicationId        = $applicationIdentifier
            ApplicationPartnerId = $partnerIdentifier
            Issuer               = "$(Get-PSFConfigValue -FullName 'PSPersonio.API.URI' -Fallback '')"
            Scope                = @("PAPI", "Personio.API.Service")
            Token                = ($RawToken | ConvertTo-SecureString -AsPlainText -Force)
            ApiUri               = "$(Get-PSFConfigValue -FullName 'PSPersonio.API.URI' -Fallback '')"
            IssuedUTC            = $_date
            NotBeforeUTC         = $_date
            ExpiresUTC           = $_date.AddHours(24)
        }
    }

    # Create output token
    Write-PSFMessage -Level System -Message "Creating Personio.Core.AccessToken object" -Tag "AccessToken", "Create"
    $token = [Personio.Core.AccessToken]@{
        TokenID              = $tokenInfo.Id
        ClientId             = $tokenInfo.ClientId
        ApplicationId        = $applicationIdentifier
        ApplicationPartnerId = $partnerIdentifier
        Issuer               = $tokenInfo.Issuer
        Scope                = $tokenInfo.Scope
        Token                = ($RawToken | ConvertTo-SecureString -AsPlainText -Force)
        ApiUri               = "$(Get-PSFConfigValue -FullName 'PSPersonio.API.URI' -Fallback $tokenInfo.Issuer)"
        TimeStampCreated     = $tokenInfo.IssuedUTC.ToLocalTime()
        TimeStampNotBefore   = $tokenInfo.NotBeforeUTC.ToLocalTime()
        TimeStampExpires     = $tokenInfo.ExpiresUTC.ToLocalTime()
        TimeStampModified    = $_date.ToLocalTime()
    }

    # Output object
    $token
}
