InModuleScope "ServiceNow" {
    Describe "New-ServiceNowConnection" -Tag @('unit') {
        Context "New-ServiceNowConnection - Should Throw if Script Scoped Auth Not Set" {
            It "Should Throw if Script Scoped Auth Not Set and ConnectionObject Not Passed as Parameter" {
                {New-ServiceNowConnection -Table 'incident'} | Should -Throw
            }
        }
        Context "New-ServiceNowConnection -  Script Scoped Access Token Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "Should not throw" {
                {New-ServiceNowConnection -Table 'incident'} | Should -Not -Throw
            }
            It "Should return a hashtable" {
                New-ServiceNowConnection -Table 'incident' | Should -BeOfType Hashtable
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "New-ServiceNowConnection -  Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "Should not throw" {
                {New-ServiceNowConnection -Table 'incident'} | Should -Not -Throw
            }
            It "Should return a hashtable" {
                New-ServiceNowConnection -Table 'incident' | Should -BeOfType Hashtable
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "New-ServiceNowConnection -  Azure Automation Authentication" {
            BeforeAll {
                $AzureConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    user = 'user001'
                    pass = 'Password1'
                }
            }
            It "Should not throw" {
                {New-ServiceNowConnection -Table 'incident' -ConnectionObject $AzureConnectionObj} | Should -Not -Throw
            }
            It "Should return a hashtable" {
                New-ServiceNowConnection -Table 'incident' -ConnectionObject $AzureconnectionObj | Should -BeOfType Hashtable
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}