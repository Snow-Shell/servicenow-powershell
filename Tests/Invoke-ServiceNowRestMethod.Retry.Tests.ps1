$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Invoke-ServiceNowRestMethod Retry Logic' {

    BeforeAll {
        $script:testSession = @{
            Domain              = 'test.service-now.com'
            BaseUri             = 'https://test.service-now.com/api/'
            Version             = ''
            Credential          = [PSCredential]::new('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
            RetryCount          = 2
            RetryWaitSeconds    = 1
            MaxRetryAfterSeconds = 10
        }
    }

    Context 'Retries on retryable HTTP status codes' {

        It 'Retries on HTTP <StatusCode> and succeeds on next attempt' -TestCases @(
            @{ StatusCode = 429 }
            @{ StatusCode = 502 }
            @{ StatusCode = 503 }
            @{ StatusCode = 504 }
            @{ StatusCode = 408 }
            @{ StatusCode = 409 }
        ) {
            param($StatusCode)

            $global:retryTestCallCount = 0
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                $global:retryTestCallCount++
                if ($global:retryTestCallCount -eq 1) {
                    $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]$StatusCode)
                    $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new("HTTP $StatusCode", $response)
                    throw $exception
                }
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = '{"result": [{"sys_id": "abc123"}]}'
                    Headers    = @{ 'X-Total-Count' = '1' }
                }
            }

            Mock Start-Sleep -ModuleName 'ServiceNow' {}

            InModuleScope 'ServiceNow' -Parameters @{ testSession = $script:testSession } {
                param($testSession)
                Mock Get-ServiceNowAuth {
                    @{
                        Uri     = 'https://test.service-now.com/api/'
                        Headers = @{ Authorization = 'Basic dXNlcjpwYXNz' }
                    }
                }

                $result = Invoke-ServiceNowRestMethod -Table 'incident' -ServiceNowSession $testSession
                $result | Should -Not -BeNullOrEmpty
            }

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 2 -Exactly
            Should -Invoke Start-Sleep -ModuleName 'ServiceNow' -Times 1
            Remove-Item -Path 'variable:global:retryTestCallCount' -ErrorAction SilentlyContinue
        }
    }

    Context 'Does not retry on non-retryable status codes' {

        It 'Throws immediately on HTTP 401' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]401)
                $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new("HTTP 401", $response)
                throw $exception
            }

            Mock Start-Sleep -ModuleName 'ServiceNow' {}

            InModuleScope 'ServiceNow' -Parameters @{ testSession = $script:testSession } {
                param($testSession)
                Mock Get-ServiceNowAuth {
                    @{
                        Uri     = 'https://test.service-now.com/api/'
                        Headers = @{ Authorization = 'Basic dXNlcjpwYXNz' }
                    }
                }

                { Invoke-ServiceNowRestMethod -Table 'incident' -ServiceNowSession $testSession } | Should -Throw
            }

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName 'ServiceNow' -Times 0
        }
    }

    Context 'Exhausts retries and throws' {

        It 'Throws after exhausting all retry attempts' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]429)
                $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new("HTTP 429", $response)
                throw $exception
            }

            Mock Start-Sleep -ModuleName 'ServiceNow' {}

            InModuleScope 'ServiceNow' -Parameters @{ testSession = $script:testSession } {
                param($testSession)
                Mock Get-ServiceNowAuth {
                    @{
                        Uri     = 'https://test.service-now.com/api/'
                        Headers = @{ Authorization = 'Basic dXNlcjpwYXNz' }
                    }
                }

                { Invoke-ServiceNowRestMethod -Table 'incident' -ServiceNowSession $testSession } | Should -Throw
            }

            # 1 initial + 2 retries = 3 total calls
            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 3 -Exactly
            Should -Invoke Start-Sleep -ModuleName 'ServiceNow' -Times 2
        }
    }

    Context 'Succeeds without retry on first attempt' {

        It 'Does not retry when the first request succeeds' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = '{"result": [{"sys_id": "abc123"}]}'
                    Headers    = @{ 'X-Total-Count' = '1' }
                }
            }

            Mock Start-Sleep -ModuleName 'ServiceNow' {}

            InModuleScope 'ServiceNow' -Parameters @{ testSession = $script:testSession } {
                param($testSession)
                Mock Get-ServiceNowAuth {
                    @{
                        Uri     = 'https://test.service-now.com/api/'
                        Headers = @{ Authorization = 'Basic dXNlcjpwYXNz' }
                    }
                }

                $result = Invoke-ServiceNowRestMethod -Table 'incident' -ServiceNowSession $testSession
                $result | Should -Not -BeNullOrEmpty
            }

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName 'ServiceNow' -Times 0
        }
    }

    Context 'Retry disabled when RetryCount is 0' {

        It 'Throws immediately when RetryCount is 0' {
            $noRetrySession = @{
                Domain              = 'test.service-now.com'
                BaseUri             = 'https://test.service-now.com/api/'
                Version             = ''
                Credential          = [PSCredential]::new('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
                RetryCount          = 0
                RetryWaitSeconds    = 1
                MaxRetryAfterSeconds = 10
            }

            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]429)
                $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new("HTTP 429", $response)
                throw $exception
            }

            Mock Start-Sleep -ModuleName 'ServiceNow' {}

            InModuleScope 'ServiceNow' -Parameters @{ noRetrySession = $noRetrySession } {
                param($noRetrySession)
                Mock Get-ServiceNowAuth {
                    @{
                        Uri     = 'https://test.service-now.com/api/'
                        Headers = @{ Authorization = 'Basic dXNlcjpwYXNz' }
                    }
                }

                { Invoke-ServiceNowRestMethod -Table 'incident' -ServiceNowSession $noRetrySession } | Should -Throw
            }

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName 'ServiceNow' -Times 0
        }
    }
}

Describe 'New-ServiceNowSession Retry Parameters' {

    It 'Session includes default retry settings' {
        Mock Invoke-WebRequest -ModuleName 'ServiceNow' {}

        $session = New-ServiceNowSession -Url 'test.service-now.com' -Credential ([PSCredential]::new('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))) -PassThru

        $session.RetryCount | Should -Be 2
        $session.RetryWaitSeconds | Should -Be 5
        $session.MaxRetryAfterSeconds | Should -Be 10
    }

    It 'Session includes custom retry settings' {
        Mock Invoke-WebRequest -ModuleName 'ServiceNow' {}

        $session = New-ServiceNowSession -Url 'test.service-now.com' -Credential ([PSCredential]::new('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))) -RetryCount 5 -RetryWaitSeconds 10 -MaxRetryAfterSeconds 30 -PassThru

        $session.RetryCount | Should -Be 5
        $session.RetryWaitSeconds | Should -Be 10
        $session.MaxRetryAfterSeconds | Should -Be 30
    }
}
