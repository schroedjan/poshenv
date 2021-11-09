Import-Module -Name ($PSScriptRoot + "\config.ps1")

$script:LOG_LEVEL=@{
    error = 0
    warn = 1
    info = 2
    debug = 3
    trace = 4
}

function Log-Trace {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-PoshEnvConfig "log_level")] -ge $script:LOG_LEVEL["trace"]) {
        Write-Host "TRACE:" $Message -ForegroundColor DarkGray
    }
}

function Log-Debug {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-PoshEnvConfig "log_level")] -ge $script:LOG_LEVEL["debug"]) {
        Write-Host "DEBUG:" $Message -ForegroundColor Cyan
    }
}

function Log-Info {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-PoshEnvConfig "log_level")] -ge $script:LOG_LEVEL["info"]) {
        Write-Host "INFO:" $Message -ForegroundColor Green
    }
}

function Log-Warn {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-PoshEnvConfig "log_level")] -ge $script:LOG_LEVEL["warn"]) {
        Write-Host "WARN:" $Message -ForegroundColor Yellow
    }
}

function Log-Error {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-PoshEnvConfig "log_level")] -ge $script:LOG_LEVEL["error"]) {
        Write-Host "ERROR:" $Message -ForegroundColor Red
    }
}