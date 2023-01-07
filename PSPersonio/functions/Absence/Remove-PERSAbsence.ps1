function Remove-PERSAbsence {
    <#
    .Synopsis
        Remove-PERSAbsence

    .DESCRIPTION
        Remove absence period (tracked in days) from Personio service

    .PARAMETER Absence
        The Absence to remove

    .PARAMETER AbsenceId
        The ID of the absence to remove

    .PARAMETER Force
        Suppress the user confirmation.

    .PARAMETER Token
        AccessToken object for Personio service

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> $absence | Remove-PERSAbsence

        Remove absence from variable $absence. Assuming that $absence was previsouly filled with Get-PERSAbsence

    .EXAMPLE
        PS C:\> $absence | Remove-PERSAbsence -Force

        Remove absence from variable $absence silently. (Confirmation will be suppressed)

    .EXAMPLE
        PS C:\> Remove-PERSAbsence -AbsenceId 111

        Remove absence with ID 111

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
        [Personio.Absence.AbsencePeriod]
        $Absence,

        [Parameter(
            ParameterSetName = "ApiNative",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [int]
        $AbsenceId,

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
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "AbsensePeriod", "New"

        # fill pipedin query parameters
        if ($parameterSetName -like "ApiNative") {
            $id = $AbsenceId
        } elseif ($parameterSetName -like "UserFriendly") {
            $id = $Absence.Id
        }

        # Prepare query
        $invokeParam = @{
            "Type"    = "DELETE"
            "ApiPath" = "company/time-offs/$($id)"
            "Token"   = $Token
        }

        $processMessage = "absence id '$($id)'"
        if($parameterSetName -like "UserFriendly") {
            $processMessage = $processMessage + " (" + $Absence.Type + " on '" + $Absence.Employee + "' for " + (Get-Date -Date $Absence.StartDate -Format "yyyy-MM-dd") + " - " + (Get-Date -Date $Absence.EndDate -Format "yyyy-MM-dd") + ")"
        }

        if ($pscmdlet.ShouldProcess($processMessage, "Remove")) { $Force = $true }

        if($Force) {
            Write-PSFMessage -Level Verbose -Message "Remove $($processMessage)" -Tag "AbsensePeriod", "Remove"

            # Execute query
            $response = Invoke-PERSRequest @invokeParam

            # Check response and add to responseList
            if ($response.success) {
                Write-PSFMessage -Level Vebose -Message "Absence id '$($id)' was removed. Message: $($response.data.message)" -Tag "AbsensePeriod", "Remove", "Result"
            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsensePeriod", "Remove", "Result"
            }
        }

        # Cleanup variable
        Remove-Variable -Name Token,id, doRemove, processMessage -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
    }

    end {
    }
}
