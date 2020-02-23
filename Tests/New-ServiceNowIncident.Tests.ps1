InModuleScope "ServiceNow" {
    Describe "New-ServiceNowIncident" -Tag @('Unit') {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
            $newServiceNowSplat = @{
                Caller           = 'user001'
                ShortDescription = 'Short Description'
            }
        }
        Context "Calling with no script scoped Auth set and no explicity credentials passed" {
            It "Should Throw if Script Scoped Auth not set and no explicit Credentials Passed" {

                {New-ServiceNowIncident @newServiceNowSplat} | Should -Throw
            }
        }
        Context "New-ServiceNowIncident - Should Not Throw" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri         = 'dev123.service-now.com'
                    AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
                }
            }
            It "New-ServiceNowIncident - Should Not Throw" {
                {New-ServiceNowIncident @newServiceNowSplat} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
        Context "New-ServiceNowIncident - Script Scoped PSCredential Set" {
            BeforeAll {
                $Script:ConnectionObj = @{
                    uri        = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
            }
            It "New-ServiceNowIncident - Should Not Throw" {
                {New-ServiceNowIncident @newServiceNowSplat} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}