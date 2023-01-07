function New-PERSAbsence {
    <#
    .Synopsis
        New-PERSAbsence

    .DESCRIPTION
        Adds absence period tracked in days into Personio service

    .PARAMETER Employee
        The employee to create a absence for

    .PARAMETER EmployeeId
        Employee ID to create an abesende

    .PARAMETER Type
        The Absence type to create

    .PARAMETER AbsenceTypeId
        The Absence type to create

    .PARAMETER StartDate
        First day of absence period

    .PARAMETER EndDate
        Last day of absence period

    .PARAMETER HalfDayStart
        Weather the start date is a half-day off

    .PARAMETER HalfDayEnd
        Weather the end date is a half-day off

    .PARAMETER Comment
        Optional comment for the absence

    .PARAMETER SkipApproval
        Optional, default value is true.
        If set to false, the approval status of the absence request will be "pending"
        if an approval rule is set for the absence type in Personio.
        The respective approval flow will be triggered.

    .PARAMETER Token
        AccessToken object for Personio service

    .EXAMPLE
        PS C:\> New-PERSAbsence -Employee (Get-PERSEmployee -Email john.doe@company.com) -Type (Get-PERSAnsemceType -Name Urlaub) -StartDate 01.01.2023 -EndDate 05.01.2023

        Create a new absence for "John Doe" of type "Urlaub" from 01.01.2023 until 05.01.2023

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ApiNative",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            ParameterSetName = "UserFriendly",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [Personio.Employee.BasicEmployee]
        $Employee,

        [Parameter(
            ParameterSetName = "ApiNative",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [ind]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "UserFriendly",
            Mandatory = $true
        )]
        [Personio.Absence.AbsenceType]
        $Type,

        [Parameter(
            ParameterSetName = "ApiNative",
            Mandatory = $true
        )]
        [ind]
        $AbsenceTypeId,

        [Parameter(Mandatory = $true)]
        [datetime]
        $StartDate,

        [Parameter(Mandatory = $true)]
        [datetime]
        $EndDate,

        [bool]
        $HalfDayStart = $false,

        [bool]
        $HalfDayEnd = $false,

        [string]
        $Comment,

        [ValidateNotNullOrEmpty()]
        [bool]
        $SkipApproval = $true,

        [ValidateNotNullOrEmpty()]
        [Personio.Core.AccessToken]
        $Token
    )

    begin {
        # define query parameters
        $body = [ordered]@{}

        # fill query parameters
        if ($MyInvocation.BoundParameters['StartDate']) { $body.Add("start_date", (Get-Date -Date $StartDate -Format "yyyy-MM-dd")) }
        if ($MyInvocation.BoundParameters['EndDate']) { $body.Add("end_date", (Get-Date -Date $EndDate -Format "yyyy-MM-dd")) }
        if ($MyInvocation.BoundParameters['HalfDayStart']) { $body.Add("half_day_start", $HalfDayStart.ToString().ToLower()) }
        if ($MyInvocation.BoundParameters['HalfDayEnd']) { $body.Add("half_day_end", $HalfDayEnd.ToString().ToLower()) }
        if ($MyInvocation.BoundParameters['$Comment']) { $body.Add("comment", $Comment) }
        if ($MyInvocation.BoundParameters['SkipApproval']) { $body.Add("skip_approval", $SkipApproval.ToString().ToLower()) }
    }

    process {
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }

        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "AbsensePeriod", "New"

        # fill pipedin query parameters
        if ($parameterSetName -like "ApiNative") {
            $body.Add("employee_id", $EmployeeId)
        } elseif ($parameterSetName -like "UserFriendly") {
            $body.Add("employee_id", $Employee.Id)
        }

        # Prepare query
        $invokeParam = @{
            "Type"    = "POST"
            "ApiPath" = "company/time-offs"
            "Token"   = $Token
        }
        if ($body) { $invokeParam.Add("Body", $body) }

        # Execute query
        $response = Invoke-PERSRequest @invokeParam

        # Check response and add to responseList
        if ($response.success) {
            Write-PSFMessage -Level Verbose -Message "Retrieve $($response.data.Count) objects" -Tag "AbsensePeriod", "New", "Result"
            $record = $response.data
            $result = [Personio.Absence.AbsencePeriod]@{
                BaseObject = $record.attributes
                Id         = $record.attributes.id
                Name       = $record.attributes.time_off_type.attributes.name
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

        } else {
            Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsensePeriod", "New"
        }

        # output final results
        Write-PSFMessage -Level Verbose -Message "Output [$($result.psobject.TypeNames[0])] objects (start: $(Get-Date $result.StartDate -Format "yyyy-MM-dd") - end: $(Get-Date $result.EndDate -Format "yyyy-MM-dd"))" -Tag "AbsensePeriod", "Result", "Output"
        $result

        # Cleanup variable
        Remove-Variable -Name Token, -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
        $body.remove('employee_id')
    }

    end {
    }
}
