<#
.SYNOPSIS
    Installs assets from the AI resources repository (https://github.com/poziel/ai-resources)
    whose installers are implemented.

.DESCRIPTION
    Currently installs skills using SKILLS_DIR from the environment or .env.

    Agents, instruction assembly, MCP servers, and shared scripts are reserved
    for future installers.

.EXAMPLE
    ./Install.ps1 -DryRun

    Preview installation without changing any files or directories.

.EXAMPLE
    ./Install.ps1

    Install using the destinations configured in .env or the environment.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env'),

    [switch]$DryRun,

    [switch]$BackupExisting
)

$ErrorActionPreference = 'Stop'

# Forward configuration and preview preferences to the individual installers.
# Keep this entry point responsible for orchestration as more installers are added.
$options = @{
    EnvFile        = $EnvFile
    DryRun         = [bool]$DryRun
    BackupExisting = [bool]$BackupExisting
    WhatIf         = [bool]($DryRun -or $WhatIfPreference)
}

if ($PSBoundParameters.ContainsKey('Confirm')) {
    $options.Confirm = $PSBoundParameters['Confirm']
}

# Skills are the first supported asset type.
& (Join-Path $PSScriptRoot 'scripts/Install-Skills.ps1') @options
