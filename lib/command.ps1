Import-Module -Name ($PSScriptRoot + "\config.ps1")
Import-Module -Name ($PSScriptRoot + "\authorization.ps1")
# Import-Module -Name ($PSScriptRoot + "\environment.ps1")
# Import-Module -Name ($PSScriptRoot + "\log.ps1")

function poshenv {
    [CmdletBinding()]
    param(
        [parameter(Position=0)]
        [string]$Command="help",
        [parameter(Position=1, ValueFromRemainingArguments=$true)]
        $arguments
    )
    Log-Trace "Command  : $Command"
    Log-Trace "Arguments: $arguments"
    switch ($Command) {
        "allow" { Register-PoshEnv }
        "deny" { Unregister-PoshEnv }
        "config" { Command-Config @arguments}
        "refresh" { Read-PoshEnvConfig }
        default { Show-Help }
    }
}

function Command-Config {
    [CmdletBinding()]
    param(
        [parameter(Position=0)]
        [string]$Command="list",
        [parameter(Position=1, ValueFromRemainingArguments=$true)]
        $arguments
    )
    Log-Trace "Config-Command  : $Command"
    Log-Trace "Config-Arguments: $arguments"
    switch ($Command) {
        "set" { Set-PoshEnvConfig @arguments}
        "get" { Get-PoshEnvConfig @arguments }
        "list" { Get-Content -Path (Get-PoshEnvConfig "file") }
        default { Config-Help }
    }
}

function Show-Help {
    Write-Host "Usage - PoshEnv"
    Write-Host "  poshenv <command>"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host " allow     - Allow env files in current folder. Needs to be run again, when files have changed."
    Write-Host " deny      - Deny env foles in current folder."
    Write-Host " refresh   - Update config from config file."
    Write-Host " help      - Show this help page."
}

function Config-Help {
    Write-Host "Usage - PoshEnv"
    Write-Host "  poshenv config <command>"
    Write-Host "  poshenv config list"
    Write-Host "  poshenv config get <key>"
    Write-Host "  poshenv config set <key> <value>"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host " list     - List all current settings."
    Write-Host " get      - Get setting with given name."
    Write-Host " set      - Set setting with given name to given value."
    Write-Host " help     - Show this help page."
}