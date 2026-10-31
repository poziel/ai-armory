<#
.SYNOPSIS
    Links skills from the AI resources repository into a configured directory without copying them.

.DESCRIPTION
    Requires PowerShell 7. Uses directory junctions on Windows and symbolic
    links elsewhere. The AI resources repository remains the source of the installed files:
    https://github.com/poziel/ai-resources

    Destination precedence: -SkillsPath, process SKILLS_DIR, .env SKILLS_DIR.

    Existing matching links are left alone. Conflicts stop installation before
    changes. Other links are never replaced.

.PARAMETER SkillsPath
    Override the skills destination configured in the environment or .env.

.PARAMETER Skill
    Install only the named skills. By default, install all available skills.

.PARAMETER EnvFile
    Read settings from this file. Defaults to the repository's .env.

.PARAMETER BackupExisting
    Move existing ordinary skill directories into a timestamped folder under
    <destination>.ai-resources-backups before linking. Backups sit beside the
    destination directory, outside skills discovery.

.PARAMETER DryRun
    Show planned links and backups without changing files or directories.

.EXAMPLE
    ./scripts/Install-Skills.ps1 -DryRun

    Preview installation using the configured destination.

.EXAMPLE
    ./scripts/Install-Skills.ps1 -Skill git-commit

    Install only the git-commit skill.

.EXAMPLE
    ./scripts/Install-Skills.ps1 -SkillsPath D:/AI/2-skills -BackupExisting -DryRun

    Preview migration of existing directories into backups and linked skills.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SkillsPath,

    [string[]]$Skill,

    [string]$EnvFile = (Join-Path $PSScriptRoot '../.env'),

    [switch]$BackupExisting,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Locate the source checkout independently of the caller's working directory.
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourceRoot = Join-Path $repository 'skills'

# Read settings as plain data. Blank lines and full-line comments are ignored.
$settings = @{}
if (Test-Path -LiteralPath $EnvFile) {
    foreach ($line in Get-Content -LiteralPath $EnvFile) {
        if ($line -match '^\s*(#.*)?$') {
            continue
        }
        if ($line -notmatch '^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$') {
            throw "Invalid .env entry: expected NAME=value or a full-line comment."
        }
        $key = $Matches[1]
        $value = $Matches[2]
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $settings[$key] = $value
    }
}

# Resolve the destination: explicit argument, process environment, then .env.
if (-not $SkillsPath) {
    if ($env:SKILLS_DIR) {
        $SkillsPath = $env:SKILLS_DIR
    }
    elseif ($settings['SKILLS_DIR']) {
        $SkillsPath = $settings['SKILLS_DIR']
    }
    else {
        throw 'No skills destination configured. Set SKILLS_DIR in .env or the environment, or pass -SkillsPath.'
    }
}

# Expand placeholders as data; never execute .env content or change process variables.
for ($pass = 0; $SkillsPath -match '%([^%]+)%'; $pass++) {
    if ($pass -ge 10) {
        throw 'Circular or excessively nested path placeholders.'
    }
    $SkillsPath = [regex]::Replace($SkillsPath, '%([^%]+)%', {
        param($match)
        $name = $match.Groups[1].Value
        $replacement = [Environment]::GetEnvironmentVariable($name)
        if (-not $replacement) {
            $replacement = $settings[$name]
        }
        if (-not $replacement) {
            throw "Undefined path placeholder: %$name%. Set it or use an absolute path."
        }
        return $replacement
    })
}

# Reject relative destinations and paths that overlap the repository's skills.
if (-not [IO.Path]::IsPathFullyQualified($SkillsPath)) {
    throw 'The skills destination must be an absolute path.'
}
$destinationRoot = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($SkillsPath))
$comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$separator = [IO.Path]::DirectorySeparatorChar
if ($destinationRoot.Equals($sourceRoot, $comparison) -or
    $destinationRoot.StartsWith("$sourceRoot$separator", $comparison) -or
    $sourceRoot.StartsWith("$destinationRoot$separator", $comparison)) {
    throw 'The destination must be separate from the repository skills directory.'
}

# Discover installable skills, then apply the optional name selection.
$available = @(Get-ChildItem -LiteralPath $sourceRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
} | Sort-Object Name)
if (-not $Skill) {
    $Skill = @($available.Name)
}
if (-not $Skill.Count) {
    throw 'No skills found.'
}

# Preflight every selected skill before changing the destination.
$plan = foreach ($name in ($Skill | Select-Object -Unique)) {
    if ($name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $name -notin $available.Name) {
        throw "Unknown skill: $name"
    }
    $source = Join-Path $sourceRoot $name
    $destination = Join-Path $destinationRoot $name
    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    $action = 'Link'
    if ($existing) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $target = $existing.ResolveLinkTarget($true)
            # Source skills may themselves be junctions or symbolic links.
            # Compare final targets on both sides while keeping new links pointed
            # at the AI resources checkout so its source references remain authoritative.
            $sourceItem = Get-Item -LiteralPath $source -Force
            $sourceTarget = if ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $sourceItem.ResolveLinkTarget($true)
            }
            else {
                $sourceItem
            }
            if ($target -and $sourceTarget -and $target.FullName.Equals($sourceTarget.FullName, $comparison)) {
                $action = 'Unchanged'
            }
            else {
                throw "Conflicting link: $destination. Resolve it manually; no links were changed."
            }
        }
        elseif ($existing.PSIsContainer -and $BackupExisting) {
            $action = 'Backup and link'
        }
        else {
            throw "Destination exists: $destination. Use -BackupExisting for ordinary directories; no links were changed."
        }
    }
    [pscustomobject]@{ Name = $name; Source = $source; Destination = $destination; Action = $action }
}

# Keep recovery snapshots outside the directory scanned for installed skills.
$backupRoot = Join-Path "$destinationRoot.ai-resources-backups" ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))

# Apply the validated plan. Preview paths return before any filesystem changes.
foreach ($item in $plan) {
    if ($item.Action -eq 'Unchanged') {
        Write-Output "UNCHANGED $($item.Destination) -> $($item.Source)"
        continue
    }

    if ($DryRun) {
        Write-Output "WOULD $($item.Action.ToUpperInvariant()) $($item.Destination) -> $($item.Source)"
        continue
    }

    # ShouldProcess also supports PowerShell's native -WhatIf and -Confirm.
    if ($PSCmdlet.ShouldProcess($item.Destination, "$($item.Action) -> $($item.Source)")) {
        if (-not (Test-Path -LiteralPath $destinationRoot)) {
            New-Item -ItemType Directory -Path $destinationRoot | Out-Null
        }

        # Preserve an existing ordinary directory only when explicitly requested.
        $backup = $null
        if ($item.Action -eq 'Backup and link') {
            # Verify the resolved move source remains the selected direct child.
            $resolved = (Get-Item -LiteralPath $item.Destination -Force).FullName
            if (-not $resolved.Equals((Join-Path $destinationRoot $item.Name), $comparison)) {
                throw "Unexpected backup source: $resolved"
            }
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
            $backup = Join-Path $backupRoot $item.Name
            Move-Item -LiteralPath $resolved -Destination $backup
            Write-Output "BACKUP $backup"
        }

        # Create the reference, restoring the backup if link creation fails.
        try {
            $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
            New-Item -ItemType $linkType -Path $item.Destination -Target $item.Source | Out-Null
        }
        catch {
            if ($backup -and -not (Get-Item -LiteralPath $item.Destination -Force -ErrorAction SilentlyContinue)) {
                Move-Item -LiteralPath $backup -Destination $item.Destination
            }
            throw
        }

        Write-Output "LINKED $($item.Destination) -> $($item.Source)"
    }
}
