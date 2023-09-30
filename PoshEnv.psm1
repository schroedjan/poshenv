# -----------------------------------------------------------------------------
# Load Lib
# -----------------------------------------------------------------------------
Get-ChildItem "$PSScriptRoot/lib/*.ps1" |
    ? { $_.Name -notlike "*.Tests.*" } |
    % { . $_.PSPath }


# -----------------------------------------------------------------------------
# Initialize Config
# -----------------------------------------------------------------------------
Initialize-PoshEnvConfig
Initialize-AllowedPaths


# -----------------------------------------------------------------------------
# Hook into Prompt
# -----------------------------------------------------------------------------
if (Test-Path Function:\PromptBackup) {
    Write-Host "Prompt Backup already existing"
}

if (Test-Path Function:\Prompt) {
    Rename-Item Function:\Prompt global:PromptBackup
}

function global:Prompt {
    try {
        Set-PoshEnv | Out-Null

        # Fall back on existing Prompt function
        if (Test-Path Function:\PromptBackup) {
            PromptBackup
        }
    }
    catch {
        Write-Error "Error in env definition. $($_.Exception.Message) >"
    }
}
