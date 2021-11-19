Set-Variable -Name "ConfigDirBase" -Value ([string]".config") -Scope script
Set-Variable -Name "ConfigDirPoshEnv" -Value ([string]"poshenv") -Scope script
Set-Variable -Name "ConfigFileName" -Value ([string]"config.json") -Scope script

function Initialize-PoshEnvConfig {
    Set-Variable -Name "ConfigDir" -Value ([string]"$env:POSH_ENV_CONFIG_DIR") -Scope script
    if (-not $script:ConfigDir) {
        if ($env:HOME) {
            $script:ConfigDirBase = Join-Path $env:HOME ".config" 
            $script:ConfigDir = Join-Path $script:ConfigDirBase $script:ConfigDirPoshEnv
        } else {
            $script:ConfigDirBase = Join-Path $env:USERPROFILE ".config" 
            $script:ConfigDir = Join-Path $script:ConfigDirBase $script:ConfigDirPoshEnv
        }
    }
    Set-Variable -Name "ConfigFile" -Value ([string]"$(Join-Path $script:ConfigDir $script:ConfigFileName)") -Scope script

    # Init Folders and Files if not existing
    if (-not (Test-Path $script:ConfigDirBase)) { New-Item -ItemType "directory" -Path $script:ConfigDirBase }
    if (-not (Test-Path $script:ConfigDir)) { New-Item -ItemType "directory" -Path $script:ConfigDir }
    if (-not (Test-Path $script:ConfigFile)) {
        New-Item -ItemType "file" -Path $script:ConfigFile
        # init default values
        New-Variable -Name "PoshEnvConfig" -Value @{} -Scope script
        Set-PoshEnvConfig "posh_env_files" @(".envrc", ".env")
        Set-PoshEnvConfig "allowed_path_file" "allowed_paths.json"
        Set-PoshEnvConfig "log_level" "info"
        Set-PoshEnvConfig "show_candidates" $True
        Save-PoshEnvConfig
    } else {
        Read-PoshEnvConfig
    }
}

function Read-PoshEnvConfig {
    Set-Variable -Name "PoshEnvConfig" -Value $(Get-Content -Raw -Path $script:ConfigFile | ConvertFrom-Json) -Scope script
}

function Save-PoshEnvConfig {
    $script:PoshEnvConfig | ConvertTo-Json | Out-File -FilePath $script:ConfigFile
}

function Get-PoshEnvConfig {
    [CmdletBinding()]
    Param (
        [Alias("k")]
        $Key
    )
    if ([string]::IsNullOrEmpty($key)) {
        return $null
    }
    switch ($key) {
        "dir" {
            return $script:ConfigDir
        }
        "file" {
            return $script:ConfigFile
        }
        default {
            return $script:PoshEnvConfig.$key
        }
    }
}

function Set-PoshEnvConfig {
    [CmdletBinding()]
    param(
        [string]$Key,
        $Val
    )
    $script:PoshEnvConfig["$Key"]=$Val
    Save-PoshEnvConfig
}