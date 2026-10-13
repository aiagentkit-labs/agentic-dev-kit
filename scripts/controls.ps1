<#
Print the layers of one topic's controls: the plugin default, the file the repo override extends, and the repo override.
Usage: controls.ps1 -Topic security|privacy|testing|practices|lint [-Ref <base-ref>]   (run from the user's repo root)
#>
param(
  [Parameter(Mandatory)][ValidateSet('security', 'privacy', 'testing', 'practices', 'lint')][string]$Topic,
  [string]$Ref = ''
)

$rel = switch ($Topic) {
  { $_ -in 'security', 'privacy' } { "review-controls/$Topic.md" }
  'testing' { 'testing-controls/testing.md' }
  'practices' { 'practice-controls/practices.md' }
  'lint' { 'lint-controls/lint.md' }
}
if (-not $Ref) {
  $Ref = git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>$null
  if (-not $Ref) { [Console]::Error.WriteLine('no origin/HEAD; pass -Ref origin/<base>'); exit 2 }
}

$pluginRoot = Split-Path -Parent $PSScriptRoot
$repoPath = ".github/$rel"

# The value of $Key in the text's leading --- block.
function Get-Frontmatter([string]$Text, [string]$Key) {
  $lines = $Text -split "`r?`n"
  if ($lines.Count -eq 0 -or $lines[0] -ne '---') { return '' }
  foreach ($line in $lines[1..($lines.Count - 1)]) {
    if ($line -match '^---\s*$') { break }
    if ($line -match "^${Key}:\s*(.*?)\s*$") { return $Matches[1] }
  }
  ''
}

Write-Output "=== layer 1: plugin default ($rel) ==="
Get-Content -Raw (Join-Path $pluginRoot $rel)

$repo = (git show "${Ref}:$repoPath" 2>$null) -join "`n"
$extends = if ($repo) { Get-Frontmatter $repo 'extends' } else { '' }

Write-Output ''
Write-Output "=== layer 2: extends $(if ($extends) { $extends } else { 'none' }) ==="
if ($extends) {
  if ($extends -notmatch '^(?<url>[^#]+)#(?<ref>[^:]+):(?<path>.+)$') {
    Write-Output '(not fetched: write extends as <git URL>#<ref>:<path>)'
  } elseif ($Matches.url -notmatch '^(https://|ssh://|git@)') {
    Write-Output '(not fetched: only https and ssh URLs are allowed)'
  } else {
    $url, $xref, $xpath = $Matches.url, $Matches.ref, $Matches.path
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    # Fail instead of prompting: the agent's terminal can't answer a credential prompt.
    $env:GIT_TERMINAL_PROMPT = '0'
    if (-not $env:GIT_SSH_COMMAND) { $env:GIT_SSH_COMMAND = 'ssh -o BatchMode=yes' }
    try {
      $err = git clone --quiet --depth 1 --branch $xref --filter=blob:none --no-checkout -- $url $tmp 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Output "(fetch failed: $(@($err)[0]))"
      } else {
        $shared = (git -C $tmp show "HEAD:$xpath" 2>$null) -join "`n"
        if ($LASTEXITCODE -ne 0) { Write-Output "(fetch failed: $xpath not found at $xref)" }
        else {
          Write-Output $shared
          if (Get-Frontmatter $shared 'extends') { Write-Output '(its own extends is ignored: one level only)' }
        }
      }
    } finally {
      Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
  }
}

Write-Output ''
Write-Output "=== layer 3: repo override ($repoPath at $Ref) ==="
if ($repo) { Write-Output $repo } else { Write-Output 'none' }
