<#
Preflight and postflight checks for agentic-dev-kit skills; run from the user's repo root.
Usage: check.ps1 -Phase pre|post -Skill ado-implement|pr-review|branch-policies [-SkipChecks git,az,gh,node,dotnet]
#>
param(
  [Parameter(Mandatory)][ValidateSet('pre', 'post')][string]$Phase,
  [Parameter(Mandatory)][ValidateSet('ado-implement', 'pr-review', 'branch-policies')][string]$Skill,
  [ValidateSet('git', 'az', 'gh', 'node', 'dotnet')][string[]]$SkipChecks = @()
)

$script:Fails = 0
function Report([string]$Status, [string]$Check, [string]$Hint = '') {
  Write-Output ('{0,-5} {1,-28} {2}' -f $Status, $Check, $Hint)
  if ($Status -eq 'FAIL') { $script:Fails++ }
}
function Have([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
# Report SKIP and return true when the user chose to skip check $Id.
function Skipped([string]$Id, [string]$Label) {
  if ($SkipChecks -contains $Id) { Report SKIP $Label 'skipped by the user'; return $true }
  $false
}

if (-not (Have git)) { Report FAIL 'git' 'not installed; run install.ps1'; exit 1 }
git rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) { Report FAIL 'git repository' 'run from inside a git work tree'; exit 1 }

$stateDir = Join-Path (git rev-parse --absolute-git-dir) 'agentic-dev-kit'
$remoteUrl = git remote get-url origin 2>$null
$hostKind = if ($remoteUrl -match 'github\.com') { 'github' }
elseif ($remoteUrl -match 'dev\.azure\.com|visualstudio\.com') { 'azure-repos' }
else { 'unknown' }

function Invoke-Pre {
  $ver = ((git --version) -split ' ')[2]
  $parts = $ver.Split('.')
  if (Skipped git "git $ver") { }
  elseif ([int]$parts[0] -gt 2 -or ([int]$parts[0] -eq 2 -and [int]$parts[1] -ge 23)) {
    Report PASS "git $ver"
  } else {
    Report FAIL "git $ver" "need 2.23+ for 'git switch'; run install.ps1"
  }

  if ($hostKind -eq 'unknown') {
    Report WARN 'origin remote' 'not Azure Repos or GitHub; PR steps will need manual help'
  } else {
    Report PASS "origin: $hostKind"
  }

  if (Skipped az 'az CLI') { }
  elseif (Have az) {
    az extension show --name azure-devops *> $null
    if ($LASTEXITCODE -eq 0) { Report PASS 'az + azure-devops' }
    else { Report WARN 'azure-devops extension' 'az extension add --name azure-devops' }
    az account show *> $null
    if ($LASTEXITCODE -eq 0) { Report PASS 'az login' }
    else { Report WARN 'az login' "run 'az login' in your own terminal (CLI fallback only)" }
  } else {
    Report WARN 'az CLI' "needed only when the ADO MCP server can't sign in; run install.ps1"
  }

  if ($hostKind -eq 'github' -and -not (Skipped gh 'gh CLI')) {
    if (-not (Have gh)) { Report FAIL 'gh CLI' 'needed for GitHub PRs; run install.ps1' }
    else {
      gh --version *> $null
      if ($LASTEXITCODE -ne 0) {
        Report FAIL 'gh CLI' "$((Get-Command gh).Source) won't run in this session. If gh works in your terminal, restart VS Code so it reloads PATH; otherwise reinstall gh"
      } else {
        gh auth status *> $null
        if ($LASTEXITCODE -eq 0) { Report PASS 'gh + auth' }
        else { Report FAIL 'gh auth' "run 'gh auth login' in your own terminal" }
      }
    }
  }

  if ($Skill -eq 'ado-implement' -and (Test-Path package.json) -and -not (Skipped node 'node / npx')) {
    if ((Have node) -and (Have npx)) { Report PASS "node $(node --version)" }
    else { Report WARN 'node / npx' 'needed for Playwright and axe tests; run install.ps1' }
  }

  if ($Skill -eq 'ado-implement' -and (git ls-files '*.sln' '*.slnx' '*.csproj' | Select-Object -First 1) -and -not (Skipped dotnet 'dotnet SDK')) {
    if (Have dotnet) { Report PASS "dotnet $(dotnet --version)" }
    else { Report WARN 'dotnet SDK' 'needed to build, test, and lint .NET code; https://dot.net' }
  }

  if (git status --porcelain) { Report WARN 'working tree dirty' 'the skill will ask to stash, commit, or stop' }
  else { Report PASS 'working tree clean' }

  New-Item -ItemType Directory -Force -Path (Join-Path $stateDir 'tmp') | Out-Null
  $startBranch = git symbolic-ref --quiet --short HEAD 2>$null
  if ($LASTEXITCODE -ne 0) { $startBranch = git rev-parse HEAD }
  @(
    "skill=$Skill"
    "start_branch=$startBranch"
    "stash_count=$(@(git stash list).Count)"
    "skipped=$($SkipChecks -join ',')"
  ) | Set-Content -Path (Join-Path $stateDir 'state')
  Report PASS 'state recorded' $stateDir
}

function Invoke-Post {
  $statePath = Join-Path $stateDir 'state'
  if (-not (Test-Path $statePath)) { Report FAIL 'preflight state' "run 'check.ps1 -Phase pre -Skill $Skill' first"; return }
  $state = Get-Content -Raw $statePath | ConvertFrom-StringData
  $branch = git symbolic-ref --quiet --short HEAD 2>$null
  if ($LASTEXITCODE -ne 0) { $branch = 'DETACHED' }

  $dirty = @(git status --porcelain)
  if ($dirty.Count -eq 0) { Report PASS 'working tree clean' }
  else { Report WARN 'working tree dirty' "$($dirty.Count) path(s) uncommitted" }

  $leftover = @(git stash list).Count - [int]$state.stash_count
  if ($leftover -gt 0) { Report FAIL 'stash' "$leftover stash(es) left behind; restore with 'git stash pop'" }
  else { Report PASS 'stash restored' }

  switch ($Skill) {
    { $_ -in 'pr-review', 'branch-policies' } {
      if ($branch -eq $state.start_branch) { Report PASS "back on $branch" }
      else { Report FAIL 'branch' "on $branch; the user started on $($state.start_branch)" }
    }
    'ado-implement' {
      if ($branch -eq 'DETACHED') { Report FAIL 'branch' 'detached HEAD' }
      else {
        git rev-parse --abbrev-ref '@{u}' *> $null
        if ($LASTEXITCODE -ne 0) { Report WARN 'upstream' "$branch is not pushed" }
        else {
          $ahead = [int](git rev-list --count '@{u}..HEAD')
          if ($ahead -eq 0) { Report PASS "$branch pushed" }
          else { Report WARN 'upstream' "$ahead commit(s) not pushed" }
        }
      }
    }
  }

  # Keep state on failure so the check can be rerun after fixing.
  if ($script:Fails -eq 0) {
    Remove-Item -Recurse -Force $stateDir
    Report PASS 'temp files removed'
  }
}

if ($Phase -eq 'pre') { Invoke-Pre } else { Invoke-Post }
exit [int]($script:Fails -gt 0)
