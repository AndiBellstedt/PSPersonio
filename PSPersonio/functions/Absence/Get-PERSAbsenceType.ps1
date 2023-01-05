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

    .EXAMPLE
        PS C:\> Get-PERSAbsenceType -Name "Krankheit*"

        Get all available absence types with name "Krankheit*"

    .EXAMPLE
        PS C:\> Get-PERSAbsenceType -Id 10

        Get absence types with id 10

    .EXAMPLE
        PS C:\> Get-PERSAbsenceType -Id 10, 11, 12 -Name "*Krankheit*"

        Get absence types with id 10, 11, 12 as long, as name matches *Krankheit*

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
                Write-PSFMessage -Level Significant -Message "Pagination detected! Retrieved records: $([Array]($response.data).count) of $($response.metadata.total_elements) total records (api call hast limit of $($response.limit) records and started on record number $($response.offset))" -Tag "AbsenseType", "Query", "WebRequest", "Pagination"
            }


            # Process result
            $output = [System.Collections.ArrayList]@()
            foreach ($record in $response.data) {
                Write-PSFMessage -Level Debug -Message "Working on record $($record.attributes.name) (ID: $($record.attributes.id))" -Tag "AbsenseType", "ObjectCreation"

                # Create object
                $result = [Personio.Absence.AbsenceType]@{
                    BaseObject = $record.attributes
                    Id         = $record.attributes.id
                    Name       = $record.attributes.name
                }
                $result.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.type)")

                # add objects to output array
                $null = $output.Add($result)
            }
            Write-PSFMessage -Level Verbose -Message "Retrieve $($output.Count) objects of type [Personio.Absence.AbsenceType]" -Tag "AbsenseType", "Result"


            # Filtering
            if ($Name -and $output) {
                Write-PSFMessage -Level Verbose -Message "Filter by Name: $([string]::Join(", ", $Name))" -Tag "AbsenseType", "Filtering", "NameFilter"

                $newOutput = [System.Collections.ArrayList]@()
                foreach ($item in $output) {
                    foreach ($filter in $Name) {
                        $filterResult = $item | Where-Object Name -like $filter
                        if ($filterResult) { $null = $newOutput.Add($filterResult) }
                    }
                }

                $Output = $newOutput
                Remove-Variable -Name newOutput, filter, filterResult, item -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
            }

            if ($Id -and $output) {
                Write-PSFMessage -Level Verbose -Message "Filter by Id: $([string]::Join(", ", $Id))" -Tag "AbsenseType", "Filtering", "IdFilter"
                $output = $output | Where-Object Id -in $Id
            }


            # output final results
            Write-PSFMessage -Level Verbose -Message "Output $($output.Count) objects" -Tag "AbsenseType", "Result", "Output"
            $output

        } else {
            Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsenseType", "Query"
        }
    }
}
