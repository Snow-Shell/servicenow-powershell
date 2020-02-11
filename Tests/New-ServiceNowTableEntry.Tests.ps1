InModuleScope "ServiceNow" {
    Describe "New-ServiceNowTableEntry" -Tag @('Unit') {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
        }
        Context "Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script Scoped Auth not set and no explicit Credentials Passed" {
                {New-ServiceNowTableEntry -Table 'incident'} | Should -Throw
            }
        }
        Context "New-ServiceNowTableEntry - Should Not Throw" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri         = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "New-ServiceNowTableEntry - Should Not Throw" {
                {New-ServiceNowTableEntry -Table 'incident'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "New-ServiceNowTableEntry - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri        = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "New-ServicNowTableEntry - Should Not Throw" {
                {New-ServiceNowTableEntry -Table 'incident'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}