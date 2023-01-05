function Invoke-PERSRequest {
    <#
    .Synopsis
        Invoke-PersRequest

    .DESCRIPTION
        Basic function to invoke a API request to Personio service

        The function returns "raw data" from the API as a PSCustomObject.
        Titerally the function is a basic function within the core of the module.
        Most of the other functions, rely on Invoke-PresRequest to provide convenient data and functionality.

    .PARAMETER Type
        Type of web request

    .PARAMETER ApiPath
        Uri path for the REST call in the API

    .PARAMETER QueryParameter
        A hashtable for all the parameters to the api route

    .PARAMETER Body
        The body as a hashtable for the request

    .PARAMETER Token
        The TANSS.Connection token

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Invoke-PersRequest -Type GET -ApiPath "company/employees"

        Invoke a request to API route 'company/employees' as a GET call

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]
        $Type,

        [Parameter(Mandatory = $true)]
        [string]
        $ApiPath,

        [hashtable]
        $QueryParameter,

        [hashtable]
        $Body,

        [Personio.Core.AccessToken]
        $Token
    )

    begin {
    }

    process {
    }

    end {
        #region Perpare variables
        # Check AccessToken
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }
        if (-not $Token) { Stop-PSFFunction -Message "No AccessToken found. Please connect to personio service frist. Use Connect-Personio command." -Tag "Connection", "MissingToken" -EnableException $true -Cmdlet $pscmdlet }
        if ($Token.IsValid) {
            Write-PSFMessage -Level System -Message "Valid AccessTokenId '$($Token.TokenID.ToString())' for service '$($Token.ApiUri)'."
        } else {
            Stop-PSFFunction -Message "AccessTokenId '$($Token.TokenID.ToString())' is not valid. Please reconnect to personio service. Use Connect-Personio command." -Tag "Connection", "InvalidToken" -EnableException $true -Cmdlet $pscmdlet
        }

        # Get AppIds
        [string]$applicationIdentifier = Get-PSFConfigValue -FullName 'PSPersonio.WebClient.ApplicationIdentifier' -Fallback "PSPersonio"
        [string]$partnerIdentifier = Get-PSFConfigValue -FullName 'PSPersonio.WebClient.PartnerIdentifier' -Fallback ""

        # Format api path / api route to call
        $ApiPath = Format-ApiPath -Path $ApiPath -Token $Token -QueryParameter $QueryParameter

        # Format body
        if ($Body) {
            $bodyData = $Body | ConvertTo-Json
        } else {
            $bodyData = $null
        }

        # Format request header
        $header = @{
            "Authorization"         = "Bearer $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.Token)))"
            "X-Personio-Partner-ID" = $partnerIdentifier
            "X-Personio-App-ID"     = $applicationIdentifier
        }

        #endregion Perpare variables

        # Invoke the api request to the personio service
        $paramInvoke = @{
            "Uri"           = "$($ApiPath)"
            "Headers"       = $header
            "Body"          = $bodyData
            "Method"        = $Type
            "ContentType"   = 'application/json; charset=UTF-8'
            "Verbose"       = $false
            "Debug"         = $false
            "ErrorAction"   = "Stop"
            "ErrorVariable" = "invokeError"
        }

        if ($pscmdlet.ShouldProcess("$($Type) web REST call against URL '$($paramInvoke.Uri)'", "Invoke")) {
            Write-PSFMessage -Level Verbose -Message "Invoke $($Type) web REST call against URL '$($paramInvoke.Uri)'" -Tag "WebRequest"

            try {
                $response = Invoke-WebRequest @paramInvoke -UseBasicParsing
                $responseContent = $response.Content | ConvertFrom-Json
                Write-PSFMessage -Level System -Message "API Response: $($responseContent.success)"
            } catch {
                Write-PSFMessage -Level Error -Message "$($invokeError.Message) (StatusDescription:$($invokeError.ErrorRecord.Exception.Response.StatusDescription), Uri:$($ApiPath))" -Exception $invokeError.ErrorRecord.Exception -Tag "WebRequest", "Error", "API failure" -EnableException $true -PSCmdlet $pscmdlet
                return
            }

            # Create updated AccesToken from response. Every token can be used once and every api call will offer a new token
            Write-PSFMessage -Level System -Message "Update Personio.Core.AccessToken" -Tag "Connection", "AccessToken", "Update"
            $token = New-AccessToken -RawToken $response.Headers['authorization'].Split(" ")[1]

            # Register updated AccessToken for further commands
            Register-AccessToken -Token $token
            Write-PSFMessage -Level Verbose -Message "Update AccessToken to Id '$($token.TokenID)'. Now valid up to $($token.TimeStampExpires.toString())" -Tag "Connection", "AccessToken", "Update"

            # Check pagination
            if($responseContent.metadata) {
                Write-PSFMessage -Level VeryVerbose -Message "Pagination detected! Retrieved records: $([Array]($responseContent.data).count) of $($responseContent.metadata.total_elements) total records (api call hast limit of $($responseContent.limit) records and started on record number $($responseContent.offset))" -Tag "WebRequest", "Pagination"
            }

            # Output data
            $responseContent
        }

    }
}