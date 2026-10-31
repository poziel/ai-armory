<#
.SYNOPSIS
    Copies coding standards from the AI resources into configured projects.
    Source: https://github.com/poziel/ai-resources
.DESCRIPTION
    Requires PowerShell 7. The default is a read-only preview. Use -Apply to
    replace selected standards with exact source bytes, or -Check to fail on
    drift without writing. No files are deleted and AGENTS.md is never changed.
    Project paths are relative to the configuration file; source standards are
    located relative to this script. No network or additional modules are used.
.PARAMETER Config
    JSON project list. Defaults to coding-standards.projects.json in the AI resources checkout.
.PARAMETER Project
    Optional project names to update. Omit to select every configured project.
.PARAMETER Apply
    Create or overwrite the selected files. The AI resources are authoritative, so local
    edits to these files are replaced. Review the default preview first.
.PARAMETER Check
    Fail if any selected file is absent or differs from its source in the AI resources.
.PARAMETER DryRun
    Explicit preview. Takes precedence over Apply. WhatIf also prevents writes.
.EXAMPLE
    ./scripts/Sync-CodingStandards.ps1
.EXAMPLE
    ./scripts/Sync-CodingStandards.ps1 -Apply
.EXAMPLE
    ./scripts/Sync-CodingStandards.ps1 -Project pixen -Check
#>
#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Config = (Join-Path $PSScriptRoot '../coding-standards.projects.json'),
    [string[]]$Project,
    [switch]$Apply,
    [switch]$Check,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Reject links at every existing path component, including parent junctions.
function Assert-PlainPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing link or junction: $current"
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

# Use a boundary-aware comparison so sibling names are not mistaken for parents.
function Test-Within([string]$Path, [string]$Root) {
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $prefix = $Root.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    return $Path.Equals($Root, $comparison) -or $Path.StartsWith($prefix, $comparison)
}

# Accept explicit schema fields only, catching typos before changing projects.
function Assert-Fields($Value, [string[]]$Fields, [string]$Context) {
    if ($Value -isnot [Collections.IDictionary]) { throw "Expected object: $Context" }
    foreach ($key in $Value.Keys) {
        if ($key -cnotin $Fields) { throw "Unknown field '$key' in $Context" }
    }
    foreach ($key in $Fields) {
        if (-not $Value.Contains($key)) { throw "Missing field '$key' in $Context" }
    }
}

# Configured paths are data, never evaluated as expressions or environment code.
function Read-Json([string]$Path) {
    Assert-PlainPath $Path
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing JSON file: $Path" }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable -Depth 32
}

function Assert-StringList($Value, [string]$Context) {
    if ($Value -isnot [array] -or $Value.Count -eq 0) { throw "Expected nonempty array: $Context" }
    foreach ($entry in $Value) {
        if ($entry -isnot [string] -or [string]::IsNullOrWhiteSpace($entry)) {
            throw "Expected nonempty strings: $Context"
        }
    }
}

# Hash the captured bytes, which are also used for writing the planned update.
function Get-BytesHash([byte[]]$Bytes) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($algorithm.ComputeHash($Bytes)) }
    finally { $algorithm.Dispose() }
}

if ($Apply -and $Check) { throw 'Use either Apply or Check, not both.' }
if ($DryRun -and $Check) { throw 'Use either DryRun or Check, not both.' }
$configPath = [IO.Path]::GetFullPath($Config)
$configRoot = [IO.Path]::GetDirectoryName($configPath)
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../instructions/coding-standards'))
$settings = Read-Json $configPath
Assert-Fields $settings @('version', 'projects') 'project list'
if ($settings.version -cne 1) { throw 'Unsupported project list version; expected 1.' }
if ($settings.projects -isnot [array] -or $settings.projects.Count -eq 0) {
    throw 'Expected a nonempty projects array.'
}
$catalog = Read-Json (Join-Path $sourceRoot 'catalog.json')
Assert-Fields $catalog @('version', 'always', 'languages') 'catalog'
if ($catalog.version -cne 1) { throw 'Unsupported catalog version; expected 1.' }
Assert-StringList $catalog.always 'catalog always'
if ($catalog.languages -isnot [Collections.IDictionary]) { throw 'Expected languages object in catalog.' }
foreach ($language in $catalog.languages.Keys) {
    if ($language -cnotmatch '^[a-z][a-z0-9-]*$') { throw "Invalid language: $language" }
    Assert-StringList $catalog.languages[$language] "catalog language $language"
}

$projectsByName = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $settings.projects) {
    Assert-Fields $entry @('name', 'path', 'destination', 'languages') 'project'
    if ($entry.name -isnot [string] -or $entry.name -cnotmatch '^[a-z][a-z0-9-]*$') {
        throw 'Project names must be lowercase identifiers.'
    }
    if ($projectsByName.ContainsKey($entry.name)) { throw "Duplicate project: $($entry.name)" }
    Assert-StringList $entry.languages "project $($entry.name) languages"
    foreach ($language in $entry.languages) {
        if (-not $catalog.languages.Contains($language)) { throw "Unknown language '$language' in $($entry.name)" }
    }
    $projectsByName.Add($entry.name, $entry)
}
foreach ($name in $Project) {
    if (-not $projectsByName.ContainsKey($name)) { throw "Unknown project: $name" }
}

$plan = [Collections.Generic.List[object]]::new()
$destinations = [Collections.Generic.List[string]]::new()
foreach ($entry in $settings.projects) {
    if ($Project -and $entry.name -notin $Project) { continue }
    if ($entry.path -isnot [string] -or [string]::IsNullOrWhiteSpace($entry.path)) {
        throw "Project directory is required: $($entry.name)"
    }
    $root = [IO.Path]::GetFullPath($entry.path, $configRoot)
    Assert-PlainPath $root
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Project directory does not exist: $root" }
    if ($entry.destination -isnot [string] -or [string]::IsNullOrWhiteSpace($entry.destination) -or
        [IO.Path]::IsPathRooted($entry.destination) -or $entry.destination -match '[:*?"<>|]' -or
        @($entry.destination -split '[/\\]' | Where-Object { $_ -in @('', '.', '..') }).Count -gt 0) {
        throw "Invalid relative destination in $($entry.name)"
    }
    $targetRoot = [IO.Path]::GetFullPath((Join-Path $root $entry.destination))
    if (-not (Test-Within $targetRoot $root) -or (Test-Within $targetRoot $sourceRoot) -or (Test-Within $sourceRoot $targetRoot)) {
        throw "Invalid destination overlapping source or outside project: $targetRoot"
    }
    Assert-PlainPath $targetRoot
    if ((Test-Path -LiteralPath $targetRoot) -and -not (Test-Path -LiteralPath $targetRoot -PathType Container)) {
        throw "Expected destination directory: $targetRoot"
    }
    foreach ($existing in $destinations) {
        if ((Test-Within $targetRoot $existing) -or (Test-Within $existing $targetRoot)) {
            throw "Project destinations overlap: $existing and $targetRoot"
        }
    }
    $destinations.Add($targetRoot)
    $files = @($catalog.always)
    foreach ($language in $entry.languages) { $files += @($catalog.languages[$language]) }
    foreach ($file in ($files | Sort-Object -Unique)) {
        if ($file -cne '.gitattributes' -and $file -cnotmatch '^[a-zA-Z0-9][a-zA-Z0-9-]*\.md$') {
            throw "Invalid catalog filename: $file"
        }
        $source = Join-Path $sourceRoot $file
        $target = Join-Path $targetRoot $file
        Assert-PlainPath $source
        Assert-PlainPath $target
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing source standard: $source" }
        if ((Test-Path -LiteralPath $target) -and -not (Test-Path -LiteralPath $target -PathType Leaf)) {
            throw "Expected destination file: $target"
        }
        $bytes = [IO.File]::ReadAllBytes($source)
        $exists = [IO.File]::Exists($target)
        $same = $exists -and ((Get-BytesHash $bytes) -eq (Get-BytesHash ([IO.File]::ReadAllBytes($target))))
        $action = if ($same) { 'UNCHANGED' } elseif ($exists) { 'UPDATE' } else { 'COPY' }
        $plan.Add(@{ Project = $entry.name; Target = $target; Bytes = $bytes; Action = $action })
    }
}

# No writes occur until every selected project and source file passes preflight.
$changes = @($plan | Where-Object { $_.Action -ne 'UNCHANGED' })
foreach ($item in $plan) {
    Write-Output "$($item.Action) [$($item.Project)] $($item.Target)"
}
if ($Check) {
    if ($changes.Count -gt 0) { throw "Coding standards out of date: $($changes.Count) file(s). Run with -Apply to update." }
    Write-Output 'All selected coding standards match the AI resources.'
    return
}
if (-not $Apply -or $DryRun) {
    Write-Output "Preview: $($changes.Count) file(s) would change. Use -Apply to copy source files over these destinations."
    return
}
foreach ($item in $changes) {
    if ($PSCmdlet.ShouldProcess($item.Target, 'Copy authoritative standard from the AI resources (overwrite if present)')) {
        Assert-PlainPath $item.Target
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($item.Target)) | Out-Null
        [IO.File]::WriteAllBytes($item.Target, $item.Bytes)
    }
}
