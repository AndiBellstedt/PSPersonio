function ConvertFrom-JWTtoken {
    <#
    .SYNOPSIS
        Converts access tokens to readable objects

    .DESCRIPTION
        Converts access tokens to readable objects

    .PARAMETER Token
        The Token to convert

    .EXAMPLE
        PS C:\> ConvertFrom-JWTtoken -Token $Token

        Converts the content from variable $token to an object
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Token
    )

    # Validate as per https://tools.ietf.org/html/rfc7519 - Access and ID tokens are fine, Refresh tokens will not work
    if ((-not $Token.Contains(".")) -or (-not $Token.StartsWith("eyJ"))) {
        $msg = "Invalid data or not an access token. $($Token)"
        Stop-PSFFunction -Message $msg -Tag "JWT" -EnableException $true -Exception ([System.Management.Automation.RuntimeException]::new($msg))
    }

    # Split the token in its parts
    $tokenParts = $Token.Split(".")

    # Work on header
    $tokenHeader = [System.Text.Encoding]::UTF8.GetString( (ConvertFrom-Base64StringWithNoPadding $tokenParts[0]) )
    $tokenHeaderJSON = $tokenHeader | ConvertFrom-Json

    # Work on payload
    $tokenPayload = [System.Text.Encoding]::UTF8.GetString( (ConvertFrom-Base64StringWithNoPadding $tokenParts[1]) )
    $tokenPayloadJSON = $tokenPayload | ConvertFrom-Json

    # Work on signature
    $tokenSignature = ConvertFrom-Base64StringWithNoPadding $tokenParts[2]

    # Output
    $resultObject = [PSCustomObject]@{
        "Header"       = $tokenHeader
        "Payload"      = $tokenPayload
        "Signature"    = $tokenSignature

        "Algorithm"    = $tokenHeaderJSON.alg
        "Type"         = $tokenHeaderJSON.typ

        "JwtId"        = [guid]::Parse($tokenPayloadJSON.jti)
        "Issuer"       = $tokenPayloadJSON.iss
        "Scope"        = $tokenPayloadJSON.scope

        "IssuedUTC"    = ([datetime]"1970-01-01Z00:00:00").AddSeconds($tokenPayloadJSON.iat).ToUniversalTime()
        "ExpiresUTC"   = ([datetime]"1970-01-01Z00:00:00").AddSeconds($tokenPayloadJSON.exp).ToUniversalTime()
        "NotBeforeUTC" = ([datetime]"1970-01-01Z00:00:00").AddSeconds($tokenPayloadJSON.nbf).ToUniversalTime()

        "ClientId"     = $tokenPayloadJSON.sub
        "Prv"          = $tokenPayloadJSON.prv
    }

    #$output
    $resultObject
}
