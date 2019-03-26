InModuleScope "ServiceNow" {
    Describe "Get-ServiceNowTable" {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
        }
        Context "Get-ServiceNowTable - Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script scoped Auth not set and no explicit Credentials Passed" {
                {Get-ServiceNowtable -Table 'incident'} | Should -Throw
            }
        }
        Context "Get-ServiceNowTable - Script Scoped Access Token Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "Get-ServiceNowTable - Should Not Throw" {
                {Get-ServiceNowTable -Table 'incident'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "Get-ServiceNowTable - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "Get-ServiceNowTable - Should Not Throw" {
                {Get-ServiceNowTable -Table 'incident'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}
