InModuleScope "ServiceNow" {
    Describe "Get-ServiceNowFullUri" {
        BeforeAll {
            $uri = 'test.service-now.com'
        }
        Context "Get-ServiceNowFullUri" {
            It "Should not throw when parameters provided" {
                {Get-ServiceNowFullUri -Uri $uri -Table 'incident'} | Should -Not -Throw
            }
            It "Should return a string" {
                Get-ServiceNowFullUri -Uri $uri -Table 'incident' | Should -BeOfType system.string
            }
            It "Should have the correct URI format" {
                Get-ServiceNowFullUri -Uri $uri -Table 'incident' | Should -Match '^(https:\/\/)(\w+\..*\.\w+)(\/\w+){5}$'
            }
        }
    }
}