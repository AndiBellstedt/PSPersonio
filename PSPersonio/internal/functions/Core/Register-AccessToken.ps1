function Register-AccessToken {
    <#
    .SYNOPSIS
        Register access token

    .DESCRIPTION
        Register access token within the module

    .PARAMETER Token
        The Token object to register

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Register-AccessToken -Token $token

        Register the Personio.Core.AccessToken from variable $rawToken to module wide vaiable $PersonioToken
    #>
    [cmdletbinding(
        PositionalBinding=$true,
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [Personio.Core.AccessToken]
        $Token
    )

    # check if $PersonioToken already has data
    if($PersonioToken.TokenID) {
        Write-PSFMessage -Level System -Message "Replacing existing token object with Id '$($PersonioToken.TokenID)' with new token '$($Token.TokenID)' (valid until $($Token.TimeStampExpires))" -Tag "AccessToken", "Register"
    } else {
        Write-PSFMessage -Level System -Message "Register token '$($Token.TokenID)' (valid until $($Token.TimeStampExpires))" -Tag "AccessToken", "Register"
    }

    # register token
    if ($pscmdlet.ShouldProcess("AccessToken for ClientId '$($Token.ClientId)' from '$($Token.Issuer)' valid until $($Token.TimeStampExpires)", "Register")) {
        $script:PersonioToken = $Token
    }
}
