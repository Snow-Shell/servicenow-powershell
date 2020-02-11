InModuleScope "ServiceNow" {
    Describe "Get-ServiceNowTableEntry" -Tag @('unit') {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
        }
        Context "Get-ServiceNowTableEntry - Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script scoped Auth not set and no explicit Credentials Passed" {
                {Get-ServiceNowTableEntry -Table 'incident' -ErrorAction Stop} | Should -Throw
            }
        }
        Context "Get-ServiceNowTableEntry - Script Scoped Access Token Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "Get-ServiceNowTableEntry - Should Not Throw" {
                {Get-ServiceNowTableEntry -Table 'incident'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "Get-ServiceNowTableEntry - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "Get-ServiceNowTableEntry - Should Not Throw" {
                {Get-ServiceNowTableEntry -Table 'incident'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}
