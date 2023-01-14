function New-PERSAbsence {
    <#
    .Synopsis
        New-PERSAbsence

    .DESCRIPTION
        Adds absence period (tracked in days) into Personio service

    .PARAMETER Employee
        The employee to create a absence for

    .PARAMETER EmployeeId
        Employee ID to create an absence

    .PARAMETER AbsenceType
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

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> New-PERSAbsence -Employee (Get-PERSEmployee -Email john.doe@company.com) -Type (Get-PERSAbsenceType -Name "Vacation") -StartDate 01.01.2023 -EndDate 05.01.2023

        Create a new absence for "John Doe" of type "Urlaub" from 01.01.2023 until 05.01.2023

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
    [CmdletBinding(
        DefaultParameterSetName = "ApiNative",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
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
        [int]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "UserFriendly",
            Mandatory = $true
        )]
        [Alias("Type", "Absence")]
        [Personio.Absence.AbsenceType]
        $AbsenceType,

        [Parameter(
            ParameterSetName = "ApiNative",
            Mandatory = $true
        )]
        [Alias("TypeId")]
        [int]
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
    }

    process {
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }
        $body = [ordered]@{}

        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "AbsensePeriod", "New"

        # fill pipedin query parameters
        if ($parameterSetName -like "ApiNative") {
            $body.Add("employee_id", $EmployeeId)
            $body.Add("time_off_type_id", $AbsenceTypeId)

        } elseif ($parameterSetName -like "UserFriendly") {
            $body.Add("employee_id", $Employee.Id)
            $body.Add("time_off_type_id", $AbsenceType.Id)

        }

        # fill query parameters
        $body.Add("start_date", (Get-Date -Date $StartDate -Format "yyyy-MM-dd"))
        $body.Add("end_date", (Get-Date -Date $EndDate -Format "yyyy-MM-dd"))
        $body.Add("half_day_start", $HalfDayStart.ToString().ToLower())
        $body.Add("half_day_end", $HalfDayEnd.ToString().ToLower())
        $body.Add("skip_approval", $SkipApproval.ToString().ToLower())
        #if ($MyInvocation.BoundParameters['Comment']) { $body.Add("comment", [uri]::EscapeDataString($Comment)) }
        if ($MyInvocation.BoundParameters['Comment']) { $body.Add("comment", $Comment) }

        # Debug logging
        foreach ($key in $body.Keys) {
            Write-PSFMessage -Level Debug -Message "Added body attribute '$($key)' with value '$($body[$key])'" -Tag "AbsensePeriod", "New", "Request"
        }

        # Prepare query
        $invokeParam = @{
            "Type"             = "POST"
            "ApiPath"          = "company/time-offs"
            "Token"            = $Token
            "Body"             = $body
            "AdditionalHeader" = @{
                "accept"       = "application/json"
                "content-type" = "application/x-www-form-urlencoded"
            }
        }

        $processMsg = "absence period of '$($AbsenceType.Name)' ($($body['start_date'])-$($body['end_date']))"
        if ($pscmdlet.ShouldProcess($processMsg, "New")) {
            Write-PSFMessage -Level Verbose -Message "New $($processMsg)" -Tag "AbsensePeriod", "New"

            # Execute query
            $response = Invoke-PERSRequest @invokeParam

            # Check response and add to responseList
            if ($response.success) {
                Write-PSFMessage -Level System -Message "Retrieve $(([array]$response.data).Count) objects" -Tag "AbsensePeriod", "New", "Result"

                foreach ($record in $response.data) {
                    # create absence object
                    $result = [Personio.Absence.AbsencePeriod]@{
                        BaseObject = $record.attributes
                        Id         = $record.attributes.id
                    }
                    $result.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.type)")

                    # make employee record to valid object
                    $result.Employee = [Personio.Employee.BasicEmployee]@{
                        BaseObject = $record.attributes.employee.attributes
                        Id         = $record.attributes.employee.attributes.id.value
                        Name       = "$($record.attributes.employee.attributes.last_name.value), $($record.attributes.employee.attributes.first_name.value)"
                    }
                    $result.Employee.psobject.TypeNames.Insert(1, "Personio.Employee.$($record.attributes.employee.type)")

                    # make absenceType record to valid object
                    $result.Type = [Personio.Absence.AbsenceType]@{
                        BaseObject = $record.attributes.time_off_type.attributes
                        Id         = $record.attributes.time_off_type.attributes.id
                        Name       = $record.attributes.time_off_type.attributes.name
                    }
                    $result.Type.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.attributes.time_off_type.type)")

                    # output final results
                    Write-PSFMessage -Level Verbose -Message "Output [$($result.psobject.TypeNames[0])] object '$($result.Type)' (start: $(Get-Date $result.StartDate -Format "yyyy-MM-dd") - end: $(Get-Date $result.EndDate -Format "yyyy-MM-dd"))" -Tag "AbsensePeriod", "Result", "Output"
                    $result
                }

            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsensePeriod", "New"
            }
        }

        # Cleanup variable
        Remove-Variable -Name Token -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
        $body.remove('employee_id')
    }

    end {
    }
}
