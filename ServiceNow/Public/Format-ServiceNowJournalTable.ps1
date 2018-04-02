function Format-ServiceNowJournalTable {
    [cmdletbinding()]
    param (
        # The object to display as a table.  Must display well with Format-Table.
        <#[parameter(mandatory=$true)]#>
        [parameter(ValueFromPipeline=$True)]
        <#[ValidateNotNullOrEmpty()]#>
        [Object[]]$Object_,
        
        # Title of the table.  Will be displayed at the top of the table.
        [parameter(mandatory=$false)]
        [String]$Title,

        # Pivot the table.  Column headers become row entries.
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='PivotTable')]
        [switch]$PivotObject,

        # This object property name will be used for the column headers
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='PivotTable')]
        [string]$PivotColumnHeaderName = "",

        # The inline HTML style command that is applied to the <table> tag.
        [parameter(mandatory=$false)]
        [String]$StyleTable         = "width: auto; border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;",
        
        # The inline HTML style command that is applied to the <th> tag.
        [parameter(mandatory=$false)]
        [String]$StyleHeader        = "width: auto; border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; background-color: #1495ED; color: #FFFFFF; font-weight: bold;  padding: 3px; padding-right:15px;",
        
        # The inline HTML style command that is applied to the <tr> tag.  Odd rows only.
        [parameter(mandatory=$false)]
        [String]$StyleRowOdd        = "width: auto; border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; background-color: #DDDDDD; color: #000000; font-weight: normal;",
        
        # The inline HTML style command that is applied to the <tr> tag.  Even rows only.
        [parameter(mandatory=$false)]
        [String]$StyleRowEven       = "width: auto; border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; background-color: #FFFFFF; color: #000000; font-weight: normal;",
        
        # The inline HTML style command that is applied to the <td> tag.  All rows.
        [parameter(mandatory=$false)]
        [String]$StyleData          = "width: auto; border-width: 0px; border-style: solid; border-color: black; border-collapse: collapse; padding: 3px; padding-right:15px;"
    )
    Begin {
        $array = New-Object System.Collections.ArrayList;
    }

    Process {
        # Gather all items from the pipeline
        $array.Add($Object_) | Out-Null;
    }

    End {
        # Process 

        If ($Array.count -ieq 1) {
            $Array = $Array[0];
        }

        If ($PivotObject.IsPresent) {
            # Pivot the incoming objects
            
            # Get Property List of every item
            $PropertyList = $Array | ForEach { $_ | Get-Member -MemberType Property,NoteProperty,ScriptProperty } | SELECT -ExpandProperty Name -Unique
            
            # Temporary array to hold the pivoted information
            $ArrayTemp = New-Object System.Collections.ArrayList;

            # Pivot the data
            ForEach ($PropertyName in $PropertyList) {
                $ArrayItem = "" | SELECT -Property "Property_Name";
                $ArrayItem.Property_Name = $PropertyName;

                $ObjectCounter = 0;
                ForEach ($Item in $Array) {
                    If ($PivotColumnHeaderName) {
                        # A property name was specified for the column header
                        $ArrayItem | Add-Member -MemberType NoteProperty -Name $($Item.$PivotColumnHeaderName) -Value $($Item.$PropertyName);
                    }
                    Else {
                        # Use a generic name for the column header
                        $ArrayItem | Add-Member -MemberType NoteProperty -Name $("Object_$($ObjectCounter)_Value") -Value $($Item.$PropertyName);
                        $ObjectCounter++;
                    }
                }
                $ArrayTemp.add($ArrayItem) | Out-Null;
            }
            
            # Overwrite $Array with the pivoted data
            $Array = $ArrayTemp;
        }

        $RowCounter = 0;

        $Message  = '[code]';
        $Message += '<p><b>'+$Title+'</b></p>';                           # Add the title
        $Message += '<div style="overflow-y: auto; overflow-x: auto;">';  # Add a horizontal scroll bar
        $Message += ((($Array `
            | ForEach { $_ | SELECT -Property * }  `
            | ConvertTo-HTML -Fragment) -join '')        <# Create a single-line string #> `
            | ForEach { $_[1..($_.length - 2)] -join ''} <# Drop the leading "<" and trailing ">" #> `
            | ForEach { $_ -split '><' }                 <# Split on HTML tag boundaries #> `
            | ForEach {'<' + $_ + '>'}                   <# Restore the characters removed by Split #> `
            | ForEach {                                  <# Add style formatting #>
                    $Row = $_;
                    Switch ($true) {
                        ($Row -ilike '<table>*') {
                                If ($StyleTable) {
                                    $Row.Replace('<table>',('<table style="' + $StyleTable   + '">')) | Write-Output;
                                }
                                break;
                            }
                        ($Row -ilike '<th>*') {
                                If ($StyleHeader) {
                                    $Row.Replace('<th>'   ,('<th    style="' + $StyleHeader  + '">')) | Write-Output;
                                }
                                break;
                            }
                        ($Row -ilike '<tr>*') {
                                If ($StyleRowOdd -and $StyleRowEven) {
                                    If ($RowCount % 2 -eq 0) { $Row.Replace('<tr>'   ,('<tr    style="' + $StyleRowEven  + '">')) | Write-Output }
                                    Else                     { $Row.Replace('<tr>'   ,('<tr    style="' + $StyleRowOdd   + '">')) | Write-Output };
                                    $RowCount++;
                                }
                                break;
                            }
                        ($Row -ilike '<td>*') {
                                If ($StyleHeader) {
                                    $Row.Replace('<td>'   ,('<td    style="' + $StyleData  + '">')) | Write-Output;
                                }
                                break;
                            }
                        default {
                                $Row | Write-Output;
                                break;
                            }
                    }
                    $RowCounter++;
                } `
        ) + "</div>[/code]";

        Return $Message;
    }
}