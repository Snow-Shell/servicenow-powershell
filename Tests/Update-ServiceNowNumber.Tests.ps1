InModuleScope "ServiceNow" {
    Describe "Update-ServiceNowNumber" -Tag @('Unit') {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
        }
        Context "Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script Scoped Auth not set and no explicit Credentials Passed" {
                {Update-ServiceNowNumber -Table 'incident' -Number 'ABC'} | Should -Throw
            }
        }
        Context "Update-ServiceNowNumber - Should Not Throw" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri         = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
                Mock Get-ServiceNowTableEntry {[pscustomobject]@{sys_id = '123456789'}} -Verifiable
            }
            It "Update-ServiceNowNumber - Should Not Throw" {
                {Update-ServiceNowNumber -Table 'incident' -Number 'ABC'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
                Assert-MockCalled Get-ServiceNowTableEntry -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "Update-ServiceNowNumber - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri        = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
                Mock Get-ServiceNowTableEntry {[pscustomobject]@{sys_id = '123456789'}} -Verifiable
            }
            It "Update-ServiceNowNumber - Should Not Throw" {
                {Update-ServiceNowNumber -Table 'incident' -Number 'ABC'} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
                Assert-MockCalled Get-ServiceNowTableEntry -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}