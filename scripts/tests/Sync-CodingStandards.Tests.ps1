#Requires -Version 7.0
<#
.SYNOPSIS
    Exercises standards distribution in isolated temporary projects.
.DESCRIPTION
    Requires PowerShell 7 only. No real project or installed asset is changed.
    Tests the copied bytes, selective profiles, preflight, and update behavior.
#>
$ErrorActionPreference = 'Stop'
$script = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Sync-CodingStandards.ps1'))
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('ai-resources-standards-' + [guid]::NewGuid().ToString('N'))
$checks = 0

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAILED: $Message" }
    $script:checks++
}

function Assert-Fails([scriptblock]$Action, [string]$Pattern) {
    $caught = $false
    try { & $Action | Out-Null }
    catch {
        $caught = $true
        Assert ($_.Exception.Message -like $Pattern) "Expected '$Pattern', got '$($_.Exception.Message)'"
    }
    Assert $caught "Expected failure matching $Pattern"
}

function Write-Config($Projects) {
    @{ version = 1; projects = @($Projects) } | ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $config -Encoding utf8
}

try {
    $fixture = Join-Path $scratch 'ai-resources'
    $source = Join-Path $fixture 'instructions/coding-standards'
    $scripts = Join-Path $fixture 'scripts'
    New-Item -ItemType Directory -Path $source, $scripts | Out-Null
    Copy-Item -LiteralPath $script -Destination (Join-Path $scripts 'Sync-CodingStandards.ps1')
    $runner = Join-Path $scripts 'Sync-CodingStandards.ps1'
    $config = Join-Path $fixture 'coding-standards.projects.json'
    $projectA = Join-Path $scratch 'project a'
    $projectB = Join-Path $scratch 'project b'
    New-Item -ItemType Directory -Path $projectA, $projectB | Out-Null
    @{
        version = 1
        always = @('.gitattributes', 'README.md', 'markdown.md')
        languages = @{
            typescript = @('typescript.md')
            javascript = @('typescript.md')
            css = @('css.md')
            html = @('html.md')
            vue = @('vue.md', 'typescript.md', 'html.md', 'css.md')
        }
    } | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $source 'catalog.json')
    foreach ($file in 'README.md', 'markdown.md', 'typescript.md', 'css.md', 'html.md', 'vue.md') {
        [IO.File]::WriteAllText((Join-Path $source $file), "# $file`n`nFixture standard.`n")
    }
    [IO.File]::WriteAllText((Join-Path $source '.gitattributes'), "*.md text eol=lf`n")
    $a = @{ name = 'a'; path = '../project a'; destination = 'docs/standards'; languages = @('javascript') }
    $b = @{ name = 'b'; path = '../project b'; destination = 'docs/standards'; languages = @('css') }
    Write-Config @($a, $b)

    # Preview and WhatIf must not create directories, even when Apply is passed.
    & $runner -Config $config | Out-Null
    Assert (-not (Test-Path (Join-Path $projectA 'docs'))) 'Default preview must not write'
    & $runner -Config $config -Apply -WhatIf | Out-Null
    Assert (-not (Test-Path (Join-Path $projectA 'docs'))) 'WhatIf must not write'
    Assert-Fails { & $runner -Config $config -Check } '*out of date*'

    # Copies must be regular files and identical to source; CSS cannot load TS.
    & $runner -Config $config -Apply | Out-Null
    $targetA = Join-Path $projectA 'docs/standards/typescript.md'
    $targetB = Join-Path $projectB 'docs/standards/css.md'
    Assert ((Get-Content $targetA -Raw) -ceq "# typescript.md`n`nFixture standard.`n") 'Copy must preserve exact text'
    Assert ((Get-FileHash $targetA).Hash -eq (Get-FileHash (Join-Path $source 'typescript.md')).Hash) 'Copy must preserve bytes'
    Assert (-not ((Get-Item $targetA).Attributes -band [IO.FileAttributes]::ReparsePoint)) 'Copy must not be a link'
    Assert (-not (Test-Path (Join-Path $projectB 'docs/standards/typescript.md'))) 'CSS profile must not copy TS'
    Assert ((Get-ChildItem (Join-Path $projectA 'docs/standards') -File -Force).Count -eq 4) 'JS must select shared TS guide and common files only'
    Assert ((Get-Content (Join-Path $projectA 'docs/standards/.gitattributes') -Raw) -ceq "*.md text eol=lf`n") 'Common Git attributes must keep Markdown LF on checkout'
    & $runner -Config $config -Check | Out-Null

    # Rerunning must not rewrite matching files.
    $timestamp = (Get-Item $targetA).LastWriteTimeUtc
    & $runner -Config $config -Apply | Out-Null
    Assert ((Get-Item $targetA).LastWriteTimeUtc -eq $timestamp) 'Idempotent update must preserve mtime'

    # Updating one source must reach every selected project without touching extras.
    $b.languages = @('typescript', 'css')
    Write-Config @($a, $b)
    [IO.File]::WriteAllText((Join-Path $source 'typescript.md'), "# Updated`n")
    [IO.File]::WriteAllText((Join-Path $projectA 'docs/standards/manual.md'), 'keep me')
    Assert-Fails { & $runner -Config $config -Check } '*out of date*'
    & $runner -Config $config -Apply | Out-Null
    Assert ((Get-Content $targetA -Raw) -ceq "# Updated`n") 'First project must update'
    Assert ((Get-Content (Join-Path $projectB 'docs/standards/typescript.md') -Raw) -ceq "# Updated`n") 'Second project must update'
    Assert ((Get-Content (Join-Path $projectA 'docs/standards/manual.md') -Raw) -eq 'keep me') 'Unmanaged files must survive'

    # Project selection must not silently update every configured project.
    [IO.File]::WriteAllText((Join-Path $source 'typescript.md'), "# Selected`n")
    & $runner -Config $config -Apply -Project a | Out-Null
    Assert ((Get-Content (Join-Path $projectB 'docs/standards/typescript.md') -Raw) -ceq "# Updated`n") 'Project filter must preserve unselected project'
    Assert-Fails { & $runner -Config $config -Project missing } '*Unknown project*'

    # Vue must include the guides it references, without manual dependency setup.
    $b.languages = @('vue')
    Write-Config @($a, $b)
    & $runner -Config $config -Apply | Out-Null
    Assert ((Get-ChildItem (Join-Path $projectB 'docs/standards') -File -Force).Count -eq 7) 'Vue must copy all dependencies'

    # A later invalid destination must prevent earlier writes.
    [IO.File]::WriteAllText((Join-Path $source 'typescript.md'), "# Do not apply`n")
    $b.destination = '../escape'
    Write-Config @($a, $b)
    Assert-Fails { & $runner -Config $config -Apply } '*destination*'
    Assert ((Get-Content $targetA -Raw) -ceq "# Selected`n") 'Preflight failure must prevent all writes'
    $b.destination = 'docs/standards'
    $b.languages = @('rust')
    Write-Config @($a, $b)
    Assert-Fails { & $runner -Config $config -Apply } '*Unknown language*'
    $b.languages = @('css')
    $b.path = '../does-not-exist'
    Write-Config @($a, $b)
    Assert-Fails { & $runner -Config $config -Apply } '*Project directory*'
    $b.path = $a.path
    Write-Config @($a, $b)
    Assert-Fails { & $runner -Config $config -Apply } '*overlap*'
    $b.path = '../project b'

    # An existing destination link must not redirect writes outside the project.
    $outside = Join-Path $scratch 'outside'
    New-Item -ItemType Directory -Path $outside | Out-Null
    $link = Join-Path $projectB 'linked'
    $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkType -Path $link -Target $outside | Out-Null
    try {
        $b.destination = 'linked/standards'
        Write-Config @($a, $b)
        Assert-Fails { & $runner -Config $config -Apply } '*link*'
        Assert (-not (Test-Path (Join-Path $outside 'standards'))) 'Link rejection must preserve outside directory'
    }
    finally { [IO.Directory]::Delete($link) }
    $b.destination = 'docs/standards'

    # Missing sources must fail preflight rather than partially updating a project.
    Write-Config @($a, $b)
    $cssSource = Join-Path $source 'css.md'
    $cssBytes = [IO.File]::ReadAllBytes($cssSource)
    [IO.File]::Delete($cssSource)
    try {
        Assert-Fails { & $runner -Config $config -Apply } '*Missing source standard*'
        Assert ((Get-Content $targetA -Raw) -ceq "# Selected`n") 'Missing source must prevent all writes'
    }
    finally { [IO.File]::WriteAllBytes($cssSource, $cssBytes) }

    # Catalogs must not turn a configured language into arbitrary file copying.
    $catalogFile = Join-Path $source 'catalog.json'
    $catalogText = [IO.File]::ReadAllText($catalogFile)
    $invalidCatalog = $catalogText | ConvertFrom-Json -AsHashtable
    $invalidCatalog.languages.css = @('../outside.md')
    $invalidCatalog | ConvertTo-Json -Depth 10 | Set-Content $catalogFile
    try {
        Assert-Fails { & $runner -Config $config -Apply } '*Invalid catalog filename*'
        Assert ((Get-Content $targetA -Raw) -ceq "# Selected`n") 'Bad catalog must prevent all writes'
    }
    finally { [IO.File]::WriteAllText($catalogFile, $catalogText) }

    # A linked file is also refused, even if its contents already match.
    $fileLink = Join-Path $projectB 'docs/standards/css.md'
    $originalBytes = [IO.File]::ReadAllBytes($fileLink)
    [IO.File]::Delete($fileLink)
    # Hard links are not used: only symbolic links have redirection semantics here.
    if (-not $IsWindows) {
        New-Item -ItemType SymbolicLink -Path $fileLink -Target (Join-Path $source 'css.md') | Out-Null
        try {
            Write-Config @($a, $b)
            Assert-Fails { & $runner -Config $config -Apply } '*link*'
        }
        finally { [IO.File]::Delete($fileLink) }
    }
    [IO.File]::WriteAllBytes($fileLink, $originalBytes)

    Write-Config @($a, $b)
    & $runner -Config $config -Apply | Out-Null
    & $runner -Config $config -Check | Out-Null
    Write-Output "PASS: $checks standards distribution assertions"
}
finally {
    if (Test-Path -LiteralPath $scratch) {
        $resolved = [IO.Path]::GetFullPath($scratch)
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Refusing cleanup outside the temporary workspace.'
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
