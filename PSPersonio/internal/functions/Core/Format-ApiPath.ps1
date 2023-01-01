function Format-ApiPath {
    <#
    .Synopsis
        Format-ApiPath

    .DESCRIPTION
        Ensure the right format of api path uri

    .PARAMETER Path
        Path to format

    .EXAMPLE
        Format-ApiPath -Path $ApiPath

        Api path data from variable $ApiPath will be tested and formatted.

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Personio.Core.AccessToken]
        $Token
    )

    if (-not $Token) { $Token = $script:PersonioToken }

    Write-PSFMessage -Level System -Message "Formatting API path '$($Path)'"

    # Remove no more need slashes
    $apiPath = $Path.Trim('/')

    # check on API path prefix
    if (-not $ApiPath.StartsWith($token.ApiUri)) {
        $apiPath = $token.ApiUri.Trim('/') + "/" + $apiPath
        Write-PSFMessage -Level System -Message "Add API prefix, finished formatting path to '$($apiPath)'"
    } else {
        Write-PSFMessage -Level System -Message "Prefix API path already present, finished formatting"
    }

    # Output Result
    $apiPath
}
