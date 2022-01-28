Import-Module -Name ($PSScriptRoot + "\log.ps1")
Import-Module -Name ($PSScriptRoot + "\config.ps1")

### Public Functions ######################################################################
function Register-PoshEnv {
    [CmdletBinding()]
    Param (
        [Alias("p")]
        $Path=$pwd
    )
    Log-Trace "BEGIN - Register-PoshEnv"
    $files = (List-Files $Path)
    if ($files.Count -eq 0) {
        Log-Debug "No candidates in current folder."
    } elseif ($($files.Count) -gt 1) {
        Allow-File (Get-FileInfo $files[$(Select-File $files "Wnich file to allow?")])
        Save-AllowedPaths
    } else {
        Allow-File (Get-FileInfo $files)
        Save-AllowedPaths
    }
    Log-Trace "END - Register-PoshEnv"
}

function Unregister-PoshEnv {
    [CmdletBinding()]
    Param (
        [Alias("p")]
        $Path=$pwd
    )
    Log-Trace "BEGIN - Unregister-PoshEnv"
    $files = (List-Files $Path)
    if ($($files.Count) -gt 1) {
        Deny-File (Get-FileInfo $files[$(Select-File $files "Wnich file to deny?")])
    } else {
        Deny-File (Get-FileInfo $files)
    }
    Save-AllowedPaths
    Log-Trace "END - Unregister-PoshEnv"
}

### Private Functions ######################################################################
function Initialize-AllowedPaths {
    $FilePath = Join-Path $(Get-PoshEnvConfig "dir") $(Get-PoshEnvConfig "allowed_path_file")
    if (-not (Test-Path $FilePath)) {
        New-Item -ItemType "file" -Path $FilePath
    }
    Load-AllowedPaths
}

function Load-AllowedPaths {
    Log-Trace "BEGIN - Load-AllowedPaths"
    $script:AllowedPaths = $(Get-Content -Raw -Path (Join-Path $(Get-PoshEnvConfig "dir") $(Get-PoshEnvConfig "allowed_path_file")) | ConvertFrom-Json -AsHashtable)
    if (-not $script:AllowedPaths) {
        $script:AllowedPaths = @{}
    }
    Log-Trace "END - Load-AllowedPaths"
}

function Save-AllowedPaths {
    Log-Trace "BEGIN - Save-AllowedPaths"
    $script:AllowedPaths | ConvertTo-Json | Out-File -FilePath (Join-Path $(Get-PoshEnvConfig "dir") $(Get-PoshEnvConfig "allowed_path_file"))
    Log-Trace "END - Save-AllowedPaths"
}

function Allow-File {
    param(
        $FileEntry
    )
    $script:AllowedPaths[$FileEntry.FullName] = $FileEntry.LastWriteTime
    Log-Info "Allowing file $($FileEntry.FullName | Resolve-Path -Relative)."
    Force-PoshEnvReload
}

function Deny-File {
    param(
        $FileEntry
    )
    $script:AllowedPaths.Remove($($FileEntry.FullName | Resolve-Path -Relative))
    Force-PoshEnvReload
}

function Check-File {
    [CmdletBinding()]
    Param (
        [Alias("f")]
        $File
    )
    $FileInfo = Get-ChildItem -Path $File | Select Name,FullName,LastWriteTime
    Log-Trace "BEGIN - Check-File($File)"
    if ($script:AllowedPaths.Keys -contains $File) {
        Log-Debug "$($File | Resolve-Path -Relative) contained in AllowedPaths"
        if ($script:AllowedPaths[$File] -eq $($FileInfo.LastWriteTime)) {
            Log-Debug "File '$($File| Resolve-Path -Relative)' has valid timestamp."
            return $True
        } else {
            Log-Warn "File '$($File | Resolve-Path -Relative)' has changed. Run 'poshenv allow' again for security reasons."
        }
    }
    return $False
}

function Get-AllowedFiles {
    $files = List-Files
    $allowedFiles = New-Object System.Collections.ArrayList
    List-Files | % {
        if (Check-File $_) {
            $allowedFiles.Add($_)
        }
    }
    return $allowedFiles
}

function List-Files {
    [CmdletBinding()]
    Param (
        [Alias("d")]
        $Dir=$pwd
    )
    Log-Trace "BEGIN - List-Files($Dir)"
    switch(Get-PoshEnvConfig "search_mode") {
        "current_folder" {
            $EnvFiles = search_current_folder $Dir
            break
        }
        "search_recursive" {
            $EnvFiles = search_recursive $Dir
            break
        }
        "merge_recursive" {
            $EnvFiles = merge_recursive $Dir
            break
        }
        default {
            Log-Warn "Search Mode not recognized! Falling back to search mode 'merge_recursive'."
            $EnvFiles = merge_recursive $Dir
            break
        }
    }
    $EnvFiles = $($EnvFiles | Sort-Object)
    Log-Debug "Found following Files: $($EnvFiles)"
    return $($EnvFiles)
}

function Get-FileInfo {
    [CmdletBinding()]
    param(
        $path
    )
    return get-childitem -Path $path | select Name,Fullname,LastWriteTime

}

function Select-File {
    [CmdletBinding()]
    param(
        $options,
        [string]$Message,
        [string]$Caption="",
        [int]$DefaultChoice=0
    )
    Log-Trace "BEGIN - Select-File"
    $choices = @()
    for ($i = 0; $i -lt $options.Length; $i++) {
        $choices += New-Object System.Management.Automation.Host.ChoiceDescription("&$i - $($options[$i] | Resolve-Path -Relative)")
    }
    return $host.ui.PromptForChoice($Message, $Caption, $choices, $DefaultChoice)
}

function search_current_folder() {
    [CmdletBinding()]
    param(
        $Dir
    )
    Log-Trace "BEGIN - search_current_folder($Dir)"
    $EnvFiles = @()
    $(Get-PoshEnvConfig "posh_env_files") | % {
        try {
            if (Test-Path (Join-Path $Dir $_)) {
                $EnvFiles += (Join-Path $Dir $_)
            }
        } catch {
            Log-Debug "File '$_' not found. Continuing."
        }
    }
    Log-Trace "END - search_current_folder"
    return $EnvFiles
}

function search_recursive() {
    [CmdletBinding()]
    param(
        $Dir
    )
    Log-Trace "BEGIN - search_recursive($Dir)"
    $EnvFiles = @()
    $Path = $Dir
    while (($EnvFiles.Length -lt 1) -and ( $Path -ne "")) {
        Log-Trace "search_recursive>> Path: $Path, EnvFiles: $EnvFiles"
        $EnvFiles += search_current_folder $Path
        $Path = $Path | Split-Path -parent
    }
    Log-Trace "END - search_recursive"
    return $EnvFiles
}

function merge_recursive() {
    [CmdletBinding()]
    param(
        $Dir
    )
    Log-Trace "BEGIN - merge_recursive($Dir)"
    $EnvFiles = @()
    $Path = $Dir
    while ($Path -ne "") {
        Log-Trace "search_recursive>> Path: $Path, EnvFiles: $EnvFiles"
        $EnvFiles += search_current_folder $Path
        $Path = $Path | Split-Path -parent
    }
    Log-Trace "END - search_recursive"
    return $EnvFiles
}
