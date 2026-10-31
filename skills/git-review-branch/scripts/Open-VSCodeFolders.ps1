<#
.SYNOPSIS
  Opens each folder in its own VS Code window, unless a window is already open on it.

.DESCRIPTION
  Used by the git-review-branch skill. For each folder:
    - "already open"  -> nothing is done (no focus change, no new window).
    - "not open"      -> `code --new-window <folder>`.
  A folder counts as open when VS Code's own state file (storage.json) lists it among the open
  windows AND a VS Code process with a window exists. The state file is written by VS Code when
  windows open or close, so it can lag by a few seconds: a just-closed window may still look open.
  If the state file cannot be read, a window title that contains the folder name is used instead
  (weaker: two repos with the same name, e.g. in two worktrees, cannot be told apart) and reported as such.
  Nothing is modified except opening windows. Only stable VS Code is handled (by design; Insiders / VSCodium are not).

.PARAMETER Path
  One or more folders to open (absolute paths).

.PARAMETER DryRun
  Only report what would be done.

.EXAMPLE
  .\Open-VSCodeFolders.ps1 -Path C:\Dev\projects\sample-app\.worktree\fix-empty-notes -DryRun
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string[]]$Path,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function ConvertTo-NormalizedPath([string]$p) {
  # file:///c%3A/Dev/x  or  C:\Dev\x  ->  c:/dev/x
  if ($p -match '^file:///') {
    $p = [uri]::UnescapeDataString(($p -replace '^file:///', ''))
  }
  return ($p -replace '\\', '/').TrimEnd('/').ToLowerInvariant()
}

# 1. Is VS Code running with a window?
$codeProcs = @(Get-Process -Name 'Code' -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })

# 2. Folders VS Code reports as open.
$openFolders = $null
$storage = Join-Path $env:APPDATA 'Code\User\globalStorage\storage.json'
if (Test-Path -LiteralPath $storage) {
  try {
    $state = Get-Content -LiteralPath $storage -Raw | ConvertFrom-Json
    $uris = @()
    $ws = $state.windowsState
    if ($ws) {
      if ($ws.lastActiveWindow.folder) { $uris += $ws.lastActiveWindow.folder }
      foreach ($w in @($ws.openedWindows)) { if ($w.folder) { $uris += $w.folder } }
    }
    $openFolders = @($uris | ForEach-Object { ConvertTo-NormalizedPath $_ })
  } catch {
    Write-Warning "Could not read VS Code state ($storage): $($_.Exception.Message)"
  }
}

$codeCmd = Get-Command code -ErrorAction SilentlyContinue

foreach ($raw in $Path) {
  if (-not (Test-Path -LiteralPath $raw -PathType Container)) {
    Write-Output "MISSING   $raw"
    continue
  }
  $folder = (Resolve-Path -LiteralPath $raw).ProviderPath
  $norm = ConvertTo-NormalizedPath $folder

  $isOpen = $false
  $how = ''
  if ($codeProcs.Count -gt 0) {
    if ($null -ne $openFolders) {
      $isOpen = $openFolders -contains $norm
      $how = 'state file'
    } else {
      $leaf = Split-Path -Leaf $folder
      $isOpen = [bool]($codeProcs | Where-Object { $_.MainWindowTitle -like "*$leaf*" })
      $how = 'window title (weak match)'
    }
  }

  if ($isOpen) {
    Write-Output "OPEN      $folder  (already open, $how; nothing done)"
    continue
  }
  if ($DryRun) {
    Write-Output "WOULD-OPEN $folder"
    continue
  }
  if (-not $codeCmd) {
    Write-Output "NO-CODE-CLI $folder  (the 'code' command is not on PATH; open it manually)"
    continue
  }
  & code --new-window $folder
  Write-Output "OPENED    $folder"
}
