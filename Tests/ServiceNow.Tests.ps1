$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$DefaultsFile = Join-Path $projectRoot "Tests\$($ModuleName).Pester.Defaults.json"

# Load defaults from file (merging into $global:ServiceNowPesterTestDefaults)
if(Test-Path $DefaultsFile){
    $defaults = @{}
    # Add properties to the defaults hash
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | ForEach-Object {
        $defaults."$($_.Name)" = $_.Value
    }

    # Prompt for credentials
    $defaults.Creds = if($defaults.Creds){$defaults.Creds}else{Get-Credential}

    $global:ServiceNowPesterTestDefaults = $defaults
}else{
    # Write example file
   @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory = 'Internal'
        TestUserGroup = 'e9e9a2406f4c35001855fa0dba3ee4f3'
        TestUser = "7a4b573a6f3725001855fa0dba3ee485"
    } | ConvertTo-Json | Set-Content $DefaultsFile
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values"
    Return
}

# Load the module (unload it first in case we've made changes since loading it previously)
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleRoot "$moduleName.psd1") -Force

Describe "ServiceNow-Module" {
    If (Test-ServiceNowAuthisSet) {
        Remove-ServiceNowAuth | Should -Be $True
    }

    It "Test-ServiceNowAuthIsSet not set" {
        Test-ServiceNowAuthIsSet | Should -Be $false
    }

    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $defaults.ServiceNowURL -Credentials $defaults.Creds | Should -Be $true
    }

    It "Test-ServiceNowAuthIsSet set" {
        Test-ServiceNowAuthIsSet | Should -Be $true
    }

    It "New-ServiceNowIncident (and by extension New-ServiceNowTableEntry) works" {
        $ShortDescription = "Testing Ticket Creation with Pester"
        $newServiceNowIncidentSplat = @{
            Caller              = $Defaults.TestUser
            ShortDescription    = $ShortDescription
            Description         = "Long description"
            AssignmentGroup     = $Defaults.TestUserGroup
            Comment             = "Comment"
            Category            = $Defaults.TestCategory
            SubCategory         = $Defaults.TestSubcategory
            ConfigurationItem   = $Defaults.TestConfigurationIte
        }
        $TestTicket = New-ServiceNowIncident @newServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription
    }

    It "Get-ServiceNowTable works" {
        # There should be one or more incidents returned
        ([array](Get-ServiceNowTable -Table 'incident' -Query 'ORDERBYDESCopened_at')).Count -gt 0  | Should -Match $true
    }

    It "Get-ServiceNowIncident works" {
        # There should be one or more incidents returned
        ([array](Get-ServiceNowIncident)).count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowRequest works" {
        # There should be one or more incidents returned
        ([array](Get-ServiceNowRequest)).count -gt 0 | Should -Match $true
    }

    It "Update-ServiceNowIncident works" {
        $ShortDescription = "Testing Ticket Update with Pester"
        $newServiceNowIncidentSplat = @{
            Caller              = $Defaults.TestUser
            ShortDescription    = $ShortDescription
            Description         = "Long description"
            AssignmentGroup     = $Defaults.TestUserGroup
            Comment             = "Comment"
            Category            = $Defaults.TestCategory
            SubCategory         = $Defaults.TestSubcategory
            ConfigurationItem   = $Defaults.TestConfigurationItem

        }
        $TestTicket = New-ServiceNowIncident @newServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription

        $Values =
        @{
            'short_description' = 'Ticket Updated with Pester'
            'description' = 'Even Longer Description'
        }

        Update-ServiceNowIncident -SysId $TestTicket.sys_id -Values $Values

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should -Be "Ticket Updated with Pester"
        $TestTicket.description | Should -Be "Even Longer Description"
    }

    It "Get-ServiceNowUserGroup works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUserGroup).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowUser works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUser).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowConfigurationItem works" {
        # There should be one or more configuration items returned
        (Get-ServiceNowConfigurationItem).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowChangeRequest works" {
        (Get-ServiceNowChangeRequest).Count -gt 0 | Should -Match $true
    }

    It "Update-ServiceNowChangeRequest works" {
        $ServiceNowChangeRequestSplat = @{
            number = "CHG0000001"
        };

        $TestTicket = Get-ServiceNowChangeRequest -MatchExact $ServiceNowChangeRequestSplat;

        $Values =
        @{
            'comments'   = "Automated_Comment_$((New-Guid).guid)"
            'work_notes' = "Automated_Work_Note_$((New-Guid).guid)"
        }

        $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
        $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        $TestTicket.comments   | Should -BeLike ("*$($Values['comments'])*");
        $TestTicket.work_notes | Should -BeLike ("*$($Values['work_notes'])*");
    }

    It "Format-ServiceNowJournalTable works" {
        $ServiceNowChangeRequestSplat = @{
            number = "CHG0000003"
        };

        $TestTicket = Get-ServiceNowChangeRequest -MatchExact $ServiceNowChangeRequestSplat;

        $Values =
        @{
            'comments'   = ""
        }

        #region Multiple Custom Objects.  Use the pipeline.  Order the columns.  No line wrap.

            # Create an array of custom objects
            # NOTE: This should be wide enough to make the horizontal scroll bar appear.
            $Title = "Multiple Custom Objects.  Use the pipeline.  Order the columns.  No line wrap.";
            $Array = New-Object System.Collections.ArrayList 
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;

            # Convert $Array into the HTML table and store in Comments.  Use the pipeline.  Order the columns.  No line wrap of data.  
            $StyleData = "width: auto; border-width: 0px; border-style: solid; border-color: black; border-collapse: collapse; padding: 3px; padding-right:15px; white-space: nowrap";
            $Values['comments'] = $Array | SELECT -Property Property1,Property2,Property3,Property4,Property5 | Format-ServiceNowJournalTable -Title $Title -StyleData $StyleData;

            # Update ticket
            $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
            $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        
            # Verify ticket updated
            $TestTicket.comments.split("`n")[1]   | Should -Be ($Values['comments']);

        #endregion Multiple Custom Objects.  Use the pipeline.  Order the columns.  No line wrap.
        
        #region Multiple Custom Objects.  Use the pipeline.  Order the columns.  No line wrap.  Pivot the data.

            # Create an array of custom objects
            # NOTE: This should be wide enough to make the horizontal scroll bar appear.
            $Title = "Multiple Custom Objects.  Use the pipeline.  Order the columns.  No line wrap.  Pivot the data.";
            $Array = New-Object System.Collections.ArrayList 
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;
            $Array.Add( $(New-Object –TypeName PSObject –Prop @{'Property1'=$((New-Guid).guid); 'Property2'=$((New-Guid).guid); 'Property3'=$((New-Guid).guid); 'Property4'=$((New-Guid).guid); 'Property5'=$((New-Guid).guid);}) ) | Out-Null;

            # Convert $Array into the HTML table and store in Comments.  Use the pipeline.  Order the columns.  No line wrap of data.  
            $StyleData = "width: auto; border-width: 0px; border-style: solid; border-color: black; border-collapse: collapse; padding: 3px; padding-right:15px; white-space: nowrap";
            $Values['comments'] = $Array | SELECT -Property Property1,Property2,Property3,Property4,Property5 | Format-ServiceNowJournalTable -Title $Title -PivotObject -StyleData $StyleData;

            # Update ticket
            $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
            $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        
            # Verify ticket updated
            $TestTicket.comments.split("`n")[1]   | Should -Be ($Values['comments']);

        #endregion Multiple Custom Objects.  Use the pipeline.  Order the columns.  No line wrap.  Pivot the data.
        
        #region Single Object: (Get-PSDrive -Name 'C').  Use input parameter.  Unordered columns.  No line wrap.
        
            # Retrieve a single object
            $Title = "Single Object: (Get-PSDrive -Name 'C').  Use input parameter.  Unordered columns.  No line wrap."
            $Object = Get-PSDrive -Name "C";
        
            # Store the HTML table in Comments
            $StyleData = "width: auto; border-width: 0px; border-style: solid; border-color: black; border-collapse: collapse; padding: 3px; padding-right:15px; white-space: nowrap";
            $Values['comments'] = Format-ServiceNowJournalTable -Title $Title -Object_ $Object -StyleData $StyleData;

            # Update ticket
            $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
            $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        
            # Verify ticket updated
            $TestTicket.comments.split("`n")[1]   | Should -Be ($Values['comments']);

        #endregion Single Object: (Get-PSDrive -Name 'C').  Use input parameter.  Unordered columns.  No line wrap.

        #region Single Object: (Get-PSDrive -Name 'C').  Use input parameter.  Unordered columns.  No line wrap.  Pivot the data.  Custom column header name.
        
            # Retrieve a single object
            $Title = "Single Object: (Get-PSDrive -Name 'C').  Use input parameter.  Unordered columns.  No line wrap.  Pivot the data.  Custom column header name."
            $Object = Get-PSDrive -Name C;
        
            # Store the HTML table in Comments
            $StyleData = "width: auto; border-width: 0px; border-style: solid; border-color: black; border-collapse: collapse; padding: 3px; padding-right:15px; white-space: nowrap";
            $Values['comments'] = Format-ServiceNowJournalTable -Title $Title -Object_ $Object -PivotObject -PivotColumnHeaderName "Name" -StyleData $StyleData;

            # Update ticket
            $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
            $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        
            # Verify ticket updated
            $TestTicket.comments.split("`n")[1]   | Should -Be ($Values['comments']);

        #endregion Single Object: (Get-PSDrive -Name 'C').  Use input parameter.  Unordered columns.  No line wrap.  Pivot the data.  Custom column header name.

        #region Multiple Objects: (Get-PSDrive).  Use input parameter.  Unordered columns.  No line wrap.  Pivot the data.  Custom column header name.
        
            # Retrieve a single object
            $Title = "Multiple Objects: (Get-PSDrive).  Use input parameter.  Unordered columns.  No line wrap.  Pivot the data.  Custom column header name."
            $Objects = Get-PSDrive;
            
            # Store the HTML table in Work Notes
            $StyleData = "width: auto; border-width: 0px; border-style: solid; border-color: black; border-collapse: collapse; padding: 3px; padding-right:15px; white-space: nowrap";
            $Values['comments'] = Format-ServiceNowJournalTable -Title $Title -Object_ $Objects -PivotObject -PivotColumnHeaderName "Name" -StyleData $StyleData;

            # Update ticket
            $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
            $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        
            # Verify ticket updated
            $TestTicket.comments.split("`n")[1]   | Should -Be ($Values['comments']);

        #endregion  Multiple Objects: (Get-PSDrive).  Use input parameter.  Unordered columns.  No line wrap.  Pivot the data.  Custom column header name.

        #region Multiple Objects: (Get-PSDrive).  Use input parameter.  Unordered columns.  Allow line wrap.  Pivot the data.  Default column header name.  Custom table colors.
        
            # Retrieve a single object
            $Title = "Multiple Objects: (Get-PSDrive).  Use input parameter.  Unordered columns.  Allow line wrap.  Custom table colors.  Pivot the data.  Default column header name."
            $Objects = Get-PSDrive;
        
            # Store the HTML table in Work Notes
            $StyleHeader        = "width: auto;  border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; background-color: #CC0000; color: #000000; font-weight: bold;  padding: 3px; padding-right:15px;";
            $StyleRowOdd        = "width: auto;  border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; background-color: #ffe6e6; color: #000000; font-weight: normal; ";
            $StyleRowEven       = "width: auto;  border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; background-color: #FFFFFF; color: #000000; font-weight: normal; ";
            $Values['comments'] = Format-ServiceNowJournalTable -Title $Title -Object_ $Objects -PivotObject -StyleHeader $StyleHeader -StyleRowOdd $StyleRowOdd -StyleRowEven $StyleRowEven;

            # Update ticket
            $TestTicket = Update-ServiceNowChangeRequest -SysId $TestTicket.sys_id -Values $Values;
            $TestTicket = Get-ServiceNowChangeRequest -MatchExact @{sys_id=$TestTicket.sys_id};
        
            # Verify ticket updated
            $TestTicket.comments.split("`n")[1]   | Should -Be ($Values['comments']);

        #endregion Multiple Objects: (Get-PSDrive).  Use input parameter.  Unordered columns.  Allow line wrap.  Pivot the data.  Default column header name.  Custom table colors.
        
    }
    
    It "Remove-ServiceNowAuth works" {
        Remove-ServiceNowAuth | Should be $true
    }
}
