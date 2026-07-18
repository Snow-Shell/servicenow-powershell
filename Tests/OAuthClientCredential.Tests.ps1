$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowSession OAuth Client Credentials Grant' {

    BeforeAll {
        $script:testClientCredential = [PSCredential]::new('myClientId', ('myClientSecret' | ConvertTo-SecureString -AsPlainText -Force))
    }

    Context 'Client credentials grant without proxy' {

        It 'Authenticates using client_credentials grant type' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = '{"access_token": "abc123", "expires_in": 1800}'
                }
            }

            $session = New-ServiceNowSession -Url 'test.service-now.com' -ClientCredential $script:testClientCredential -PassThru

            $session.GrantType | Should -Be 'client_credentials'
            $session.AccessToken | Should -Not -BeNullOrEmpty
            $session.RefreshToken | Should -BeNullOrEmpty
            $session.ClientCredential | Should -Be $script:testClientCredential

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Body.grant_type -eq 'client_credentials'
            }
        }
    }

    Context 'Client credentials grant with proxy' {

        It 'Accepts ClientCredential and Proxy without requiring Credential' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = '{"access_token": "abc123", "expires_in": 1800}'
                }
            }

            $session = New-ServiceNowSession -Url 'test.service-now.com' -ClientCredential $script:testClientCredential -Proxy 'http://proxy.example.com:8080' -PassThru

            $session.GrantType | Should -Be 'client_credentials'
            $session.Proxy | Should -Be 'http://proxy.example.com:8080'

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Proxy -eq 'http://proxy.example.com:8080'
            }
        }

        It 'Accepts ClientCredential, Proxy, and ProxyCredential together' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = '{"access_token": "abc123", "expires_in": 1800}'
                }
            }

            $proxyCred = [PSCredential]::new('proxyuser', ('proxypass' | ConvertTo-SecureString -AsPlainText -Force))

            { New-ServiceNowSession -Url 'test.service-now.com' -ClientCredential $script:testClientCredential -Proxy 'http://proxy.example.com:8080' -ProxyCredential $proxyCred -PassThru } | Should -Not -Throw
        }
    }

    Context 'Password grant still works alongside client credentials support' {

        It 'Authenticates using password grant type when Credential and ClientCredential are both provided' {
            Mock Invoke-WebRequest -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = '{"access_token": "abc123", "refresh_token": "refresh456", "expires_in": 1800}'
                }
            }

            $userCred = [PSCredential]::new('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))

            $session = New-ServiceNowSession -Url 'test.service-now.com' -Credential $userCred -ClientCredential $script:testClientCredential -PassThru

            $session.GrantType | Should -Be 'password'
            $session.RefreshToken | Should -Not -BeNullOrEmpty

            Should -Invoke Invoke-WebRequest -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Body.grant_type -eq 'password'
            }
        }
    }
}

Describe 'Get-ServiceNowAuth Token Refresh Logic' {

    Context 'Client credentials grant refresh' {

        It 'Re-authenticates using client_credentials when token expired and no refresh token exists' {
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    access_token = 'newtoken123'
                    expires_in   = 1800
                }
            }

            $session = @{
                Domain           = 'test.service-now.com'
                BaseUri          = 'https://test.service-now.com/api/'
                Version          = ''
                ClientCredential = [PSCredential]::new('clientid', ('secret' | ConvertTo-SecureString -AsPlainText -Force))
                GrantType        = 'client_credentials'
                ExpiresOn        = (Get-Date).AddMinutes(-5)
            }

            InModuleScope 'ServiceNow' -Parameters @{ session = $session } {
                param($session)
                $result = Get-ServiceNowAuth -ServiceNowSession $session
                $result | Should -Not -BeNullOrEmpty
                $session.AccessToken | Should -Not -BeNullOrEmpty
            }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Body.grant_type -eq 'client_credentials'
            }
        }
    }

    Context 'Password grant refresh' {

        It 'Uses refresh_token grant when a refresh token is available' {
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    access_token  = 'newtoken123'
                    refresh_token = 'newrefresh456'
                    expires_in    = 1800
                }
            }

            $session = @{
                Domain           = 'test.service-now.com'
                BaseUri          = 'https://test.service-now.com/api/'
                Version          = ''
                ClientCredential = [PSCredential]::new('clientid', ('secret' | ConvertTo-SecureString -AsPlainText -Force))
                RefreshToken     = [PSCredential]::new('RefreshToken', ('oldrefresh' | ConvertTo-SecureString -AsPlainText -Force))
                GrantType        = 'password'
                ExpiresOn        = (Get-Date).AddMinutes(-5)
            }

            InModuleScope 'ServiceNow' -Parameters @{ session = $session } {
                param($session)
                $null = Get-ServiceNowAuth -ServiceNowSession $session
                $session.RefreshToken | Should -Not -BeNullOrEmpty
            }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Body.grant_type -eq 'refresh_token'
            }
        }
    }

    Context 'No refresh method available' {

        It 'Warns and does not call Invoke-RestMethod when no refresh token or client credentials grant type exists' {
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}
            Mock Write-Warning -ModuleName 'ServiceNow' {}

            $session = @{
                Domain           = 'test.service-now.com'
                BaseUri          = 'https://test.service-now.com/api/'
                Version          = ''
                ClientCredential = [PSCredential]::new('clientid', ('secret' | ConvertTo-SecureString -AsPlainText -Force))
                AccessToken      = [PSCredential]::new('AccessToken', ('staletoken' | ConvertTo-SecureString -AsPlainText -Force))
                GrantType        = 'password'
                ExpiresOn        = (Get-Date).AddMinutes(-5)
            }

            InModuleScope 'ServiceNow' -Parameters @{ session = $session } {
                param($session)
                $null = Get-ServiceNowAuth -ServiceNowSession $session
            }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 0
            Should -Invoke Write-Warning -ModuleName 'ServiceNow' -Times 1
        }
    }
}
