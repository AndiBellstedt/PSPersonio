function Get-PERSAttendance {
    <#
    .Synopsis
        Get-PERSAttendance

    .DESCRIPTION
        Retrieve attendance data for the company employees

        Parameters for filtered by period and/or specific employee(s) are available
        The result can be paginated

    .PARAMETER StartDate
        First day to be queried

    .PARAMETER EndDate
        Last day to be queried

    .PARAMETER UpdatedFrom
        Query the periods that created or modified from the updated date

    .PARAMETER UpdatedTo
        Query the periods that created or modified until the updated date

    .PARAMETER EmployeeId
        A list of Personio employee ID's to filter the result.
        The result filters including only attendance of provided employees

    .PARAMETER IncludePending
        Returns attendance data with a status of pending, rejected and confirmed.
        For pending periods, the EndDate attribute is nullable.

        The status of each period is included in the response.

    .PARAMETER InclusiveFiltering
        If specified, datefiltering will change it's behaviour
        Attendance data records that begin or end before specified StartDate or after specified EndDate will be outputted

    .PARAMETER ResultSize
        How much records will be returned from the api
        Default is 200

        Use this parameter, when function throw information about pagination

    .PARAMETER Token
        AccessToken object for Personio service

    .EXAMPLE
        PS C:\> Get-PERSAttendance -StartDate 2023-01-01 -EndDate 2023-01-31

        Get attendance data from 2023-01-01 until 2023-01-31
        (api-side-pagination will kick in at 200)

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
        [Parameter(Mandatory = $true)]
        [datetime]
        $StartDate,

        [Parameter(Mandatory = $true)]
        [datetime]
        $EndDate,

        [ValidateNotNullOrEmpty()]
        [datetime]
        $UpdatedFrom,

        [ValidateNotNullOrEmpty()]
        [datetime]
        $UpdatedTo,

        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [int[]]
        $EmployeeId,

        [ValidateNotNullOrEmpty()]
        [int]
        $ResultSize,

        [switch]
        $InclusiveFiltering,

        [ValidateNotNullOrEmpty()]
        [bool]
        $IncludePending = $true,

        [ValidateNotNullOrEmpty()]
        [Personio.Core.AccessToken]
        $Token
    )

    begin {
        # Cache for queried employees
        $listEmployees = [System.Collections.ArrayList]@()

        # define query parameters
        $_startDate = Get-Date -Date $StartDate -Format "yyyy-MM-dd"
        $_endDate = Get-Date -Date $EndDate -Format "yyyy-MM-dd"
        $queryParameter = [ordered]@{
            "start_date" = $_startDate
            "end_date"   = $_endDate
        }

        # fill query parameters
        if ($MyInvocation.BoundParameters['UpdatedFrom']) { $queryParameter.Add("updated_from", (Get-Date -Date $UpdatedFrom -Format "yyyy-MM-dd")) }
        if ($MyInvocation.BoundParameters['UpdatedTo']) { $queryParameter.Add("updated_to", (Get-Date -Date $UpdatedTo -Format "yyyy-MM-dd")) }
        if ($MyInvocation.BoundParameters['ResultSize']) {
            $queryParameter.Add("limit", $ResultSize)
            $queryParameter.Add("offset", 0)
        }
    }

    process {
        # basic preparation
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }

        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "Attendance"


        # fill pipedin query parameters
        if ($MyInvocation.BoundParameters['EmployeeId'] -and $EmployeeId) { $queryParameter.Add("employees[]", $EmployeeId) }


        # Prepare query
        $invokeParam = @{
            "Type"    = "GET"
            "ApiPath" = "company/attendances"
            "Token"   = $Token
        }
        if ($queryParameter) { $invokeParam.Add("QueryParameter", $queryParameter) }


        # Execute query
        Write-PSFMessage -Level Verbose -Message "Getting available attendance periods from $_startDate to $_endDate" -Tag "Attendance", "Query"

        $response = Invoke-PERSRequest @invokeParam


        # Check response and add to responseList
        if (-not $response.success) {
            Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "Attendance", "Query"
        }

        # Check pagination / result limitation
        if ($response.metadata.total_elements -gt $response.limit) {
            Write-PSFMessage -Level Significant -Message "Pagination detected! Retrieved records: $([Array]($response.data).count) of $($response.metadata.total_elements) total records (api call hast limit of $($response.limit) records and started on record number $($response.offset))" -Tag "Attendance", "Query", "WebRequest", "Pagination"
        }

        # Process result
        $output = [System.Collections.ArrayList]@()
        foreach ($record in $response.data) {
            Write-PSFMessage -Level Debug -Message "Working on record Id $($record.attributes.id) startDate: $($record.attributes.start_date) - endDate: $($record.attributes.end_date)" -Tag "Attendance", "ObjectCreation"

            # Create object
            $result = [Personio.Attendance.AttendanceRecord]@{
                BaseObject = $record.attributes
                Id         = $record.id
            }
            $result.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.type)")

            # insert employee
            if ($listEmployees -and ($record.attributes.employee -in $listEmployees.Id)) {
                $_employee = $listEmployees | Where-Object Id -eq $record.attributes.employee
            } else {
                $_employee = Get-PERSEmployee -InputObject $record.attributes.employee | Select-Object -First 1
                $null = $listEmployees.Add($_employee)
            }
            $result.Employee = $_employee
            Remove-Variable -Name _employee -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore

            #$result.Project = Get-PERSProject -InputObject $record.attributes.project

            # add objects to output array
            $null = $output.Add($result)
        }
        Write-PSFMessage -Level Verbose -Message "Retrieve $($output.Count) objects of type [Personio.Attendance.AttendanceRecord]" -Tag "Attendance", "Result"

        # Filtering
        if (-not $MyInvocation.BoundParameters['InclusiveFiltering']) {
            if ($StartDate) { $output = $output | Where-Object Date -ge $StartDate }
            if ($EndDate) { $output = $output | Where-Object Date -le $EndDate }
            if ($UpdatedFrom) { $output = $output | Where-Object UpdatedAt -ge $UpdatedFrom }
            if ($UpdatedTo) { $output = $output | Where-Object UpdatedAt -le $UpdatedTo }
        }

        # output final results
        Write-PSFMessage -Level Verbose -Message "Output $($output.Count) objects" -Tag "AbsenseType", "Result", "Output"
        $output

        # Cleanup variable
        Remove-Variable -Name Token -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
        $queryParameter.remove('employees[]')
    }

    end {
    }
}
