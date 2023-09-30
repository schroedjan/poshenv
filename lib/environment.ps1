Import-Module -Name ($PSScriptRoot + "\authorization.ps1")
Import-Module -Name ($PSScriptRoot + "\log.ps1")
Import-Module -Name ($PSScriptRoot + "\config.ps1")
Import-Module -Name ($PSScriptRoot + "\preprocessor.ps1")
Import-Module -Name ($PSScriptRoot + "\util.ps1")

function Set-PoshEnv {
    Param (
        [Alias("d")]
        $Dir=$pwd
    )
    Log-Trace "BEGIN - Set-PoshEnv"

    # Find candidates in current Folder
    $script:candidates = New-Object System.Collections.ArrayList
    $script:allowed = New-Object System.Collections.ArrayList
    List-Files -d $Dir | % {
        if ((Check-File $_)) {
            $script:allowed.Add($_)
        } else {
            $script:candidates.Add($_)
        }
    }
    Log-Debug "Candidates: $($script:candidates | % { Split-Path -Path $_ -Leaf })"
    Log-Debug "Allowed   : $($script:allowed | % { Split-Path -Path $_ -Leaf })"

    # Show candidates if config set
    if (Get-PoshEnvConfig "show_candidates") {
        $script:candidates | % {
            Log-Info "Found envfile '$($_ | Resolve-Path -Relative)' that is not allowed. Run 'poshenv allow' to allow file."
        }
    }

    # Only evaluate Envs if needed
    if (Needs-Reload) {
        # Restore Previous Env, if existing
        Restore-Env

        if ($script:allowed.Length -gt 0 ) {
            Log-Debug "Evaluating allowed env files."
            # Backup Current Env
            Backup-Env
            # Apply env files
            Apply-Env
        }

        $script:lastApplied = $($script:allowed | ConvertTo-Json | Get-Hash)
        if ($script:ForceReload) { Remove-Variable -Name "ForceReload" -Scope script }
    }

    Log-Trace "END - Set-PoshEnv"
}

function Needs-Reload() {
    Log-Trace "BEGIN - Needs-Reload()"
    $Reload = $False
    if ($script:ForceReload) {
        Log-Debug "Reload forced."
        $Reload = $True
    }
    $currentHash = $script:allowed | ConvertTo-Json | Get-Hash
    Log-Trace "CurrentHash: $currentHash"
    Log-Trace "LastHash   : $script:lastApplied"
    if ($script:lastApplied -ne $currentHash) {
        Log-Debug "Allowed files changed. Reloading."
        $Reload = $True
    }
    Log-Trace "END - Needs-Reload()"
    return $Reload
}

function Backup-Env {
    Log-Trace "BEGIN - Backup-Env"
    Log-Debug "Saving current Environment"
    $script:EnvBackup = Get-ChildItem env:
    Log-Trace "END - Backup-Env"
}

function Restore-Env {
    Log-Trace "BEGIN - Restore-Env"
    if ($script:EnvBackup) {
        Log-Debug "Restoring from EnvBackup "
        Log-Info "Unloading"
        # Only iterate once through current environment for peformance.
        # This restore will NOT recover env vars you deleted in your local env file.
        Get-ChildItem env: | % {
            $found = $script:EnvBackup | where Key -eq $_.Key
            if ($found) {
                Log-Trace "$($_.Key) found in Backup"
                if ($_.Value -ne $found.Value) {
                    Log-Trace "-> $($_.Key) - Restoring old Value $($found.Value)"
                    Set-Item "env:$($_.Key)" $found.Value
                }
            } else {
                Log-Trace "$($_.Key) not found in Backup. Removing Environment Variable."
                Remove-Item "env:$($_.Key)"
            }
        }
        Remove-Variable -Name "EnvBackup" -Scope script
    } else {
        Log-Debug "No EnvBackup exists."
    }
    Log-Trace "END - Restore-Env"
}

function Apply-Env {
    Log-Trace "BEGIN - Apply-Env"
    $script:allowed | % {
        Log-Info "Loading $($_ | Resolve-Path -Relative)."
        Apply-File $_
    }
    Log-Trace "END - Apply-Env"
}

function Force-PoshEnvReload {
    Log-Trace "BEGIN - Force-PoshEnvReload"
    $script:ForceReload = $True
    Log-Trace "END - Force-PoshEnvReload"
}
