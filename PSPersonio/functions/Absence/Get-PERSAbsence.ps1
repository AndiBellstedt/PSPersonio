function Get-PERSAbsence {
    <#
    .Synopsis
        Get-PERSAbsence

    .DESCRIPTION
        Retrieve absence periods from Personio tracked in days
        Parameters for filtered by period and/or specific employee(s) are available.

        The result can be paginated and.

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
        DefaultParameterSetName="Default",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [datetime]
        $StartDate,

        [datetime]
        $EndDate,

        [datetime]
        $UpdateFrom,

        [datetime]
        $UpdateTo,

        [ValidateNotNullOrEmpty()]
        [int[]]
        $EmployeeId,

        [ValidateNotNullOrEmpty()]
        [int]
        $ResultSize,

        [ValidateNotNullOrEmpty()]
        [Personio.Core.AccessToken]
        $Token
    )

    begin {
        if (-not $Token) { $Token = $script:PersonioToken }

        # define query parameters
        $queryParameter = [ordered]@{}

        # fill query parameters
        if ($ResultSize) {
            $queryParameter.Add("limit", $ResultSize)
            $queryParameter.Add("offset", 0)
        }
        if($StartDate) { $queryParameter.Add("start_date", (Get-Date -Date $StartDate -Format "yyyy-MM-dd")) }
        if($EndDate) { $queryParameter.Add("end_date", (Get-Date -Date $EndDate -Format "yyyy-MM-dd")) }
        if($UpdateFrom) { $queryParameter.Add("updated_from", (Get-Date -Date $UpdateFrom -Format "yyyy-MM-dd")) }
        if($UpdateTo) { $queryParameter.Add("updated_to", (Get-Date -Date $UpdateTo -Format "yyyy-MM-dd")) }
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "AbsensePeriod"

        # fill pipedin query parameters
        foreach ($id in $EmployeeId) {
            $queryParameter.Add("employees[]",$id)
        }

        # Prepare query
        $invokeParam = @{
            "Type"    = "GET"
            "ApiPath" = "company/time-offs"
            "Token"   = $Token
        }
        if($queryParameter) { $invokeParam.Add("QueryParameter", $queryParameter) }

        # Execute query
        Write-PSFMessage -Level Verbose -Message "Getting available absence periods" -Tag "AbsensePeriod", "Query"
        $response = Invoke-PERSRequest @invokeParam

        # Check respeonse
        if ($response.success) {
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

                # add objects to output array
                $null = $output.Add($result)
            }
            Write-PSFMessage -Level Verbose -Message "Retrieve $($output.Count) objects of type [Personio.Absence.AbsencePeriod]" -Tag "AbsensePeriod", "Result"

            # Filtering

        } else {
            Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsensePeriod", "Query"
        }
    }

    end {
    }
}
