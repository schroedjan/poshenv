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
    if ($($files.Count) -gt 1) {
        Allow-File (Get-FileInfo $files[$(Select-File $files "Wnich file to allow?")])
    } else {
        Allow-File (Get-FileInfo $files)
    }
    Save-AllowedPaths
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
    Force-PoshEnvReload
}

function Deny-File {
    param(
        $FileEntry
    )
    $script:AllowedPaths.Remove($FileEntry.FullName)
}

function Check-File {
    [CmdletBinding()]
    Param (
        [Alias("f")]
        $File
    )
    $FileInfo = Get-ChildItem -Path $File | Select FullName,LastWriteTime
    Log-Trace "BEGIN - Check-File"
    if ($script:AllowedPaths.Keys -contains $File) {
        Log-Debug "$(Split-Path -Path $File -Leaf) contained in AllowedPaths"
        if ($script:AllowedPaths[$File] -eq $($FileInfo.LastWriteTime)) {
            Log-Debug "File '$(Split-Path -Path $File -Leaf)' has valid timestamp."
            return $True
        } else {
            Log-Warn "File '$(Split-Path -Path $File -Leaf)' has changed. Run 'poshenv allow' again for security reasons."
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
    Log-Trace "BEGIN - List-Files"
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
    Log-Debug "Found following Files: $EnvFiles" 
    return $EnvFiles
}

function Get-FileInfo {
    [CmdletBinding()]
    param(
        $path
    )
    return get-childitem -Path $path | select Fullname,LastWriteTime

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
        $choices += New-Object System.Management.Automation.Host.ChoiceDescription("&$i - $(Split-Path -Path $options[$i] -Leaf)")
    }
    return $host.ui.PromptForChoice($Message, $Caption, $choices, $DefaultChoice)
}