function New-PERSAttendance {
    <#
    .Synopsis
        New-PERSAttendance

    .DESCRIPTION
        Add attendance records for the company employees into Personio service

    .PARAMETER Employee
        The employee to create a absence for

    .PARAMETER EmployeeId
        Employee ID to create an absence

    .PARAMETER Project
        The project to book on the attendance

    .PARAMETER ProjectId
        The id of the project to book on the attendance

    .PARAMETER Start
        Start of the attendance record as a datetime or parseable string value
        If only a time value is specified, the record will be today with the specified time.

        Attention, the date value of start and end has to be the same day!

    .PARAMETER End
        Start of the attendance record as a datetime or parseable string value
        If only a time value is specified, the record will be today with the specified time.

        Attention, the date value of start and end has to be the same day!

    .PARAMETER Break
        Minutes of break within the attendance record

    .PARAMETER Comment
        Optional comment for the attendance

    .PARAMETER SkipApproval
        Optional, default value is true.
        If set to false, the approval status of the attendance will be "pending"
        The respective approval flow will be triggered.

    .PARAMETER Token
        AccessToken object for Personio service

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> New-PERSAttendance -Employee (Get-PERSEmployee -Email john.doe@company.com) -Start 08:00 -End 12:00

        Create a new attendance record for "John Doe" for "today" from 8 - 12am

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
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
        [Personio.Employee.BasicEmployee[]]
        $Employee,

        [Parameter(
            ParameterSetName = "ApiNative",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [int[]]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "UserFriendly",
            Mandatory = $false
        )]
        [Personio.Project.ProjectRecord]
        $Project,

        [Parameter(
            ParameterSetName = "ApiNative",
            Mandatory = $false
        )]
        [int]
        $ProjectId,

        [Parameter(Mandatory = $true)]
        [datetime]
        $Start,

        [Parameter(Mandatory = $true)]
        [datetime]
        $End,

        [int]
        $Break = 0,

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
        $body = [ordered]@{
            "attendances"   = [System.Collections.ArrayList]@()
            "skip_approval" = [bool]$SkipApproval
        }

        $dateStart = Get-Date -Date $Start -Format "yyyy-MM-dd"
        $dateEnd = Get-Date -Date $End -Format "yyyy-MM-dd"
        if ($dateStart -ne $dateEnd) {
            Stop-PSFFunction -Message "Date problem, Start ($($dateStart)) and Stop ($($dateEnd)) parameters has different date values" -Tag "Attendance", "New", "StartEndDateDifference" -EnableException $true -Cmdlet $pscmdlet
        }
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "Attendance", "New"

        # fill piped in records
        if ($parameterSetName -like "UserFriendly") {
            $EmployeeId = $Employee.Id
            if ($MyInvocation.BoundParameters['Project']) { $ProjectId = $Project.Id } else { $ProjectId = 0 }
        }

        # work the pipe/ specified array of employees
        $attendances = [System.Collections.ArrayList]@()
        foreach ($employeeIdItem in $EmployeeId) {
            $attendance = [ordered]@{
                "employee"   = $employeeIdItem
                "date"       = $dateStart
                "start_time" = (Get-Date -Date $Start -Format "HH:mm")
                "end_time"   = (Get-Date -Date $End -Format "HH:mm")
                "break"      = [int]$Break
            }
            if ($ProjectId) { $attendance.Add("project_id", [int]$ProjectId) }
            if ($MyInvocation.BoundParameters['Comment']) { $attendance.Add("comment", $Comment) }

            # Debug logging
            Write-PSFMessage -Level Debug -Message "Added attendance: $($attendance | ConvertTo-Json -Compress)" -Tag "Attendance", "New", "Request", "Prepare"

            $null = $attendances.Add($attendance)
        }

        $null = $body['attendances'].Add( ($attendances | ForEach-Object { $_ }) )
    }

    end {
        # Prepare query
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }

        $invokeParam = @{
            "Type"             = "POST"
            "ApiPath"          = "company/attendances"
            "Token"            = $Token
            "Body"             = $body
            "AdditionalHeader" = @{
                "accept"       = "application/json"
                "content-type" = "application/json"
            }
        }

        $processMsg = "attendence for $(([array]$body.attendances.employee).count) employee(s)"
        if ($pscmdlet.ShouldProcess($processMsg, "New")) {
            Write-PSFMessage -Level Verbose -Message "New $($processMsg)" -Tag "Attendance", "New"

            # Execute query
            $response = Invoke-PERSRequest @invokeParam
            Remove-Variable -Name Token -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore

            # Check response and add to responseList
            if ($response.success) {
                Write-PSFMessage -Level Verbose -Message "Attendance data created. API message: $($response.data.message)" -Tag "Attendance", "New", "Result"

                # Query attendance data created short before
                $_attendances = Get-PERSAttendance -StartDate $dateStart -EndDate (Get-Date -Date $Start.AddDays(1) -Format "yyyy-MM-dd") -UpdateFrom (Get-Date).AddMinutes(-5) -UpdateTo (Get-Date) -EmployeeId $body.attendances.employee

                # Output created attendance records
                $_attendances | Where-Object id -in $response.data.Id

            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported error: $($response.error)" -Tag "Attendance", "New"
            }
        }
    }
}
