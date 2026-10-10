[CmdletBinding()]
param(
    [switch]$Strict
)

# Developer guide: docs/validate-docs.md. Paths below are relative to the repo root.
# A trailing '/' excludes a directory and its descendants; otherwise an exact file.
$excludedPaths = @(
    'docs/work/'
    'docs/audits/audit.md'
    'docs/plans/plan.md'
    'scripts/test-validate-docs.ps1' # Maintainer fixtures intentionally contain forbidden paths.
    # 'docs/custom/'              # Example: ignore a documentation directory.
    # 'src/generated/'            # Example: ignore generated source.
    # 'docs/example.md'           # Example: ignore one document.
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$anchorCache = @{}

function Get-RelativePath {
    param([Parameter(Mandatory)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    return $fullPath.Substring($script:repoRoot.Length).TrimStart([char[]]'\/').Replace('\', '/')
}

function Test-ExcludedPath {
    param([string]$Path)

    if (-not $Path.StartsWith($script:repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    $relative = Get-RelativePath $Path
    foreach ($entry in $script:excludedPaths) {
        $entry = $entry.Replace('\', '/')
        if ($entry.EndsWith('/')) {
            if ($relative -eq $entry.TrimEnd('/') -or $relative.StartsWith($entry, [StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        } elseif ($relative -eq $entry) {
            return $true
        }
    }
    return $false
}

function Get-ValidationFiles {
    param([string]$Directory, [switch]$Recurse)

    if ((Test-ExcludedPath $Directory) -or -not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return
    }
    foreach ($item in Get-ChildItem -LiteralPath $Directory) {
        if (Test-ExcludedPath $item.FullName) { continue }
        if ($item.PSIsContainer) {
            if ($Recurse) { Get-ValidationFiles $item.FullName -Recurse }
        } else {
            $item
        }
    }
}

function Add-Issue {
    param(
        [Parameter(Mandatory)][string]$Message,
        [switch]$Warning
    )

    if ($Warning) {
        $script:warnings.Add($Message)
    } else {
        $script:errors.Add($Message)
    }
}

function Get-MarkdownWithoutFencedCode {
    param([AllowEmptyString()][string]$Content)

    $fence = $null
    $lines = foreach ($line in $Content -split '\r?\n') {
        if ($null -ne $fence) {
            if ($line -match ('^ {0,3}' + [regex]::Escape($fence[0]) + '{' + $fence.Length + ',}[ \t]*$')) {
                $fence = $null
            }
            ''
        } elseif ($line -match '^ {0,3}(?<fence>`{3,}|~{3,})') {
            $fence = $Matches.fence
            ''
        } else {
            $line
        }
    }
    return $lines -join "`n"
}

function Get-NormalizedLongMarkdownBlocks {
    param([AllowEmptyString()][string]$Content)

    $withoutFencedCode = Get-MarkdownWithoutFencedCode $Content
    $blockNumber = 0
    foreach ($block in [regex]::Split($withoutFencedCode, '(?:\r?\n[ \t]*){2,}')) {
        $blockNumber++
        $normalized = [regex]::Replace($block, '\s+', ' ').Trim()

        # Ignore short shared labels; this is a duplicate-block filter, not a file budget.
        if ($normalized.Length -ge 240) {
            [pscustomobject]@{
                Number = $blockNumber
                Text = $normalized
            }
        }
    }
}

# Supported Markdown link forms are documented in docs/validate-docs.md; this is not a renderer.
function Get-MarkdownLinks {
    param([AllowEmptyString()][string]$Content)

    $text = Get-MarkdownWithoutFencedCode $Content
    $text = [regex]::Replace($text, '(?s)(?<!`)(`+)(?!`).*?(?<!`)\1(?!`)', '')
    $definitions = @{}
    $definitionPattern = '(?m)^ {0,3}\[(?<label>[^\]\r\n]+)\]:[ \t]*(?:<(?<target>[^>\r\n]+)>|(?<target>\S+))(?:[ \t]+[^\r\n]*)?$'
    foreach ($match in [regex]::Matches($text, $definitionPattern)) {
        $label = [regex]::Replace($match.Groups['label'].Value.Trim(), '\s+', ' ')
        if (-not $definitions.ContainsKey($label)) {
            $definitions[$label] = $match.Groups['target'].Value
        }
    }
    $text = [regex]::Replace($text, $definitionPattern, '')
    # .NET balancing groups keep parentheses inside a destination paired.
    $inlinePattern = '\[(?:\\.|[^\]\\])*\]\(\s*(?:<(?<target>[^<>\r\n]*)>|(?<target>(?:\\.|[^\s()\\]|\((?<depth>)|\)(?<-depth>))*)(?(depth)(?!)))\s*(?:(?:"[^"]*"|''[^'']*''|\([^)]*\))\s*)?\)'
    foreach ($match in [regex]::Matches($text, $inlinePattern)) {
        $match.Groups['target'].Value
    }
    $text = [regex]::Replace($text, $inlinePattern, '')
    foreach ($match in [regex]::Matches($text, '\[(?<label>[^\]\r\n]+)\](?:\[(?<reference>[^\]\r\n]*)\])?')) {
        $label = $match.Groups['reference'].Value
        if ([string]::IsNullOrEmpty($label)) {
            $label = $match.Groups['label'].Value
        }
        $label = [regex]::Replace($label.Trim(), '\s+', ' ')
        if ($definitions.ContainsKey($label)) {
            $definitions[$label]
        }
    }
}

function Get-MarkdownAnchors {
    param([AllowEmptyString()][string]$Content)

    $text = Get-MarkdownWithoutFencedCode $Content
    $anchors = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $previous = ''
    foreach ($line in $text -split '\r?\n') {
        $heading = $null
        if ($line -match '^ {0,3}#{1,6}[ \t]+(?<heading>.*?)(?:[ \t]+#+[ \t]*)?$') {
            $heading = $Matches.heading
        } elseif ($previous.Trim().Length -gt 0 -and $line -match '^ {0,3}(?:=+|-+)[ \t]*$') {
            $heading = $previous.Trim()
        }
        $previous = $line
        if ($null -eq $heading) { continue }
        $heading = [regex]::Replace($heading, '\[([^\]]+)\]\([^)]*\)', '$1')
        $heading = [regex]::Replace($heading, '<[^>]+>', '')
        # Strip underscore emphasis without changing underscores inside inline code.
        $heading = [regex]::Replace($heading, '(?<ticks>`+)(?<code>.*?)\k<ticks>|(?<![\p{L}\p{N}])(?<marker>_{1,3})(?<emphasis>\S(?:.*?\S)?)\k<marker>(?![\p{L}\p{N}])', {
            param($match)
            if ($match.Groups['ticks'].Success) { return $match.Groups['code'].Value }
            return $match.Groups['emphasis'].Value
        })
        $heading = [System.Net.WebUtility]::HtmlDecode($heading).ToLowerInvariant()
        $slug = [regex]::Replace($heading, '[^\p{L}\p{M}\p{N}_\- ]', '').Replace(' ', '-')
        $anchor = $slug
        $suffix = 0
        while (-not $anchors.Add($anchor)) {
            $suffix++
            $anchor = "$slug-$suffix"
        }
    }
    foreach ($match in [regex]::Matches($text, '<[A-Za-z][^>]*?\s(?:id|name)\s*=\s*["''](?<anchor>[^"'']+)["''][^>]*>')) {
        [void]$anchors.Add($match.Groups['anchor'].Value)
    }
    return ,$anchors
}

$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$invariantsPath = Join-Path $repoRoot 'docs/architecture/invariants.md'

foreach ($requiredPath in @($agentsPath, $invariantsPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Add-Issue "Missing required file: $(Get-RelativePath $requiredPath)"
    }
}

$markdownFiles = @(
    Get-ValidationFiles $repoRoot
    Get-ValidationFiles (Join-Path $repoRoot 'docs') -Recurse
) | Where-Object Extension -eq '.md' | Sort-Object FullName -Unique

foreach ($file in $markdownFiles) {
    $content = [string](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
    $source = Get-RelativePath $file.FullName
    $isActivePhaseParent =
        $source -match '^docs/phases/active/phase-\d+-[^/]+\.md$'
    $isActivePhaseStep =
        $source -match '^docs/phases/active/phase-\d+(?:-[^/]+)?/step-\d+-.+\.md$'
    $isCompletedPhaseParent =
        $source -match '^docs/phases/completed/phase-\d+-.+\.md$'

    if (
        $source -match '^docs/phases/active/' -and
        -not $isActivePhaseParent -and
        -not $isActivePhaseStep
    ) {
        Add-Issue "Non-canonical Markdown file under active phases: $source"
    }
    if ($source -match '^docs/phases/completed/' -and -not $isCompletedPhaseParent) {
        Add-Issue "Non-canonical Markdown file under completed phases: $source"
    }

    foreach ($target in Get-MarkdownLinks $content) {

        $isPhaseTemplateExample =
            $source -eq 'docs/phases/templates/phase-template.md' -and
            $target -match '^\./phase-N/step-(01|02|03|XX)-name\.md$'
        $isStepTemplateExample =
            $source -eq 'docs/phases/templates/step-template.md' -and
            $target -eq '../phase-N-name.md'

        if ($isPhaseTemplateExample -or $isStepTemplateExample) {
            continue
        }

        if (
            [string]::IsNullOrWhiteSpace($target) -or
            $target -match '^(?:[a-zA-Z][a-zA-Z0-9+.-]*:|//)'
        ) {
            continue
        }

        try {
            $parts = $target -split '#', 2
            $pathPart = [System.Uri]::UnescapeDataString(($parts[0] -split '\?', 2)[0])
            $pathPart = [regex]::Replace($pathPart, '\\([^\p{L}\p{N}\s])', '$1')
            $candidate = if ([string]::IsNullOrEmpty($pathPart)) {
                $file.FullName
            } else {
                [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $pathPart))
            }
        } catch {
            Add-Issue "Invalid local link '$target' in $source"
            continue
        }

        if (-not (Test-Path -LiteralPath $candidate)) {
            Add-Issue "Broken local link '$target' in $source"
            continue
        }

        $phaseRoot = Join-Path $repoRoot 'docs/phases'
        if (
            $source -like 'docs/architecture/*' -and (
                $candidate.StartsWith((Join-Path $phaseRoot 'active') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
                $candidate.StartsWith((Join-Path $phaseRoot 'completed') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
                $candidate -eq (Join-Path $phaseRoot 'README.md') -or
                $candidate -eq (Join-Path $phaseRoot 'COMPLETED_PHASES.md')
            )
        ) {
            Add-Issue "Durable owner links back to phase state: $source -> $target"
        }

        if ($parts.Count -gt 1 -and $parts[1].Length -gt 0 -and [IO.Path]::GetExtension($candidate) -eq '.md' -and
            -not (Test-ExcludedPath $candidate)) {
            $fragment = [System.Uri]::UnescapeDataString($parts[1])
            if (-not $anchorCache.ContainsKey($candidate)) {
                $anchorCache[$candidate] = Get-MarkdownAnchors ([IO.File]::ReadAllText($candidate))
            }
            if (-not $anchorCache[$candidate].Contains($fragment)) {
                Add-Issue "Broken Markdown anchor '$target' in $source"
            }
        }
    }

    $placeholders = @(
        [regex]::Matches($content, '\[INSERT_[A-Z0-9_]+\]') |
            ForEach-Object Value |
            Sort-Object -Unique
    )

    if ($placeholders.Count -gt 0) {
        $message = "Unresolved placeholders in ${source}: $($placeholders -join ', ')"
        Add-Issue $message -Warning:(-not $Strict)
    }

    $prose = Get-MarkdownWithoutFencedCode $content
    if ($isActivePhaseStep) {
        $statusMatch = [regex]::Match(
            $prose,
            '(?ms)^## Статус\s*\r?\n\s*`(?<status>planned|in_progress|blocked|completed)`\s*$'
        )
        $verdictMatch = [regex]::Match(
            $prose,
            '(?m)^\s*-\s*Actual verdict:\s*`(?<verdict>NOT_RUN|PASS|FAIL|PARTIAL|BASELINE)`\s*$'
        )

        if (-not $statusMatch.Success) {
            Add-Issue "Missing or invalid lifecycle status in phase step: $source"
        }
        if (-not $verdictMatch.Success) {
            Add-Issue "Missing or invalid Actual verdict in phase step: $source"
        }
        if (
            $statusMatch.Success -and
            $verdictMatch.Success -and
            $statusMatch.Groups['status'].Value -eq 'planned' -and
            $verdictMatch.Groups['verdict'].Value -ne 'NOT_RUN'
        ) {
            Add-Issue "Planned phase step must use Actual verdict NOT_RUN: $source"
        }
        if (
            $statusMatch.Success -and
            $verdictMatch.Success -and
            $statusMatch.Groups['status'].Value -eq 'completed' -and
            $verdictMatch.Groups['verdict'].Value -ne 'PASS'
        ) {
            Add-Issue "Completed phase step must use Actual verdict PASS: $source"
        }
    }

    if ($isActivePhaseParent) {
        $parentStatusMatch = [regex]::Match(
            $prose,
            '(?ms)^## Статус\s*\r?\n\s*`(?<status>planned|in_progress|blocked|completed)`\s*·\s*Current:\s*\[[^\]]+\]\([^)]+\)\s*$'
        )

        if (-not $parentStatusMatch.Success) {
            Add-Issue "Missing or invalid lifecycle status in active phase parent: $source"
        }
    }

    if (
        $isCompletedPhaseParent -and
        $prose -notmatch '(?ms)^## Статус\s*\r?\n\s*✅ Завершена\s*$'
    ) {
        Add-Issue "Completed phase parent must use exact status '✅ Завершена': $source"
    }
}

$nonDurableMarkdownPattern =
    '^(?:task\.md|docs/(?:work|plans|audits)(?:/|$))'
$durableMarkdownFiles = @(
    $markdownFiles |
        Where-Object {
            (Get-RelativePath $_.FullName) -notmatch $nonDurableMarkdownPattern
        }
)
$normalizedLongBlocks = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new([System.StringComparer]::Ordinal)

foreach ($file in $durableMarkdownFiles) {
    $content = [string](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
    $source = Get-RelativePath $file.FullName

    foreach ($block in Get-NormalizedLongMarkdownBlocks $content) {
        if (-not $normalizedLongBlocks.ContainsKey($block.Text)) {
            $normalizedLongBlocks[$block.Text] = [System.Collections.Generic.List[string]]::new()
        }
        $normalizedLongBlocks[$block.Text].Add("$source#block-$($block.Number)")
    }
}

$duplicateLongBlockGroups = @(
    foreach ($entry in $normalizedLongBlocks.GetEnumerator()) {
        if ($entry.Value.Count -gt 1) {
            $locations = @($entry.Value | Sort-Object)
            [pscustomobject]@{
                Locations = $locations
                SortKey = $locations -join '|'
            }
        }
    }
)

foreach ($group in $duplicateLongBlockGroups | Sort-Object SortKey) {
    Add-Issue "Duplicate normalized long Markdown block: $($group.Locations -join ', ')"
}

$temporaryDocConsumerRoots = @(
    'src',
    'lib',
    'inertia',
    'app',
    'config',
    'database',
    'providers',
    'scripts',
    'start',
    'tests'
)
$temporaryDocConsumerExtensions = @('.js', '.jsx', '.mjs', '.mts', '.ps1', '.ts', '.tsx', '.vue', '.py', '.go', '.rs', '.java', '.cs')
$temporaryDocReferencePattern =
    '(?i)docs[\\/](?:phases[\\/]active|work|plans|audits)(?:[\\/]|$)|(?<![\w.-])task\.md(?![\w.-])'

foreach ($rootName in $temporaryDocConsumerRoots) {
    $rootPath = Join-Path $repoRoot $rootName
    if (-not (Test-Path -LiteralPath $rootPath)) {
        continue
    }

    foreach ($file in Get-ValidationFiles $rootPath -Recurse) {
        if (
            $file.FullName -eq $PSCommandPath -or
            $file.Extension -notin $temporaryDocConsumerExtensions
        ) {
            continue
        }

        $content = [string](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
        if ($content -match $temporaryDocReferencePattern) {
            Add-Issue "Code/test consumer references temporary documentation: $(Get-RelativePath $file.FullName)"
        }
    }
}

if ((Test-Path -LiteralPath $invariantsPath) -and -not (Test-ExcludedPath $invariantsPath)) {
    $ids = @(
        foreach ($line in Get-Content -LiteralPath $invariantsPath -Encoding UTF8) {
            if ($line -match '^\|\s*(INV-[A-Z]+-\d+)\s*\|') {
                $Matches[1]
            }
        }
    )

    foreach ($duplicate in $ids | Group-Object | Where-Object Count -gt 1) {
        Add-Issue "Duplicate invariant ID: $($duplicate.Name)"
    }
}

Write-Host "Docs validation: $repoRoot"
$warnings | ForEach-Object { Write-Host "[WARN] $_" }
$errors | ForEach-Object { Write-Host "[ERROR] $_" }

if ($errors.Count -gt 0) {
    Write-Host "[FAIL] $($errors.Count) error(s), $($warnings.Count) warning(s)."
    exit 1
}

Write-Host "[OK] Structural checks passed with $($warnings.Count) warning(s)."
