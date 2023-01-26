function Expand-MemberNamesFromBasicObject {
    <#
    .SYNOPSIS
        Expand-MemberNamesFromBasicObject

    .DESCRIPTION
        Retrieve properties names retrieved from Personio API from TypeData definition

    .PARAMETER TypeName
        Name of the type to retrieve properties from

    .EXAMPLE
        PS C:\> Expand-MemberNamesFromBasicObject -TypeNameBasic "Personio.Employee.BasicEmployee"

        Output properties names retrieved from Personio API from TypeData definition
    #>
    [CmdletBinding(
        PositionalBinding=$true,
        ConfirmImpact="Low"
    )]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $TypeName
    )

    begin {
    }

    process {

        # Get TypeData from PS type system
        $members = Get-TypeData -TypeName "$TypeName" | Select-Object -ExpandProperty Members

        # work trough members of type
        foreach ($key in $members.Keys) {

            # extract scriptblock from module types.ps1xml
            foreach($text in ($members.$key.GetScriptBlock)) {

                # match property names from Baseobject
                if($text -match "\`$this.BaseObject.(?'attrib'\S*[^)}\]])") {

                    # remove subproperties like "email.value" -> so only "email" will be outputted
                    $output = $Matches.attrib.Split(".")[0]

                    # return result
                    $output
                }
            }
        }
    }

    end {
    }
}