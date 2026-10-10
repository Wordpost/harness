[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$validator = Join-Path $PSScriptRoot 'validate-docs.ps1'
$utf8 = [System.Text.UTF8Encoding]::new($true)
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixtureRoot = Join-Path $tempRoot ('validate-docs-tests-' + [guid]::NewGuid().ToString('N'))
$passed = 0
$failed = 0

function Write-Fixture {
    param([string]$Root, [string]$Path, [AllowEmptyString()][string]$Content)
    $destination = Join-Path $Root $Path
    [void][IO.Directory]::CreateDirectory((Split-Path $destination -Parent))
    [IO.File]::WriteAllText($destination, $Content, $utf8)
}

function Test-Fixture {
    param(
        [string]$Name,
        [hashtable]$Files,
        [int]$Exit = 0,
        [string]$Message = '\[OK\]',
        [string[]]$ExcludePaths = @(),
        [switch]$NonStrict,
        [switch]$InstalledTemplate
    )
    $root = Join-Path $fixtureRoot $Name
    Write-Fixture $root 'AGENTS.md' '# Fixture harness'
    Write-Fixture $root 'docs/architecture/invariants.md' '| INV-TEST-1 | Fixture invariant | manual |'
    [void][IO.Directory]::CreateDirectory((Join-Path $root 'scripts'))
    Copy-Item -LiteralPath $validator -Destination (Join-Path $root 'scripts/validate-docs.ps1')
    if ($ExcludePaths.Count -gt 0) {
        $scriptFile = Join-Path $root 'scripts/validate-docs.ps1'
        $entries = ($ExcludePaths | ForEach-Object { "    '" + $_.Replace("'", "''") + "'" }) -join "`n"
        $content = [IO.File]::ReadAllText($scriptFile).Replace('$excludedPaths = @(', '$excludedPaths = @(' + "`n" + $entries)
        [IO.File]::WriteAllText($scriptFile, $content, $utf8)
    }
    if ($InstalledTemplate) {
        $documents = @(
            Get-Item -LiteralPath (Join-Path $repoRoot 'AGENTS.md')
            Get-ChildItem -LiteralPath (Join-Path $repoRoot 'docs') -Recurse -Filter '*.md' -File
        )
        foreach ($document in $documents) {
            $path = $document.FullName.Substring($repoRoot.Length).TrimStart([char[]]'\/')
            $content = [regex]::Replace([IO.File]::ReadAllText($document.FullName), '\[INSERT_[A-Z0-9_]+\]', 'fixture')
            Write-Fixture $root $path $content
        }
    }
    foreach ($path in $Files.Keys) { Write-Fixture $root $path $Files[$path] }
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $root 'scripts/validate-docs.ps1'))
    if (-not $NonStrict) { $arguments += '-Strict' }
    # Capture unexpected native stderr as a failed scenario, without aborting the suite.
    $ErrorActionPreference = 'Continue'
    $output = (& powershell @arguments 2>&1 | Out-String)
    $actualExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($actualExit -ne $Exit -or $output -notmatch $Message) {
        $script:failed++
        Write-Host "[FAIL] ${Name}: expected exit $Exit / $Message, got exit $actualExit"
        Write-Host $output.Trim()
    } else {
        $script:passed++
    }
}

try {
    Test-Fixture 'installed-template' @{} -InstalledTemplate
    Test-Fixture 'domain-contract' @{
        'docs/architecture/worker.md' = "# Worker`n`n~~~yaml`nstatus: pending`n~~~`n`nПосле закрытия соединения повторная отправка запрещена.`n"
    }
    Test-Fixture 'no-size-policy' @{
        'AGENTS.md' = "# Fixture`n" + ("`n" * 110) + "## Project Adapter`n`n- One: a`n- Two: b`n- Three: c`n- Four: d`n"
        'docs/architecture/large.md' = '# Contract' + "`n`n" + ('contract ' * 2200)
        'docs/phases/PHASE_AUTHORING_GUIDE.md' = '# Правила написания фаз без обязательной формулировки.'
    } -Message '\[OK\].*0 warning'
    Test-Fixture 'empty-markdown' @{'docs/architecture/empty.md' = ''}
    Test-Fixture 'exclude-doc-directory' @{
        'docs/custom/deep/broken.md' = '[INSERT_FIXTURE] [broken](absent.md)'
    } -ExcludePaths 'docs/custom/'
    Test-Fixture 'exclude-directory-boundary' @{
        'docs/custom/deep/broken.md' = '[broken](absent.md)'
        'docs/custom-extra/checked.md' = '[INSERT_FIXTURE]'
    } -ExcludePaths 'docs/custom/' -Exit 1 -Message 'Unresolved placeholders in docs/custom-extra/checked.md'
    Test-Fixture 'exclude-exact-file' @{
        'docs/example.md' = '[INSERT_FIXTURE]'
    } -ExcludePaths 'docs/example.md'
    Test-Fixture 'exclude-file-boundary' @{
        'docs/example.md' = '[INSERT_FIXTURE]'
        'docs/example.md.backup.md' = '[INSERT_FIXTURE]'
    } -ExcludePaths 'docs/example.md' -Exit 1 -Message 'Unresolved placeholders in docs/example.md.backup.md'
    Test-Fixture 'exclude-source-directory' @{
        'src/generated/deep/reader.ts' = 'readFileSync("task.md");'
    } -ExcludePaths 'src/generated/'
    Test-Fixture 'exclude-source-boundary' @{
        'src/generated/reader.ts' = 'readFileSync("task.md");'
        'src/generated-extra/reader.ts' = 'readFileSync("task.md");'
    } -ExcludePaths 'src/generated/' -Exit 1 -Message 'Code/test consumer references temporary documentation: src/generated-extra/reader.ts'
    Test-Fixture 'excluded-target-exists' @{
        'docs/custom/example.md' = '[INSERT_FIXTURE]'
        'docs/link.md' = '[target](custom/example.md#unverified)'
    } -ExcludePaths 'docs/custom/'
    Test-Fixture 'excluded-target-missing' @{
        'docs/link.md' = '[target](custom/missing.md)'
    } -ExcludePaths 'docs/custom/' -Exit 1 -Message 'Broken local link'
    Test-Fixture 'code-examples' @{
        'docs/example.md' = '````markdown
```
[example](missing.md)
```
````

`[inline](also-missing.md)`

~~~markdown
[example][missing]
[missing]: not-a-file.md
~~~'
    }
    Test-Fixture 'parentheses-and-titles' @{
        'docs/api(v2).md' = '# API'
        'docs/space name.md' = '# Spaces'
        'docs/link.md' = '[A](<api(v2).md>) [B](api(v2).md "API") [C](api\(v2\).md) [D](<space name.md> ''Title'')'
    }
    Test-Fixture 'references' @{
        'docs/api.md' = '# API'
        'docs/link.md' = '[full][API ref] [collapsed][] [shortcut]

[api ref]: api.md "API"
[collapsed]: <api.md>
[shortcut]: api.md'
    }
    Test-Fixture 'reference-missing' @{'docs/link.md' = "[API][api]`n`n[api]: missing.md"} -Exit 1 -Message 'Broken local link'
    Test-Fixture 'inline-missing' @{'docs/link.md' = '[missing](missing.md)'} -Exit 1 -Message 'Broken local link'
    Test-Fixture 'anchors' @{
        'docs/api.md' = "# API`n## Раздел API`n## Раздел API`n## Вызов ``run()```n`nSetext`n------`n`n<a id='explicit'></a>"
        'docs/link.md' = '# Links

[A](api.md#раздел-api) [B](api.md#раздел-api-1) [C](api.md#вызов-run) [D](api.md#setext) [E](api.md#explicit) [F](#links) [G](api.md#%D1%80%D0%B0%D0%B7%D0%B4%D0%B5%D0%BB-api)'
    }
    Test-Fixture 'anchor-missing' @{'docs/link.md' = '# Links

[missing](#absent)'} -Exit 1 -Message 'Broken Markdown anchor'
    Test-Fixture 'heading-formatting' @{'docs/link.md' = '# _Contract_ **owner** and `_code_`

[heading](#contract-owner-and-_code_)'}
    Test-Fixture 'external-links' @{'docs/link.md' = '[A](https://example.invalid/x#y) [B](mailto:fixture@example.invalid) [C](//example.invalid/path)'}
    Test-Fixture 'stable-phase-policy-link' @{
        'docs/phases/PHASE_AUTHORING_GUIDE.md' = '# Guide'
        'docs/architecture/owner.md' = '[guide](../phases/PHASE_AUTHORING_GUIDE.md#guide)'
    }
    Test-Fixture 'mutable-phase-link' @{
        'docs/phases/README.md' = '# Roadmap'
        'docs/architecture/owner.md' = '[roadmap][phase]

[phase]: ../phases/README.md'
    } -Exit 1 -Message 'Durable owner links back to phase state'
    Test-Fixture 'placeholder-strict' @{'docs/owner.md' = '[INSERT_FIXTURE]'} -Exit 1 -Message 'Unresolved placeholders'
    Test-Fixture 'placeholder-warning' @{'docs/owner.md' = '[INSERT_FIXTURE]'} -NonStrict -Message '\[OK\].*1 warning'
    Test-Fixture 'duplicate-invariants' @{'docs/architecture/invariants.md' = "| INV-TEST-1 | A |`n| INV-TEST-1 | B |"} -Exit 1 -Message 'Duplicate invariant ID'
    $block = (1..50 | ForEach-Object { 'contract' + $_ }) -join ' '
    Test-Fixture 'duplicate-block' @{'docs/a.md' = $block; 'docs/b.md' = $block} -Exit 1 -Message 'Duplicate normalized long Markdown block'
    Test-Fixture 'case-distinct-blocks' @{'docs/a.md' = $block; 'docs/b.md' = $block.ToUpperInvariant()}
    foreach ($path in @('task.md', './task.md', 'docs/work/notes.md', 'docs/phases/active/phase-1-example.md')) {
        Test-Fixture ('temporary-' + $passed) @{'src/reader.ts' = "readFileSync('$path');"} -Exit 1 -Message 'Code/test consumer references temporary documentation'
    }
    Test-Fixture 'task-name-boundary' @{'src/reader.ts' = 'readFileSync("subtask.md"); readFileSync("task.md.backup");'}
    foreach ($case in @(
        @('planned', 'NOT_RUN', 0), @('planned', 'PASS', 1),
        @('completed', 'PASS', 0), @('completed', 'PARTIAL', 1),
        @('blocked', 'FAIL', 0), @('in_progress', 'BASELINE', 0)
    )) {
        $step = "# Step`n`n## Статус`n`n``$($case[0])```n`n## Верификация`n`n- Actual verdict: ``$($case[1])```n"
        $expected = if ($case[2] -eq 0) { '\[OK\]' } else { 'must use Actual verdict' }
        Test-Fixture ("status-$($case[0])-$($case[1])") @{'docs/phases/active/phase-1/step-01-example.md' = $step} -Exit $case[2] -Message $expected
    }
    Test-Fixture 'fenced-status' @{'docs/phases/active/phase-1/step-01-example.md' = '~~~markdown
## Статус

`completed`

- Actual verdict: `PASS`
~~~'} -Exit 1 -Message 'Missing or invalid lifecycle status'
    Test-Fixture 'noncanonical-phase' @{'docs/phases/active/notes.md' = '# Notes'} -Exit 1 -Message 'Non-canonical Markdown'
    Test-Fixture 'template-example-outside-template' @{'docs/example.md' = '[Step](./phase-N/step-01-name.md)'} -Exit 1 -Message 'Broken local link'
} finally {
    # Delete only the unique temporary directory created by this run, using one shell.
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    if ($failed -eq 0 -and $resolvedFixture.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $resolvedFixture -Leaf) -match '^validate-docs-tests-[a-f0-9]{32}$') {
        if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
    } else {
        Write-Host "Fixture evidence: $fixtureRoot"
    }
}
Write-Host "Validator regression tests: $passed passed, $failed failed."
if ($failed -gt 0) { exit 1 }
