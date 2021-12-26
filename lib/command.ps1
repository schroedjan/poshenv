Import-Module -Name ($PSScriptRoot + "\config.ps1")
Import-Module -Name ($PSScriptRoot + "\authorization.ps1")
Import-Module -Name ($PSScriptRoot + "\preprocessor.ps1")
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
        "config" { Command-Config @arguments }
        "refresh" { Read-PoshEnvConfig }
        "list" { List-Files $pwd }
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

function Complete-PoshEnv {
    param($commandName, $wordToComplete, $cursorPosition)

    $cmd = -split $wordToComplete
    switch ($($cmd[1])) {
        "config" {
            switch ($($cmd[2])) {
                "get" {}
                "set" {}
                "list" {}
                default {
                    @("list", "get", "set") | Where-Object {
                        $_ -like "${commandName}*"
                    } | ForEach-Object {
                        "$_"
                    }
                }
            }
        }
        default {
            # Handle main command completion
            @("allow", "deny", "config", "refresh", "help") | Where-Object {
                $_ -like "${commandName}*"
            } | ForEach-Object {
                "$_"
            }
        }
    }
}

function Register-PoshEnvCompletion {
    Register-ArgumentCompleter -Native -CommandName poshenv -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        Complete-PoshEnv @PsBoundParameters
    }
}

function Show-Help {
    Write-Host @"
Usage - PoshEnv
    poshenv <command>

Commands:
    allow     - Allow env files in current folder. Needs to be run again, when files have changed.
    deny      - Deny env foles in current folder.
    config    - View and edit poshenv configuration.
    refresh   - Update config from config file.
    help      - Show this help page.

Argument Completion:

    For automatic argument completion, add the following to your profile.
        Register-PoshEnvCompletion
"@

}

function Config-Help {
    Write-Host @"
Usage - PoshEnv Config
    poshenv config <command>
    poshenv config list
    poshenv config get <key>
    poshenv config set <key> <value>

Commands:
    list     - List all current settings.
    get      - Get setting with given name.
    set      - Set setting with given name to given value.
    help     - Show this help page.
"@
}
