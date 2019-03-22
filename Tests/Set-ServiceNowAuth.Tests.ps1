InModuleScope "ServiceNow" {
    Describe "Set-ServiceNowAuth" {
        BeforeAll {
            Mock Get-ServiceNowOAuthToken {(-join ((33..126) | Get-Random -Count 32 | ForEach-Object {[char]$_}))} -Verifiable
        }
        Context "Testing Script Scoped OAuth Authentication" {
            BeforeAll {
                $setServiceNowAuthSplat = @{
                    Url              = 'dev123.service.now.com'
                    ClientCredential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                    UserCredential   = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
                Set-ServiceNowAuth @setServiceNowAuthSplat
            }
            It "Script Scoped ConnectionObj Variable Should Exist" {
                $Script:ConnectionObj | Should -Not -BeNullOrEmpty
            }
            It "Script Scoped ConnectionObj is of TYPE hashtable" {
                $Script:ConnectionObj | Should -BeOfType hashtable
                Assert-MockCalled Get-ServiceNowOAuthToken -Scope Context -Times 1
            }
            It "Script Scoped ConnectionObj Uri matches the ServiceNow Uri format" {
                $script:ConnectionObj['uri'] | Should -Match '^\w+\..*\.\w+'
            }
            It "Script SCoped ConnectionObj AccessToken is of TYPE string" {
                $script:ConnectionObj['AccessToken'] | Should -BeOfType System.String
            }
            AfterAll {
                $Script:ConnectionObj
            }
        }
        Context "Testing Script Scoped Credential Authentication" {
            BeforeAll {
                $setServiceNowAuthSplat = @{
                    Url        = 'dev123.service-now.com'
                    Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
                }
                Set-ServiceNowAuth @setServiceNowAuthSplat
            }
            It "Script Scoped ConnectionObj Variable Should Exist" {
                $Script:ConnectionObj | Should -Not -BeNullOrEmpty
            }
            It "Script Scoped ConnectionObj is of TYPE hashtable" {
                $Script:ConnectionObj | Should -BeOfType hashtable
            }
            It "Script Scoped ConnectionObj Uri matches the ServiceNow Uri format" {
                $script:ConnectionObj['uri'] | Should -Match '^\w+\..*\.\w+'
            }
            It "Script Scoped ConnectionObj Credential is of TYPE string" {
                $script:ConnectionObj['Credential'] | Should -BeOfType [PSCredential]
            }
            AfterAll {
                $Script:ConnectionObj = $null
            }
        }
    }
}