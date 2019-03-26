InModuleScope "ServiceNow" {
    Describe "Get-ServiceNowOAuthToken" {
        BeforeAll {
            Mock Invoke-RestMethod {} -Verifiable
            $uri = 'dev123.service-now.com'
            $Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
        }
        Context "Get-ServiceNowOAuthToken - Should not throw" {
            It "Should not throw when parameters provided" {
                {Get-ServiceNowOAuthToken -Url $uri -Credential $credential -ClientCredential $Credential} | Should -Not -Throw

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
        }
        Context "Get-ServiceNowOAuthToken" {
            BeforeEach {
                Mock Invoke-RestMethod {
                    [pscustomobject]@{
                        'access_token' = ((0..9+'a'..'z'+'A'..'Z') | Get-Random -Count 32) -join ''
                    }
                } -Verifiable
            }
            It "Should return a string" {
                Get-ServiceNowOAuthToken -Url $uri -Credential $Credential -ClientCredential $Credential | Should -BeOfType system.string

                Assert-MockCalled Invoke-RestMethod -Times 1
            }
        }
    }
}