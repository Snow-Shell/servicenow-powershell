InModuleScope "ServiceNow" {
    Describe "Update-ServiceNowRequestItem" -Tag @('Unit') {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
        }
        Context "Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script Scoped Auth not set and no explicit Credentials Passed" {

                {Update-ServiceNowRequestItem -SysId 'ABC' -Values @{assignee = 'user1'}} | Should -Throw
            }
        }
        Context "Update-ServiceNowRequestItem - Should Not Throw" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri         = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "Update-ServiceNowRequestItem - Should Not Throw" {
                {Update-ServiceNowRequestItem -SysId 'ABC' -Values @{assignee = 'user1'}} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "Update-ServiceNowRequestItem - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri        = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "Update-ServiceNowRequestItem - Should Not Throw" {
                {Update-ServiceNowRequestItem -SysId 'ABC' -Values @{assignee = 'user1'}} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}