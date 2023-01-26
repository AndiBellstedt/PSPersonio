function Get-PERSAbsenceSummary {
    <#
    .Synopsis
        Get-PERSAbsenceSummary

    .DESCRIPTION
        Retrieve absence summery for a specific employee from Personio

    .PARAMETER Employee
        The employee to get the summary for

    .PARAMETER EmployeeId
        Employee ID to get the summary for

    .PARAMETER Filter
        The name of the absence type to filter on

    .PARAMETER IncludeZeroValues
        If this is specified, all the absence types will be outputted.
        Be default, only absence summary records with a balance value greater than 0 are returned

    .PARAMETER Token
        AccessToken object for Personio service

    .EXAMPLE
        PS C:\> Get-PERSAbsenceSummary -EmployeeId 111

        Get absence summary of all types on employee with ID 111

    .EXAMPLE
        PS C:\> Get-PERSAbsenceSummary -Employee (Get-PERSEmployee -Email john.doe@company.com)

        Get absence summary of all types on employee John Doe

    .EXAMPLE
        PS C:\> Get-PERSEmployee -Email john.doe@company.com | Get-PERSAbsenceSummary -Type "Vacation"

        Get absence summary of type 'vacation' on employee John Doe

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSPersonio
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ApiNative",
        SupportsShouldProcess = $false,
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

        [Alias("Type", "AbsenceType")]
        [string[]]
        $Filter,

        [switch]
        $IncludeZeroValues,

        [Personio.Core.AccessToken]
        $Token
    )

    begin {
        if ($MyInvocation.BoundParameters['Token']) {
            $absenceTypes = Get-PERSAbsenceType -Token $Token
        } else {
            $absenceTypes = Get-PERSAbsenceType
        }
        $newTokenRequired = $true
    }

    process {
        # collect Employees from piped in IDs
        if ($MyInvocation.BoundParameters['EmployeeId']) {
            $Employee = Get-PERSEmployee -InputObject $EmployeeId
        }


        # Process employees and gather data
        $output = [System.Collections.ArrayList]@()
        foreach ($employeeItem in $Employee) {
            # Prepare token
            if (-not $MyInvocation.BoundParameters['Token'] -or $newTokenRequired) { $Token = Get-AccessToken }

            # Prepare query
            $invokeParam = @{
                "Type"    = "GET"
                "ApiPath" = "company/employees/$($employeeItem.id)/absences/balance"
                "Token"   = $Token
            }

            # Execute query
            Write-PSFMessage -Level Verbose -Message "Getting absence summary for '$($employeeItem)'" -Tag "AbsenceSummary", "Query"
            $response = Invoke-PERSRequest @invokeParam

            # Check respeonse
            if ($response.success) {
                # Process result
                foreach ($record in $response.data) {
                    Write-PSFMessage -Level Debug -Message "Working on record $($record.name) (ID: $($record.id)) for '$($employeeItem)'" -Tag "AbsenceSummary", "ObjectCreation"

                    # process if filter is not specified or filter applies on record
                    if ((-not $Filter) -or ($Filter | ForEach-Object { $record.name -like $_ })) {

                        # Create object
                        $result = [Personio.Absence.AbsenceSummaryRecord]@{
                            BaseObject  = $record
                            AbsenceType = ($absenceTypes | Where-Object Id -eq $record.id)
                            Employee    = $employeeItem
                            "Category"  = $record.category
                            "Balance"   = $record.balance
                        }
                        $result.psobject.TypeNames.Insert(1, "Personio.Absence.$($record.type)")

                        # add objects to output array
                        $null = $output.Add($result)
                    }
                }
            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "AbsenceSummary", "Query"
            }
        }
        Write-PSFMessage -Level System -Message "Retrieve $($output.Count) objects of type [Personio.Absence.AbsenceSummaryRecord]" -Tag "AbsenceSummary", "Result"

        if (-not $MyInvocation.BoundParameters['IncludeZeroValues']) {
            $output = $output | Where-Object Balance -gt 0
        }

        # output final results
        Write-PSFMessage -Level Verbose -Message "Output $($output.Count) objects" -Tag "AbsenceSummary", "Result", "Output"
        $output


        # Cleanup variable
        Remove-Variable -Name Token -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
    }

    end {
    }
}
