<#
.SYNOPSIS
    Runs isolated integration checks for the installers in the AI resources.

.DESCRIPTION
    Verifies previews, links, reruns, backups, configuration, and root delegation.
    No Pester dependency is required, and global installations are left alone.

    Each run uses a temporary directory and restores changed process variables.
    Cleanup removes test links before deleting the temporary files, so it cannot
    recurse through a link into the source checkout.

.EXAMPLE
    ./scripts/tests/Install-Skills.Tests.ps1
#>

#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

# Locate both entry points and reserve an isolated filesystem workspace.
$installer = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Install-Skills.ps1'))
$rootInstaller = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Install.ps1'))
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('ai-resources-test-' + [guid]::NewGuid().ToString('N'))

# Save the caller's environment and track links that need separate cleanup.
$savedHome = $env:AI_RESOURCES_TEST_ROOT
$savedSkills = $env:SKILLS_DIR
$createdLinks = [Collections.Generic.List[string]]::new()
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../skills'))
$skillNames = @(Get-ChildItem -LiteralPath $sourceRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
} | Select-Object -ExpandProperty Name)

# Assertion helpers keep each scenario focused on observable behavior.
function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "FAILED: $Message"
    }
}

function Assert-Fails([scriptblock]$Action, [string]$Pattern) {
    $caught = $false
    try { & $Action | Out-Null }
    catch {
        $caught = $true
        Assert ($_.Exception.Message -like $Pattern) "Expected '$Pattern', got '$($_.Exception.Message)'"
    }
    Assert $caught "Expected failure: $Pattern"
}

try {
    # Configuration fixture: one active destination and blank reserved settings.
    New-Item -ItemType Directory -Path $scratch | Out-Null
    $env:AI_RESOURCES_TEST_ROOT = Join-Path $scratch 'asset root'
    $env:SKILLS_DIR = $null
    $blankEnv = Join-Path $scratch 'empty.env'
    Set-Content -LiteralPath $blankEnv -Value @('SKILLS_DIR=%AI_RESOURCES_TEST_ROOT%/skills', 'AGENTS_DIR=', 'INSTRUCTIONS_DIR=', 'MCP_SERVERS_DIR=', 'SCRIPTS_DIR=')
    $defaultRoot = Join-Path $env:AI_RESOURCES_TEST_ROOT 'skills'

    # Preview must not create the destination directory.
    & $installer -EnvFile $blankEnv -DryRun
    Assert (-not (Test-Path -LiteralPath $defaultRoot)) 'DryRun must not create the destination'

    # Install all skills and verify that every link resolves into this checkout.
    foreach ($name in $skillNames) {
        $createdLinks.Add((Join-Path $defaultRoot $name))
    }

    # Installing again must leave existing matching links alone.
    & $installer -EnvFile $blankEnv | Out-Null
    foreach ($path in $createdLinks) {
        $link = Get-Item -LiteralPath $path -Force
        Assert ([bool]($link.Attributes -band [IO.FileAttributes]::ReparsePoint)) 'Installation must create links'
        $expected = Join-Path ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../skills'))) $link.Name
        $sourceItem = Get-Item -LiteralPath $expected
        if ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $expected = $sourceItem.ResolveLinkTarget($true).FullName
        }
        Assert ($link.ResolveLinkTarget($true).FullName -eq $expected) 'Link must resolve into this checkout'
        Assert (Test-Path -LiteralPath (Join-Path $path 'SKILL.md')) 'Skill must be readable through link'
    }
    $rerun = @(& $installer -EnvFile $blankEnv)
    Assert (@($rerun | Where-Object { $_ -like 'UNCHANGED *' }).Count -eq $skillNames.Count) 'Rerun must leave all links unchanged'

    # A conflict must abort the entire plan before any earlier skill is installed.
    $conflictRoot = Join-Path $scratch 'conflict'
    New-Item -ItemType Directory -Path (Join-Path $conflictRoot 'git-commit') | Out-Null
    $marker = Join-Path $conflictRoot 'git-commit/manual.txt'
    Set-Content -LiteralPath $marker -Value 'preserve me'
    Assert-Fails { & $installer -SkillsPath $conflictRoot -EnvFile $blankEnv } '*Destination exists*'
    Assert (-not (Test-Path -LiteralPath (Join-Path $conflictRoot 'git-branch'))) 'Preflight conflict must prevent earlier links'

    # Preview preserves manual content; real migration retains it in a backup.
    & $installer -SkillsPath $conflictRoot -EnvFile $blankEnv -BackupExisting -DryRun
    Assert (Test-Path -LiteralPath $marker) 'DryRun must not move existing content'
    foreach ($name in $skillNames) {
        $createdLinks.Add((Join-Path $conflictRoot $name))
    }
    & $installer -SkillsPath $conflictRoot -EnvFile $blankEnv -BackupExisting | Out-Null
    $backups = @(Get-ChildItem -LiteralPath "$conflictRoot.ai-resources-backups" -Recurse -Filter manual.txt)
    Assert ($backups.Count -eq 1) 'Migration must preserve the original directory in one backup'
    Assert ((Get-Content -LiteralPath $backups[0].FullName) -eq 'preserve me') 'Backup contents must survive'

    # Process settings override .env; quoted values and placeholders still work.
    $env:SKILLS_DIR = Join-Path $scratch 'environment override'
    $overrideEnv = Join-Path $scratch 'override.env'
    Set-Content -LiteralPath $overrideEnv -Value 'SKILLS_DIR="%AI_RESOURCES_TEST_ROOT%/another path"'
    $createdLinks.Add((Join-Path $env:SKILLS_DIR 'git-commit'))
    & $installer -EnvFile $overrideEnv -Skill git-commit | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $env:SKILLS_DIR 'git-commit/SKILL.md')) 'Process override must win over .env'
    Assert (-not (Test-Path -LiteralPath (Join-Path $env:AI_RESOURCES_TEST_ROOT 'another path'))) '.env must not override process setting'
    $env:SKILLS_DIR = $null
    $expandedRoot = Join-Path $env:AI_RESOURCES_TEST_ROOT 'another path'
    $createdLinks.Add((Join-Path $expandedRoot 'git-commit'))
    & $installer -EnvFile $overrideEnv -Skill git-commit | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $expandedRoot 'git-commit/SKILL.md')) '.env quotes and placeholders must expand'

    # Reject invalid selections, overlapping paths, and unresolved placeholders.
    Assert-Fails { & $installer -SkillsPath $defaultRoot -Skill '../escape' -EnvFile $blankEnv } '*Unknown skill*'
    Assert-Fails { & $installer -SkillsPath (Join-Path $PSScriptRoot '../../skills') -EnvFile $blankEnv } '*separate*'
    Assert-Fails { & $installer -SkillsPath '%AI_RESOURCES_TEST_UNDEFINED%/skills' -EnvFile $blankEnv } '*Undefined path placeholder*'

    # Missing configuration must fail rather than select an AI tool implicitly.
    $missingEnv = Join-Path $scratch 'missing-destination.env'
    Set-Content -LiteralPath $missingEnv -Value 'SKILLS_DIR='
    Assert-Fails { & $installer -EnvFile $missingEnv -DryRun } '*No skills destination configured*'

    # The root entry point forwards configuration and both preview switches.
    $rootDestination = Join-Path $scratch 'root installation'
    $rootEnv = Join-Path $scratch 'root.env'
    Set-Content -LiteralPath $rootEnv -Value @(
        "SKILLS_DIR=$rootDestination"
        "AGENTS_DIR=$scratch/unused-agents"
        'INSTRUCTIONS_DIR=%AI_RESOURCES_TEST_UNDEFINED%/unused'
        "MCP_SERVERS_DIR=$scratch/unused-mcp"
        "SCRIPTS_DIR=$scratch/unused-scripts"
    )
    $preview = @(& $rootInstaller -EnvFile $rootEnv -DryRun)
    Assert (@($preview | Where-Object { $_ -like 'WOULD LINK *' }).Count -eq $skillNames.Count) 'Root preview must describe all planned links'
    Assert (@($preview | Where-Object { $_ -like 'LINKED *' }).Count -eq 0) 'Root preview must never report completed installation'
    Assert (-not (Test-Path -LiteralPath $rootDestination)) 'Root DryRun must not create directories'
    & $rootInstaller -EnvFile $rootEnv -WhatIf
    Assert (-not (Test-Path -LiteralPath $rootDestination)) 'Root WhatIf must not create directories'
    foreach ($name in $skillNames) {
        $createdLinks.Add((Join-Path $rootDestination $name))
    }
    & $rootInstaller -EnvFile $rootEnv | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $rootDestination 'git-commit/SKILL.md')) 'Root must delegate real installation'
    Assert (-not (Test-Path -LiteralPath "$scratch/unused-agents")) 'Reserved agents destination must remain untouched'
    Assert (-not (Test-Path -LiteralPath "$scratch/unused-mcp")) 'Reserved MCP destination must remain untouched'
    Assert (-not (Test-Path -LiteralPath "$scratch/unused-scripts")) 'Reserved scripts destination must remain untouched'

    # A different existing link is refused, even with -BackupExisting.
    $wrongRoot = Join-Path $scratch 'wrong link'
    New-Item -ItemType Directory -Path $wrongRoot | Out-Null
    $wrongLink = Join-Path $wrongRoot 'git-commit'
    $createdLinks.Add($wrongLink)
    $type = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $type -Path $wrongLink -Target $scratch | Out-Null
    Assert-Fails { & $installer -SkillsPath $wrongRoot -EnvFile $blankEnv -BackupExisting } '*Conflicting link*'

    Write-Output 'PASS: dry runs, root delegation, reserved settings, links, reruns, backups, conflicts, path guards, and configuration precedence.'
}
finally {
    # Restore the process environment even when a test fails.
    $env:AI_RESOURCES_TEST_ROOT = $savedHome
    $env:SKILLS_DIR = $savedSkills

    # Remove only the test links first, never recurse through a junction into the repository.
    foreach ($path in $createdLinks) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            [IO.Directory]::Delete($item.FullName)
        }
    }

    # Verify the cleanup path before recursively removing temporary test files.
    $resolvedScratch = [IO.Path]::GetFullPath($scratch)
    $tempRoot = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath([IO.Path]::GetTempPath()))
    if ((Split-Path -Parent $resolvedScratch) -ne $tempRoot -or
        (Split-Path -Leaf $resolvedScratch) -notmatch '^ai-resources-test-[a-f0-9]{32}$') {
        throw "Refusing cleanup of unexpected path: $resolvedScratch"
    }
    if (Test-Path -LiteralPath $resolvedScratch) {
        Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
    }
}
