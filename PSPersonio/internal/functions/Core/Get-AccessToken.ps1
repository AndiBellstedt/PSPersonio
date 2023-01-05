function Get-AccessToken {
    <#
    .SYNOPSIS
        Get access token

    .DESCRIPTION
        Get currently registered access token

    .EXAMPLE
        PS C:\> Get-AccessToken

        Get currently registered access token
    #>
    [cmdletbinding(ConfirmImpact="Low")]
    param()

    Write-PSFMessage -Level System -Message "Retrieve token object Id '$($script:PersonioToken.TokenID)'" -Tag "AccessToken", "Get"
    $script:PersonioToken

}
