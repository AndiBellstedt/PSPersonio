function ConvertTo-CamelCaseString {
    <#
    .SYNOPSIS
        ConvertTo-CamelCaseString

    .DESCRIPTION
        Convert a series of strings to Uppercase first strings and concatinate together as a final 'camelcased' string

    .PARAMETER InputObject
        String(s) to convert

    .EXAMPLE
        PS C:\> ConvertTo-CamelCaseString "my", "foo", "string"

        Return "MyFooString"
    #>
    [CmdletBinding(
        PositionalBinding=$true,
        SupportsShouldProcess=$false,
        ConfirmImpact="Low"
    )]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [string[]]
        $InputObject
    )

    begin {
        $collection = [System.Collections.ArrayList]@()
    }

    process {
        foreach ($string in $InputObject) {

            $firstPart = $string.Substring(0,1).ToUpper()

            if($string.Length -gt 1) {
                $secondPart = $string.Substring(1, ($string.Length-1)).ToLower()
            }

            $null = $collection.Add( "$($firstPart)$($secondPart)" )
        }
    }

    end {
        [String]::Join('', ($collection | ForEach-Object { $_ }))
    }
}