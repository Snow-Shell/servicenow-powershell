InModuleScope "ServiceNow" {
    Describe "Get-ServiceNowUser" {
        BeforeAll {
            Mock New-ServiceNowQuery {} -Verifiable
        }
        Context "Testing Get-ServiceNowUser - No Script Scoped Auth or Explicit Credentials Passed as arguments" {
            It "Should throw if no authentication set or passed as parameters" {
                {Get-ServiceNowUser} | Should -Throw
            }
        }
        Context "Get-ServiceNowUser - Script Scoped Access Token Set" {
            Mock Get-ServiceNowTable {} -Verifiable
            $script:ConnectionObj = @{
                uri         = 'dev123.service-now.com'
                AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
            }
            It "Should Not Throw When Auth Set" {
                {Get-ServiceNowUser} | Should -Not -Throw
                Assert-MockCalled New-ServiceNowQuery -Times 1
                Assert-MockCalled Get-ServiceNowTable -Times 1
            }
        }
        Context "Get-ServiceNowUser - Script Scoped Credential Set" {
            Mock Get-ServiceNowTable {} -Verifiable
            $setServiceNowAuthSplat = @{
                Url        = 'dev123.service-now.com'
                Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
            }
            Set-ServiceNowAuth @setServiceNowAuthSplat
            It "Should not throw when no parameters provided" {
                {Get-ServiceNowUser} | Should -Not -Throw

                Assert-MockCalled New-ServiceNowQuery -Times 1
                Assert-MockCalled Get-ServiceNowTable -Times 1
            }
            AfterAll {
                $script:ConnectionObj = $null
            }
        }
        Context "Get-ServiceNowUser - Explicitly Passing Credential Parameters" {
            Mock Get-ServiceNowTable {} -Verifiable

            $Uri = 'dev123.service-now.com'
            $Creds = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))

            It "Get-ServiceNowUser - Should not thow when credentials passed as parameters" {
                {Get-ServiceNowUser -ServiceNowURL $uri -Credential $Creds} | Should -Not -Throw

                Assert-MockCalled Get-ServiceNowTable -Times 1
            }
        }
    }
}