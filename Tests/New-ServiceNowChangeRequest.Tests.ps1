InModuleScope "ServiceNow" {
    Describe "New-ServiceNowChangeRequest" -Tag @('Unit') {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
            $newServiceNowSplat = @{
                Caller           = 'user001'
                ShortDescription = 'Short Description'
            }
        }
        Context "Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script Scoped Auth not set and no explicit Credentials Passed" {

                {New-ServiceNowChangeRequest @newServiceNowSplat} | Should -Throw
            }
        }
        Context "New-ServiceNowChangeRequest - Should Not Throw" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri         = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "New-ServiceNowChangeRequest - Should Not Throw" {
                {New-ServiceNowChangeRequest @newServiceNowSplat} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "New-ServiceNowChangeRequest - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri        = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "New-ServiceNowChangeRequest - Should Not Throw" {
                {New-ServiceNowChangeRequest @newServiceNowSplat} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}