function Get-PERSAbsence {
    <#
    .Synopsis
        Get-PERSAbsence

    .DESCRIPTION
        Retrieve absence periods from Personio tracked in days
        Parameters for filtered by period and/or specific employee(s) are available.

        The result can be paginated and.

    .PARAMETER InputObject
        AbsencePeriod to call again
        It is inclusive, so the result starts from and including the provided StartDate

    .PARAMETER StartDate
        First day of the period to be queried.
        It is inclusive, so the result starts from and including the provided StartDate

    .PARAMETER EndDate
        Last day of the period to be queried.
        It is inclusive, so the result ends on end_date including absences from the EndDate

    .PARAMETER UpdatedFrom
        Query the periods that created or modified from the date UpdatedFrom.
        It is inclusive, so all the periods created or modified from the beginning of the UpdatedFrom will be included in the results

    .PARAMETER UpdatedTo
        Query the periods that created or modified until the date UpdatedTo.
        It is inclusive, so all the periods created or modified until the end of the UpdatedTo will be included in the results

    .PARAMETER EmployeeId
        A list of Personio employee ID's to filter the results.
        The result filters including only absences of provided employees

    .PARAMETER ResultSize
        How much records will be returned from the api.
        Default is 200.

        Use this parameter, when function throw information about pagination

    .PARAMETER Token
        AccessToken object for Personio service

    .EXAMPLE
        PS C:\> Get-PERSAbsence

        Get all available absence periods
        (api-side-pagination will kick in at 200)

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(ParameterSetName = "Default")]
        [datetime]
        $StartDate,

        [Parameter(ParameterSetName = "Default")]
        [datetime]
        $EndDate,

        [Parameter(ParameterSetName = "Default")]
        [datetime]
        $UpdateFrom,

        [Parameter(ParameterSetName = "Default")]
        [datetime]
        $UpdateTo,

        [Parameter(
            ParameterSetName = "Default",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [int[]]
        $EmployeeId,

        [Parameter(ParameterSetName = "Default")]
        [ValidateNotNullOrEmpty()]
        [int]
        $ResultSize,

        [Parameter(
            ParameterSetName = "ByType",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Personio.Absence.AbsencePeriod[]]
        $InputObject,

        [ValidateNotNullOrEmpty()]
        [Personio.Core.AccessToken]
        $Token
    )

    begin {
        # define query parameters
        $queryParameter = [ordered]@{}

        # fill query parameters
        if ($ResultSize) {
            $queryParameter.Add("limit", $ResultSize)
            $queryParameter.Add("offset", 0)
        }
        if ($StartDate) { $queryParameter.Add("start_date", (Get-Date -Date $StartDate -Format "yyyy-MM-dd")) }
        if ($EndDate) { $queryParameter.Add("end_date", (Get-Date -Date $EndDate -Format "yyyy-MM-dd")) }
        if ($UpdateFrom) { $queryParameter.Add("updated_from", (Get-Date -Date $UpdateFrom -Format "yyyy-MM-dd")) }
        if ($UpdateTo) { $queryParameter.Add("updated_to", (Get-Date -Date $UpdateTo -Format "yyyy-MM-dd")) }
    }

    process {
        if (-not $Token) { $Token = $script:PersonioToken }

        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "AbsensePeriod"

        # fill pipedin query parameters
        if ($EmployeeId) {
            $queryParameter.Add("employees[]", [array]$EmployeeId)
        }

        # Prepare query
        $invokeParam = @{
            "Type"    = "GET"
            "ApiPath" = "company/time-offs"
            "Token"   = $Token
        }
        if ($queryParameter) { $invokeParam.Add("QueryParameter", $queryParameter) }

        # Execute query
        $responseList = [System.Collections.ArrayList]@()
        if ($parameterSetName -like "Default") {
            Write-PSFMessage -Level Verbose -Message "Getting available absence periods" -Tag "AbsensePeriod", "Query"

            $response = Invoke-PERSRequest @invokeParam

            # Check response and add to responseList
            if ($response.success) {
                $null = $responseList.Add($response)
            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsensePeriod", "Query"
            }
        } elseif ($parameterSetName -like "ByType") {
            foreach ($absencePeriod in $InputObject) {
                Write-PSFMessage -Level Verbose -Message "Getting absence period Id $($absencePeriod.Id)" -Tag "AbsensePeriod", "Query"

                $invokeParam.ApiPath = "company/time-offs/$($absencePeriod.Id)"
                $response = Invoke-PERSRequest @invokeParam

                # Check respeonse and add to responeList
                if ($response.success) {
                    $null = $responseList.Add($response)
                } else {
                    Write-PSFMessage -Level Warning -Message "Personio api reported no data on absence Id $($absencePeriod.Id)" -Tag "AbsensePeriod", "Query"
                }

                # remove token param for further api calls, due to the fact, that the passed in token, is no more valid after previous api all (api will use internal registered token)
                if ($InputObject.Count -gt 1) { $invokeParam.Remove("Token") }
            }
        }
        Remove-Variable -Name response -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore

        foreach ($response in $responseList) {
            # Check pagination / result limitation
            if ($response.metadata) {
                Write-PSFMessage -Level Significant -Message "Pagination detected! Retrieved records: $([Array]($response.data).count) of $($response.metadata.total_elements) total records (api call hast limit of $($response.limit) records and started on record number $($response.offset))" -Tag "AbsensePeriod", "Query", "WebRequest", "Pagination"
            }

            # Process result
            $output = [System.Collections.ArrayList]@()
            foreach ($record in $response.data) {
                Write-PSFMessage -Level Debug -Message "Working on record Id $($record.attributes.id) startDate: $($record.attributes.start_date) - endDate: $($record.attributes.end_date)" -Tag "AbsensePeriod", "ObjectCreation"

                # Create object
                $result = [Personio.Absence.AbsencePeriod]@{
                    BaseObject = $record.attributes
                    Id         = $record.attributes.id
                }
                $result.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.type)")

                $result.Employee = [Personio.Employee.BasicEmployee]@{
                    BaseObject = $record.attributes.employee.attributes
                    Id         = $record.attributes.employee.attributes.id.value
                    Name       = "$($record.attributes.employee.attributes.last_name.value), $($record.attributes.employee.attributes.first_name.value)"
                }
                $result.Employee.psobject.TypeNames.Insert(1, "Personio.Employee.$($record.attributes.employee.type)")

                $result.Type = [Personio.Absence.AbsenceType]@{
                    BaseObject = $record.attributes.time_off_type.attributes
                    Id         = $record.attributes.time_off_type.attributes.id
                    Name       = $record.attributes.time_off_type.attributes.name
                }
                $result.Type.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.attributes.time_off_type.type)")

                # add objects to output array
                $null = $output.Add($result)
            }
            Write-PSFMessage -Level Verbose -Message "Retrieve $($output.Count) objects of type [Personio.Absence.AbsencePeriod]" -Tag "AbsensePeriod", "Result"

            # Filtering
            #ToDo: Implement filtering for record output

            # output final results
            Write-PSFMessage -Level Verbose -Message "Output $($output.Count) objects" -Tag "AbsenseType", "Result", "Output"
            $output
        }

        # Cleanup variable
        Remove-Variable -Name Token -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
        $queryParameter.remove('employees[]')
    }

    end {
    }
}
