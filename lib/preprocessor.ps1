Import-Module -Name ($PSScriptRoot + "\authorization.ps1")
Import-Module -Name ($PSScriptRoot + "\log.ps1")
Import-Module -Name ($PSScriptRoot + "\config.ps1")

function Apply-File() {
    [CmdletBinding()]
    Param (
        [Alias("f")]
        $File
    )
    Log-Trace "BEGIN - Apply-File"
    # Move Content to temporary file, ensures correct file extension
    $tempfile = Join-Path $([System.IO.Path]::GetTempPath()) "$((Get-FileHash $File).Hash).ps1"
    Log-Trace "Using temporary file: $tempfile"
    PreProcess-File $File $tempfile
    try {
        # Source temporary file
        . $tempfile
    } finally {
        # delete temporary file
        Remove-Item $tempfile
    }
    Log-Trace "END - Apply-File"
}

function PreProcess-File() {
    [CmdletBinding()]
    Param (
        [Alias("f")]
        $File,
        $TempFile
    )
    Log-Trace "BEGIN - PreProcess-File"
    Get-Content $File | ForEach-Object {
        PreProcess-Line $_ | Out-File -FilePath $TempFile -Append
    }
    Log-Trace "END - PreProcess-File"
}

function PreProcess-Line() {
    [CmdletBinding()]
    Param (
        [parameter(Position=0)]
        [string]$Line,
        [parameter(Position=1, ValueFromRemainingArguments=$true)]
        $arguments
    )
    Log-Trace "BEGIN - PreProcess-Line"
    Log-Debug "Working on Line: $Line"
    $command,$arguments = $Line -split ' ',2
    switch ($command) {
        "PATH_ADD" {
            if (Get-PoshEnvConfig "enable_preprocessor") {
                Log-Trace "Found 'PATH_ADD', transforming and adding to PATH"
                $result = "`$env:PATH=`"`$env:PATH;$($arguments.replace('"', ''))`""
            } else {
                $result = $null
            }
            continue
        }
        "PATH_APPEND" {
            if (Get-PoshEnvConfig "enable_preprocessor") {
                Log-Trace "Found 'PATH_APPEND', transforming and adding to PATH"
                $result = "`$env:PATH=`"`$env:PATH;$($arguments.replace('"', ''))`""
            } else {
                $result = $null
            }
            continue
        }
        "PATH_PREPEND" {
            if (Get-PoshEnvConfig "enable_preprocessor") {
                Log-Trace "Found 'PATH_PREPEND', transforming and adding to PATH on first position"
                $result = "`$env:PATH=`"$($arguments.replace('"', ''));`$env:PATH`""
            } else {
                $result = $null
            }
            continue
        }
        "export" {
            if (Get-PoshEnvConfig "enable_preprocessor") {
                Log-Trace "Found 'export', transforming bash style to powershell"
                if ($arguments -match ".+=.+") {
                    Log-Trace "Valid variable declaration, trying to transform"
                    $key,$value = $arguments.replace('"', '') -split '='
                    $result = "`$env:${key}=`"${value}`""
                } else {
                    $result = $null
                }
            } else {
                $result = $null
            }
            continue
        }
        default {
            Log-Trace "Default line, will not transform"
            $result = $Line
        }
    }

    Log-Trace "END - PreProcess-Line"
    return $result
}
