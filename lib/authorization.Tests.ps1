BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    . "$PSScriptRoot/log.ps1"
}


Describe "Test Authentication Library" {
    Context "Register-PoshEnv" {
        BeforeAll {
            function Get-PoshEnvConfig($Key) {}
            Mock Get-PoshEnvConfig { "current_folder" } -ParameterFilter { $Key -eq "search_mode" }
            Mock Get-PoshEnvConfig { @(".env") } -ParameterFilter { $Key -eq "posh_env_files" }
            Mock Allow-File {}
            Mock Save-AllowedPaths {}
            Mock List-Files { @("mockedFile\.env") }
            Mock Get-FileInfo {}

        }
        It "succeeds" {
            { Register-PoshEnv -p $tmpDir } | Should -Not -Throw
        }
        It "allows File" {
            Register-PoshEnv -p $tmpDir
            Should -Invoke -CommandName Allow-File -Times 1
        }
        It "saves allowed files" {
            Register-PoshEnv -p $tmpDir
            Should -Invoke -CommandName Save-AllowedPaths -Times 1
        }
    }

    Context "Unregister-PoshEnv" {
        BeforeAll {
            function Get-PoshEnvConfig($Key) {}
            Mock Get-PoshEnvConfig { "current_folder" } -ParameterFilter { $Key -eq "search_mode" }
            Mock Get-PoshEnvConfig { @(".env") } -ParameterFilter { $Key -eq "posh_env_files" }
            Mock Deny-File {}
            Mock Save-AllowedPaths {}
            Mock List-Files { @("mockedFile\.env") }
            Mock Get-FileInfo {}
        }
        It "succeeds" {
            { Unregister-PoshEnv -p $tmpDir } | Should -Not -Throw
        }
        It "denys File" {
            Unregister-PoshEnv -p $tmpDir
            Should -Invoke -CommandName Deny-File -Times 1
        }
        It "saves allowed files" {
            Unregister-PoshEnv -p $tmpDir
            Should -Invoke -CommandName Save-AllowedPaths -Times 1
        }
    }

    Context "Initialize-AllowedPaths" {
        BeforeAll {
            $tmpDir = Join-Path $env:TEMP $(New-Guid)
            New-Item -ItemType "directory" -Path $tmpDir
            $tmpAllowedPaths = $(New-Item -ItemType "file" -Path "$tmpDir\allowedPaths")

            function Get-PoshEnvConfig($Key) {}
            Mock Get-PoshEnvConfig { $tmpDir } -ParameterFilter { $Key -eq "dir" }
            Mock Get-PoshEnvConfig { "allowedPaths" } -ParameterFilter { $Key -eq "allowed_path_file" }
            Mock Load-AllowedPaths {}
        }
        AfterAll {
            Remove-Item -Recurse -Force $tmpDir
        }
        It "succeeds" {
            { Initialize-AllowedPaths } | Should -Not -Throw
        }
        It "loads allowed paths" {
            Initialize-AllowedPaths | Should -Invoke -CommandName Load-AllowedPaths -Times 1
        }
    }

    Context "Load-AllowedPaths" {
        BeforeAll {
            $tmpDir = Join-Path $env:TEMP $(New-Guid)
            New-Item -ItemType "directory" -Path $tmpDir
            $tmpAllowedPathsFile = $(New-Item -ItemType "file" -Path "$tmpDir\allowedPaths")

            function Get-PoshEnvConfig($Key) {}
            Mock Get-PoshEnvConfig { $tmpDir } -ParameterFilter { $Key -eq "dir" }
            Mock Get-PoshEnvConfig { "allowedPaths" } -ParameterFilter { $Key -eq "allowed_path_file" }

        }
        AfterAll {
            Remove-Item -Recurse -Force $tmpDir
            $script:AllowedPaths = @{}
        }
        It "succeeds" {
            { Load-AllowedPaths } | Should -Not -Throw
        }
        It "initializes empty array" {
            $($script:AllowedPaths.Count) | Should -Be 0
            Load-AllowedPaths
            $($script:AllowedPaths.Count) | Should -Be 0
        }
        It "loads allowed paths" {
            Write-Output '{"C:\\tmp\\test\\.envrc": "2023-01-09T10:43:34.1656825+01:00",}' | Out-File -FilePath $tmpAllowedPathsFile
            $($script:AllowedPaths.Count) | Should -Be 0
            Load-AllowedPaths
            $($script:AllowedPaths.Count) | Should -Be 1
        }
    }

    Context "Save-AllowedPaths" {
        BeforeAll {
            $tmpDir = Join-Path $env:TEMP $(New-Guid)
            New-Item -ItemType "directory" -Path $tmpDir
            $tmpAllowedPathsFile = $(New-Item -ItemType "file" -Path "$tmpDir\allowedPaths")

            function Get-PoshEnvConfig($Key) {}
            Mock Get-PoshEnvConfig { $tmpDir } -ParameterFilter { $Key -eq "dir" }
            Mock Get-PoshEnvConfig { "allowedPaths" } -ParameterFilter { $Key -eq "allowed_path_file" }

        }
        AfterAll {
            Remove-Item -Recurse -Force $tmpDir
            $script:AllowedPaths = @{}
        }
        It "succeeds" {
            { Save-AllowedPaths } | Should -Not -Throw
        }
        It "saves allowed paths" {
            $(Get-Content (Join-Path $(Get-PoshEnvConfig "dir") $(Get-PoshEnvConfig "allowed_path_file"))) | Should -Be "{}"
            $testFile = @{
                FullName = "FullName"
                LastWriteTime = "LastWriteTime"
            }
            $script:AllowedPaths[$testFile.FullName] = $testFile.LastWriteTime
            { Save-AllowedPaths } | Should -Not -Throw
            $(Get-Content (Join-Path $(Get-PoshEnvConfig "dir") $(Get-PoshEnvConfig "allowed_path_file"))) | Should -Be @("{", "  `"FullName`": `"LastWriteTime`"", "}")
        }
    }

    Context "Allow-File" {
        BeforeAll {
            # $tmpDir = Join-Path $env:TEMP $(New-Guid)
            # New-Item -ItemType "directory" -Path $tmpDir
            # $tmpAllowedPathsFile = $(New-Item -ItemType "file" -Path "$tmpDir\allowedPaths")
            $script:AllowedPaths = @{}

            function Log-Info {}
            Mock Log-Info {}
            function Force-PoshEnvReload {}
            Mock Force-PoshEnvReload {}
            function Resolve-Path {}
            Mock Resolve-Path { "FullNameRelative" }

        }
        AfterAll {
            # Remove-Item -Recurse -Force $tmpDir
            $script:AllowedPaths = @{}
        }
        It "succeeds" {
            $testFile = @{
                FullName = "FullName"
                LastWriteTime = "LastWriteTime"
            }
            { Allow-File $testFile } | Should -Not -Throw
        }
        It "adds file to allowedPaths" {
            $($script:AllowedPaths.Count) | Should -Be 0
            $testFile = @{
                FullName = "FullName"
                LastWriteTime = "LastWriteTime"
            }
            { AllowFile $testFile } | Should -Not -Throw
            $($script:AllowedPaths.Count) | Should -Be 1
        }
    }
}
