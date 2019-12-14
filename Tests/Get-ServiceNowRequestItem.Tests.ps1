InModuleScope "ServiceNow" {
    Describe "Get-ServiceNowRequestItem" {
        BeforeAll {
            Mock New-ServiceNowQuery {} -Verifiable
        }
        Context "Get-ServiceNowRequestItem with no script scoped Auth set and no explicit credentials passed" {
            It "Should Throw if script scoped auth not set and no explicit credentials passed" {
                {Get-ServiceNowRequestItem} | Should -Throw
            }
        }
        Context "Get-ServiceNowRequestItem - Script Scoped Access Token Set" {
            Mock Get-ServiceNowTable {} -Verifiable

            $Script:ConnectionObj = @{
                uri         = 'dev123.service-now.com'
                AccessToken = -join ((0..9 + 'a'..'z' + 'A'..'Z') | Get-Random -Count 32)
            }
            It "Should Not Throw" {
                {Get-ServiceNowRequestItem} | Should -Not -Throw

                Assert-MockCalled New-ServiceNowQuery -Times 1
                Assert-MockCalled Get-ServiceNowTable -Times 1
            }
        }
        Context "Get-ServiceNowIncident Script Scoped PSCredential Set" {
            Mock Get-ServiceNowTable {} -Verifiable
            $setServiceNowAuthSplat = @{
                Url        = 'dev123.service-now.com'
                Credential = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))
            }
            Set-ServiceNowAuth @setServiceNowAuthSplat
            It "Should not throw when no parameters provided" {
                {Get-ServiceNowRequestItem} | Should -Not -Throw

                Assert-MockCalled New-ServiceNowQuery -Times 1
                Assert-MockCalled Get-ServiceNowTable -Times 1
            }
        }
        Context "Get-ServiceNowRequestItem - Explicitly passing Credential Parameters" {
            Mock Get-ServiceNowTable {} -Verifiable
            $Uri = 'dev123.service-now.com'
            $Creds = ([pscredential]::new('testuser', ('Password1' | ConvertTo-SecureString -AsPlainText -Force)))

            It "Should not throw when credentials passed as parameters" {
                {Get-ServiceNowRequestItem -ServiceNowURL $Uri -Credential $Creds} | Should -Not -Throw

                Assert-MockCalled New-ServiceNowQuery -Times 1
                Assert-MockCalled Get-ServiceNowTable -Times 1
            }
        }
    }
}