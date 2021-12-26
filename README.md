# PoshEnv - A Powershell Native Direnv Implementation

PoshEnv is a PowerShell native implementation inspired by [direnv][direnv].

## Installation

For the time being, just clone the repository and import the module in your Powershell profile.
Because it expands your standard powershell prompt, be sure to make it the last line!

```powershell
...
<your profile content>
...
Import-Module -Name "C:\Path\To\poshenv"
```

## Argument Completion

PoshEnv comes with custom argument completion. To activate it, just register the ArgumentCompleter after importing the module.

```powershell
Import-Module -Name "C:\Path\To\poshenv"
Register-PoshEnvCompletion
```

## Usage

Use it just like you would use direnv in your common linux environment.

### Demo

```powershell
# Create a new folder for demo purposes.
$ mkdir ~/my-project
$ cd ~/my-project

# Show that the FOO environment variable is not loaded.
$ Write-Host "FOO: $env:FOO"
FOO:

# Create a new .envrc. This file is bash code that is going to be loaded by
# direnv.
$ Write-Output "`$env:FOO=`"foo`"" > .envrc
INFO: Found envfile '.envrc' that is not allowed. Run "poshenv allow" to allow file.

# The security mechanism didn't allow to load the .envrc. Since we trust it,
# let's allow its execution.
$ poshenv allow
INFO: Allowing file .envrc.
INFO: Loading .envrc.

# Show that the FOO environment variable is loaded.
$ Write-Host "FOO: $env:FOO"
FOO: foo

# Exit the project
$ cd ..
INFO: Unloading

# And now FOO is unset again
$ Write-Host "FOO: $env:FOO"
FOO:
```

### PoshEnv File Content

Unlike [direnv][direnv], PoshEnv files can contain complete PowerShell scripts.
However, PoshEnv can only restore changes to the environment automatically.

### Convenience Methods
PoshEnv also comes with handy convenience methods to change your Path:

Method | Example | Description
------ | ------- | -----------
`PATH_ADD` | `PATH_ADD "C:\myPath\myTool.exe"` | Will add the given path to the end of $env:PATH variable.
`PATH_APPEND` | `PATH_APPEND "C:\myPath\myTool.exe"` | Will add the given path to the end of $env:PATH variable.
`PATH_PREPEND` | `PATH_PREPEND "C:\myPath\myTool.exe"` | Will add the given path as first entry in $env:PATH variable.

## Configuration

PoshEnv can be configured via cli commands or by editing the config file.
To view the current configuration just run `poshenv config list`.

### Options

Option | Default Value | Description
------ | ------------- | -----------
posh_env_files | `[".envrc", ".env"]` | Defines which files will be considered for automatic environment configuration.
show_candidates | `true` | Prints information, if current folder contains candidates for automatic environment configuration.
log_level | `"error"` | The log level for internal PoshEnv logging detail.
allowed_path_file | `"allowed_paths.json"` | Defines the file in which all currently allowed files will be saved.


[direnv]: https://github.com/direnv/direnv
