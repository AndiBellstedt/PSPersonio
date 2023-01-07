function Get-PERSEmployee {
    <#
    .Synopsis
        Get-PERSEmployee

    .DESCRIPTION
        List employee(s) from Personio
        The result can be paginated and.

    .PARAMETER InputObject
        Employee to call again
        It is inclusive, so the result starts from and including the provided StartDate

    .PARAMETER Email
        Find an employee with the given email address

    .PARAMETER UpdatedSince
        Find all employees that have been updated since the provided date
        NOTE: when using UpdatedSince, the Resultsize parameter is ignored

    .PARAMETER Attributes
        Define a list of whitelisted attributes that shall be returned for all employees

    .PARAMETER EmployeeId
        A list of Personio employee ID's to retrieve

    .PARAMETER ResultSize
        How much records will be returned from the api.
        Default is 200.

        Use this parameter, when function throw information about pagination

    .PARAMETER Token
        AccessToken object for Personio service

    .EXAMPLE
        PS C:\> Get-PERSEmployee

        Get all available company employees
        (api-side-pagination may kick in at 200)

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
        [Parameter(
            ParameterSetName = "Default",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]
        $Email,

        [Parameter(ParameterSetName = "Default")]
        [datetime]
        $UpdatedSince,

        [Parameter(ParameterSetName = "Default")]
        [string[]]
        $Attributes,

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
        [Personio.Employee.BasicEmployee[]]
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
        if ($UpdatedSince) { $queryParameter.Add("updated_since", (Get-Date -Date $UpdatedSince -Format "yyyy-MM-ddTHH:mm:ss")) }
        if ($attributes) { $queryParameter.Add("employees[]", $attributes) }
    }

    process {
        if (-not $MyInvocation.BoundParameters['Token']) { $Token = Get-AccessToken }
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "Employee"

        # fill pipedin query parameters
        if ($Email) { $queryParameter.Add("email", $Email) }


        # Prepare query
        $invokeParam = @{
            "Type"    = "GET"
            "ApiPath" = "company/employees"
            "Token"   = $Token
        }
        if ($queryParameter) { $invokeParam.Add("QueryParameter", $queryParameter) }


        # Execute query
        $responseList = [System.Collections.ArrayList]@()
        if ($parameterSetName -like "Default") {
            Write-PSFMessage -Level Verbose -Message "Getting available employees" -Tag "Employee", "Query"

            $response = Invoke-PERSRequest @invokeParam

            # Check respeonse and add to responeList
            if ($response.success) {
                $null = $responseList.Add($response)
            } else {
                Write-PSFMessage -Level Warning -Message "Personio api reported no data" -Tag "Employee", "Query"
            }
        } elseif ($parameterSetName -like "ByType") {

            foreach ($inputItem in $InputObject) {
                Write-PSFMessage -Level Verbose -Message "Getting employee Id $($inputItem.Id)" -Tag "Employee", "Query"

                $invokeParam.ApiPath = "company/employees/$($inputItem.Id)"
                $response = Invoke-PERSRequest @invokeParam


                # Check respeonse and add to responeList
                if ($response.success) {
                    $null = $responseList.Add($response)
                } else {
                    Write-PSFMessage -Level Warning -Message "Personio api reported no data on employee Id $($inputItem.Id)" -Tag "Employee", "Query"
                }


                # remove token param for further api calls, due to the fact, that the passed in token, is no more valid after previous api all (api will use internal registered token)
                $invokeParam.Remove("Token")
            }
        }
        Remove-Variable -Name response -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore


        foreach ($response in $responseList) {
            # Check pagination / result limitation
            if ($response.metadata) {
                Write-PSFMessage -Level Significant -Message "Pagination detected! Retrieved records: $([Array]($response.data).count) of $($response.metadata.total_elements) total records (api call hast limit of $($response.limit) records and started on record number $($response.offset))" -Tag "Employee", "Query", "WebRequest", "Pagination"
            }


            # Process result
            $output = [System.Collections.ArrayList]@()

            foreach ($record in $response.data) {
                Write-PSFMessage -Level Debug -Message "Working on record Id $($record.attributes.id.value) name: $($record.attributes.first_name.value) $($record.attributes.last_name.value)" -Tag "Employee", "ObjectCreation"

                # Create object
                $result = [Personio.Employee.BasicEmployee]@{
                    BaseObject = $record.attributes
                    Id         = $record.attributes.id.value
                    Name       = "$($record.attributes.last_name.value), $($record.attributes.first_name.value)"
                }
                $result.psobject.TypeNames.Insert(1, "Personio.Employee.$($record.type)")

                #region dynamic attribute checking and typeData Format generation
                $dynamicAttributes = $result.BaseObject.psobject.Members | Where-Object name -like "dynamic_*"
                if ($dynamicAttributes) {
                    # Dynamic attributes found
                    $typeNameBasic = $result.psobject.TypeNames[0]
                    $typeNameExtended = "Personio.Employee.ExtendedEmployee"
                    Write-PSFMessage -Level Debug -Message "Employee with dynamic attribute detected, create [$($typeNameExtended)] object" -Tag "Employee", "ObjectCreation", "ExtendedEmployee", "DynamicProperty"

                    # Add sythetic type on top of employee object
                    $result.psobject.TypeNames.Insert(0, $typeNameExtended)

                    # Check synthetic typeData definition & compile the gathered dynamic properties if needed
                    $typeExtendedEmployee = Get-TypeData -TypeName $typeNameExtended
                    $_modified = $false
                    foreach ($dynamicAttr in $dynamicAttributes) {
                        if (-not ($dynamicAttr.Value.label -in $typeExtendedEmployee.Members.Keys)) {
                            # dynamic property is new and currently not in TypeData defintion
                            Write-PSFMessage -Level Debug -Message "Add dynamic attribute '$($dynamicAttr.Name)' as property '$($dynamicAttr.Value.label)' into TypeData for [$($typeNameExtended)]" -Tag "Employee", "ObjectCreation", "ExtendedEmployee", "DynamicProperty", "TypeData"
                            Update-TypeData -TypeName $typeNameExtended -Force -MemberName $dynamicAttr.Value.label -MemberType ScriptProperty -Value ([scriptblock]::Create( "`$this.BaseObject.$($dynamicAttr.Name).value" ))
                            $_modified = $true
                        }
                    }

                    if ($_modified) {
                        Write-PSFMessage -Level Verbose -Message "New dynamic attributes within employee detected. TypeData for [Personio.Employee.ExtendedEmployee] was modified. Going to compile FormatData" -Tag "Employee", "ObjectCreation", "ExtendedEmployee", "DynamicProperty", "FormatData"
                        $typeBasicEmployee = Get-TypeData -TypeName $typeNameBasic
                        $typeExtendedEmployee = Get-TypeData -TypeName $typeNameExtended
                        $pathExtended = Join-Path -Path $env:TEMP -ChildPath "$($typeNameExtended).Format.ps1xml"

                        $properties = @( "Id", "Name")
                        $properties += $typeBasicEmployee.Members.Keys
                        $properties += $typeExtendedEmployee.Members.Keys
                        $properties = $properties | Where-Object { $_ -notlike 'SerializationData' }

                        New-PS1XML -Path $pathExtended -TypeName $typeNameExtended -PropertyList $properties -View Table, List -Encoding UTF8

                        Write-PSFMessage -Level System -Message "Update FormatData with file '$($pathExtended)'" -Tag "Employee", "ObjectCreation", "ExtendedEmployee", "DynamicProperty", "FormatData"
                        Update-FormatData -PrependPath $pathExtended
                    }
                }
                #endregion dynamic attribute checking and typeData Format generation

                # add objects to output array
                $null = $output.Add($result)
            }

            if ($output.Count -gt 1) {
                Write-PSFMessage -Level Verbose -Message "Retrieve $(([string]::Join(" & ", ($output | ForEach-Object { $_.psobject.TypeNames[0] } | Group-Object | ForEach-Object { "$($_.count) [$($_.Name)]" })))) objects" -Tag "Employee", "Result"
            } else {
                Write-PSFMessage -Level Verbose -Message "Retrieve $($output.Count) object$(if($output) { " [" + $output[0].psobject.TypeNames[0] + "]"})" -Tag "Employee", "Result"
            }


            # Filtering
            #ToDo: Implement filtering for record output


            # output final results
            Write-PSFMessage -Level Verbose -Message "Output $($output.Count) objects" -Tag "Employee", "Result", "Output"
            foreach($item in $output) {
                $item
            }
        }


        # Cleanup variable
        Remove-Variable -Name Token -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
        $queryParameter.remove('email')
    }

    end {
    }
}
