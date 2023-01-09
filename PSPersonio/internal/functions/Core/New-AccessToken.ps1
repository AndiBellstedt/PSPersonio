function New-AccessToken {
    <#
    .SYNOPSIS
        Create access token

    .DESCRIPTION
        Create access token

    .PARAMETER RawToken
        The RawToken data from personio service

    .EXAMPLE
        PS C:\> New-AccessToken -RawToken $rawToken

        Creates a Personio.Core.AccessToken from variable $rawToken
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
    [cmdletbinding(PositionalBinding = $true)]
    [OutputType([Personio.Core.AccessToken])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $RawToken
    )

    # Convert token to data object
    Write-PSFMessage -Level System -Message "Decode token data" -Tag "AccessToken", "Create"
    $tokenInfo = ConvertFrom-JWTtoken -Token $RawToken

    # Create output token
    Write-PSFMessage -Level System -Message "Creating Personio.Core.AccessToken object" -Tag "AccessToken", "Create"
    $token = [Personio.Core.AccessToken]@{
        TokenID              = $tokenInfo.JwtId
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
        TimeStampModified    = Get-Date
    }

    # Output object
    $token
}
