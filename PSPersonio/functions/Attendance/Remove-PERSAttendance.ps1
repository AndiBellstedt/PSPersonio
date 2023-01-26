function Remove-PERSAttendance {
    <#
    .Synopsis
        Remove-PERSAttendance

    .DESCRIPTION
        Remove attendance data for the company employees from Personio service

    .PARAMETER Attendance
        The attendance to remove

    .PARAMETER AttendanceId
        The ID of the attendance to remove

    .PARAMETER SkipApproval
        Optional, default value is true.
        If set to false, the approval status within Personio service will be "pending"
        The respective approval flow will be triggered.

    .PARAMETER Force
        Suppress the user confirmation.

    .PARAMETER Token
        AccessToken object for Personio service

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> $attendance | Remove-PERSAttendance

        Remove attendance records from variable $attendance. Assuming that $attendance was previsouly filled with Get-PERSAttendance

    .EXAMPLE
        PS C:\> $attendance | Remove-PERSAttendance -Force

        Remove attendance record from variable $attendance silently. (Confirmation will be suppressed)

    .EXAMPLE
        PS C:\> Remove-PERSAttendance -AttendanceId 111

        Remove attendance redord with ID 111

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ApiNative",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'High'
    )]
    Param(
        [Parameter(
            ParameterSetName = "UserFriendly",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [Personio.Attendance.AttendanceRecord]
        $Attendance,

        [Parameter(
            ParameterSetName = "ApiNative",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [int]
        $AttendanceId,

        [ValidateNotNullOrEmpty()]
        [bool]
        $SkipApproval = $true,

        [switch]
        $Force,

        [ValidateNotNullOrEmpty()]
        [Personio.Core.AccessToken]
        $Token
    )

    begin {
    }

    process {
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }

        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "Attendance", "Remove"

        # fill pipedin query parameters
        if ($parameterSetName -like "ApiNative") {
            $id = $attendanceId
        } elseif ($parameterSetName -like "UserFriendly") {
            $id = $attendance.Id
        }

        # Prepare query
        $invokeParam = @{
            "Type"           = "DELETE"
            "ApiPath"        = "company/attendances/$($id)"
            "Token"          = $Token
            "QueryParameter" = @{
                "skip_approval" = $SkipApproval.ToString().ToLower()
            }
            "AdditionalHeader" = @{
                "accept"       = "application/json"
            }
        }

        $processMessage = "attendance id '$($id)'"
        if ($parameterSetName -like "UserFriendly") {
            $processMessage = $processMessage + " (" + $attendance.Employee + " for "  + (Get-Date -Date $attendance.Start -Format "HH:mm") + " - " + (Get-Date -Date $attendance.End -Format "HH:mm") + " on " + (Get-Date -Date $attendance.Start -Format "yyyy-MM-dd") + ")"
        }

        if (-not $Force) {
            if ($pscmdlet.ShouldProcess($processMessage, "Remove")) { $Force = $true }
        }

        if ($Force) {
            Write-PSFMessage -Level Verbose -Message "Remove $($processMessage)" -Tag "Attendance", "Remove"

            # Execute query
            $response = Invoke-PERSRequest @invokeParam

            # Check response and add to responseList
            if ($response.success) {
                Write-PSFMessage -Level Verbose -Message "Attendance id '$($id)' was removed. Message: $($response.data.message)" -Tag "Attendance", "Remove", "Result"
            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "Attendance", "Remove", "Result"
            }
        }

        # Cleanup variable
        Remove-Variable -Name Token, id, doRemove, processMessage -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
    }

    end {
    }
}
