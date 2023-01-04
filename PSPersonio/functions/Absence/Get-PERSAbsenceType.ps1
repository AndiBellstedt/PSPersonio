function Get-PERSAbsenceType {
    <#
    .Synopsis
        Get-PERSAbsenceType

    .DESCRIPTION
        Retrieve absence types from Personio

    .PARAMETER Name
        Name filter for absence types

    .PARAMETER Id
        Id filter for absence types

    .PARAMETER ResultSize
        How much records will be returned from the api.
        Default is 200.

        Use this parameter, when function throw information about pagination

    .PARAMETER Token
        AccessToken object for Personio service

    .EXAMPLE
        PS C:\> Get-PERSAbsenceType

        Get all available absence types

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [string[]]
        $Name,

        [int[]]
        $Id,

        [int]
        $ResultSize,

        [Personio.Core.AccessToken]
        $Token
    )

    begin {
    }

    process {
    }

    end {
        if (-not $Token) { $Token = $script:PersonioToken }

        # Prepare query
        $invokeParam = @{
            "Type"    = "GET"
            "ApiPath" = "company/time-off-types"
            "Token"   = $Token
        }
        if ($ResultSize) {
            $invokeParam.Add(
                "QueryParameter", @{
                    "limit"  = $ResultSize
                    "offset" = 0
                }
            )
        }

        # Execute query
        Write-PSFMessage -Level Verbose -Message "Getting available absence types" -Tag "AbsenseType", "Query"
        $response = Invoke-PERSRequest @invokeParam

        # Check respeonse
        if ($response.success) {
            # Check pagination / result limitation
            if ($response.metadata) {
                Write-PSFMessage -Level Significant -Message "Pagination detected! Retrieved records: $([Array]($responseContent.data).count) of $($responseContent.metadata.total_elements) total records (api call hast limit of $($responseContent.limit) records and started on record number $($responseContent.offset))" -Tag "WebRequest", "Pagination"
            }

            # Process result
            foreach ($record in $response.data) {
                #$result = $record.attributes
                #$result.psobject.TypeNames.Insert(0,"Personio.Absence.$($record.type)")
                #$result.psobject.typenames.Insert(0,"Personio.Absence.AbsenceType")

                # Create object
                $result = [Personio.Absence.AbsenceType]@{
                    BaseObject = $record.attributes
                    Id = $record.attributes.id
                }
                $result.psobject.TypeNames.Insert(1,"Personio.Absence.$($record.type)")

                # Output result object
                $result
            }
        } else {
            Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsenseType", "Query"
        }
    }
}
