function New-PS1XML {
    <#
    .SYNOPSIS
        Register access token

    .DESCRIPTION
        Register access token within the module

    .PARAMETER Path
        The filename of the ps1xml file to create

    .PARAMETER TypeName
        Name of the type to create format file

    .PARAMETER PropertyList
        Name list of properties to put in format file

    .PARAMETER View
        The view to create in the format file

    .PARAMETER Encoding
        File encoding

    .PARAMETER PassThru
        Outputs the token to the console, even when the register switch is set

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> New-PS1XML -Path C:\MyObject.Format.ps1xml -TypeName MY.Object -PropertyList $PropertyList

        Create MyObject.Format.ps1xml in C:\ with TypeFormat on object My.Object with property names set in $PropertyList
    #>
    [cmdletbinding(
        PositionalBinding = $true,
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]
        $TypeName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string[]]
        $PropertyList,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Table", "List", "Wide", "All")]
        [string[]]
        $View = "All",

        [ValidateNotNullOrEmpty()]
        [ValidateSet("UTF8", "UTF32", "UTF7", "Default", "Unicode", "ASCII", "BigEndianUnicode")]
        [string]
        $Encoding = "UTF8",

        [switch]
        $PassThru
    )

    # check Path
    Write-PSFMessage -Level Verbose -Message "Validate path: $($Path)" -Tag "FormatType", "Format.ps1xml"
    if (-not (Test-Path -Path $Path -IsValid -PathType Leaf)) {
        Stop-PSFFunction -Message "Path $($Path)) is not valid" -Tag "FormatType", "Format.ps1xml" -Cmdlet $pscmdlet
    }

    $tempPath = Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).guid).format.ps1xml"
    Write-PSFMessage -Level System -Message "Start writing xml data in temporary file '$($tempPath)' ($($Encoding) encoding)" -Tag "FormatType", "Format.ps1xml", "tempfile"

    $XmlWriter = [System.XMl.XmlTextWriter]::new($tempPath, [System.Text.Encoding]::$Encoding)
    $xmlWriter.Formatting = "Indented"
    $xmlWriter.Indentation = "4"

    $xmlWriter.WriteStartDocument()

    #region <Configuration><ViewDefinitions>
    $xmlWriter.WriteStartElement("Configuration")
    $xmlWriter.WriteStartElement("ViewDefinitions")

    if ($View -like "Table" -or $View -like "All") {
        Write-PSFMessage -Level Verbose -Message "Generate table view for type $($TypeName)" -Tag "FormatType", "Format.ps1xml", "TableView"

        #region Start <View>
        $xmlWriter.WriteStartElement("View")

        # Element <Name>
        $xmlWriter.WriteElementString("Name", "Table_$($TypeName)")

        #region Start <ViewSelectedBy>
        $xmlWriter.WriteStartElement("ViewSelectedBy")
        $xmlWriter.WriteElementString("TypeName", "$($TypeName)")
        $xmlWriter.WriteEndElement()
        #endregion End <ViewSelectedBy>

        #region Start <TableControl>
        $xmlWriter.WriteStartElement("TableControl")

        # Element <AutoSize>
        $xmlWriter.WriteStartElement("AutoSize")
        $xmlWriter.WriteEndElement()

        #region Start <TableHeaders>
        $xmlWriter.WriteStartElement("TableHeaders")

        #region Start <TableColumnHeader>
        foreach ($property in $PropertyList) {
            $xmlWriter.WriteStartElement("TableColumnHeader")
            $xmlWriter.WriteElementString("Label", "$($property)")
            $xmlWriter.WriteEndElement()
        }
        #endregion End <TableColumnHeader>

        $xmlWriter.WriteEndElement()
        #endregion End <TableHeaders>

        #region Start <TableRowEntries><TableRowEntry><TableColumnItems>
        $xmlWriter.WriteStartElement("TableRowEntries")
        $xmlWriter.WriteStartElement("TableRowEntry")
        $xmlWriter.WriteStartElement("TableColumnItems")

        #region Start <TableColumnItem> <PropertyName>
        foreach ($property in $PropertyList) {
            $xmlWriter.WriteStartElement("TableColumnItem")
            $xmlWriter.WriteElementString("PropertyName", $property)
            $xmlWriter.WriteEndElement()
        }
        #endregion end <TableColumnItem> <PropertyName>

        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        #endregion End <TableRowEntries><TableRowEntry><TableColumnItems>

        $xmlWriter.WriteEndElement()
        #endregion End <TableControl>

        $xmlWriter.WriteEndElement()
        #endregion End <View>
    }

    if ($View -like "List" -or $View -like "All") {
        Write-PSFMessage -Level Verbose -Message "Generate list view for type $($TypeName)" -Tag "FormatType", "Format.ps1xml", "ListView"

        #region Start <View>
        $xmlWriter.WriteStartElement("View")

        # Element <Name>
        $xmlWriter.WriteElementString("Name", "List_$($TypeName)")

        #region Start <ViewSelectedBy>
        $xmlWriter.WriteStartElement("ViewSelectedBy")
        $xmlWriter.WriteElementString("TypeName", "$($TypeName)")
        $xmlWriter.WriteEndElement()
        #endregion End <ViewSelectedBy>

        #region Start <ListControl><ListEntries><ListEntry><ListItems>
        $xmlWriter.WriteStartElement("ListControl")
        $xmlWriter.WriteStartElement("ListEntries")
        $xmlWriter.WriteStartElement("ListEntry")
        $xmlWriter.WriteStartElement("ListItems")

        #region Start <ListItem> <PropertyName>
        foreach ($property in $PropertyList) {
            $xmlWriter.WriteStartElement("ListItem")
            $xmlWriter.WriteElementString("PropertyName", $property)
            $xmlWriter.WriteEndElement()
        }
        #endregion End <ListItem> <PropertyName>

        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        #endregion End <ListControl><ListEntries><ListEntry><ListItems>

        $xmlWriter.WriteEndElement()
        #endregion End <View>
    }

    if ($View -like "Wide" -or $View -like "All") {
        Write-PSFMessage -Level Verbose -Message "Generate wide view for type $($TypeName)" -Tag "FormatType", "Format.ps1xml", "WideView"

        #region Start <View>
        $xmlWriter.WriteStartElement("View")

        # Element <Name>
        $xmlWriter.WriteElementString("Name", "Wide_$($TypeName)")

        #region Start <ViewSelectedBy>
        $xmlWriter.WriteStartElement("ViewSelectedBy")
        $xmlWriter.WriteElementString("TypeName", "$($TypeName)")
        $xmlWriter.WriteEndElement()
        #endregion End <ViewSelectedBy>

        #region Start <WideControl><WideEntries><WideEntry>
        $xmlWriter.WriteStartElement("WideControl")
        $xmlWriter.WriteElementString("AutoSize", "")
        $xmlWriter.WriteStartElement("WideEntries")
        $xmlWriter.WriteStartElement("WideEntry")

        #region Start <WideItem> <PropertyName>
        $wideProperty = ""
        $wideProperty = $PropertyList | Where-Object { $_ -like "*name*"} | Sort-Object | Select-Object -First 1
        if(-not $wideProperty) {$wideProperty = $PropertyList | Where-Object { $_ -like "Id"} | Sort-Object | Select-Object -First 1}
        if(-not $wideProperty) {$wideProperty = $PropertyList | Select-Object -First 1}

        $xmlWriter.WriteStartElement("WideItem")
        $xmlWriter.WriteElementString("PropertyName", $wideProperty)
        $xmlWriter.WriteEndElement()
        #endregion End <WideItem> <PropertyName>

        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        #endregion End <WideControl><WideEntries><WideEntry>

        $xmlWriter.WriteEndElement()
        #endregion End <View>
    }

    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()
    #endregion <Configuration><ViewDefinitions>

    # End the XML Document
    $xmlWriter.WriteEndDocument()

    # Finish The Document
    $xmlWriter.Finalize
    $xmlWriter.Flush()
    $xmlWriter.Close()

    # Write file
    if ($pscmdlet.ShouldProcess("TypeFormat file '$($Path)' for type [$($TypeName)] with properties '$([string]::Join(", ", $PropertyList))'", "New")) {
        Write-PSFMessage -Level Verbose -Message "New TypeFormat file '$($Path)' for type [$($TypeName)] with properties '$([string]::Join(", ", $PropertyList))'" -Tag "FormatType", "Format.ps1xml", "New"

        $output = Move-Item -Path $tempPath -Destination $Path -Force -Confirm:$false -PassThru

        if($PassThru) {
            $output | Get-Item
        }
    }

}
