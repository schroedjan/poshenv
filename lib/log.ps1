Import-Module -Name ($PSScriptRoot + "\config.ps1")

$script:LOG_LEVEL=@{
    error = 0
    warn = 1
    info = 2
    debug = 3
    trace = 4
}

$script:LOG_PREFIX = "PoshEnv"
$script:DEFAULT_LOG_LEVEL = "debug"

function Format-Message() {
    param(
        [string]$Message,
        [string]$Prefix="PoshEnv>>",
        [string]$Color="White"
    )
    Write-Host "$Prefix $Message" -ForegroundColor $Color
}

function Get-LogLevel() {
    $LogLevel = Get-PoshEnvConfig "log_level"
    if ($LogLevel -eq $null) {
        $LogLevel = $DEFAULT_LOG_LEVEL
    }
    return $LogLevel
}

function Log-Trace {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-LogLevel)] -ge $script:LOG_LEVEL["trace"]) {
        Format-Message $Message -Color DarkGray
        # Write-Host "TRACE:" $Message -ForegroundColor DarkGray
    }
}

function Log-Debug {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-LogLevel)] -ge $script:LOG_LEVEL["debug"]) {
        Format-Message $Message -Color Cyan
        # Write-Host "DEBUG:" $Message -ForegroundColor Cyan
    }
}

function Log-Info {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-LogLevel)] -ge $script:LOG_LEVEL["info"]) {
        Format-Message $Message -Color Green
        # Write-Host "INFO:" $Message -ForegroundColor Green
    }
}

function Log-Warn {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-LogLevel)] -ge $script:LOG_LEVEL["warn"]) {
        Format-Message $Message -Color Yellow
        # Write-Host "WARN:" $Message -ForegroundColor Yellow
    }
}

function Log-Error {
    param(
        [string]$Message
    )
    if($script:LOG_LEVEL[$(Get-LogLevel)] -ge $script:LOG_LEVEL["error"]) {
        Format-Message $Message -Color Red
        # Write-Host "ERROR:" $Message -ForegroundColor Red
    }
}
