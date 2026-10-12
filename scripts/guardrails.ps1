<#
PreToolUse guardrail: deny destructive or policy-bypassing actions, ask before writes to shared systems.
Reads the hook payload on stdin; prints a permission decision, or nothing to leave the call alone.
#>
$raw = [Console]::In.ReadToEnd()
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }
$tool = [string]$payload.tool_name
$cmd = [string]$payload.tool_input.command

function Decide([string]$Decision, [string]$Reason) {
  @{ hookSpecificOutput = @{
      hookEventName            = 'PreToolUse'
      permissionDecision       = $Decision
      permissionDecisionReason = "agentic-dev-kit: $Reason"
    } } | ConvertTo-Json -Compress -Depth 3
  exit 0
}
function Has([string]$Pattern) { $cmd -cmatch $Pattern }
function HasI([string]$Pattern) { $cmd -match $Pattern }

# Start of a command: line start or after a separator, so "legit push" never matches "git push".
$B = '(^|[;&|(`\s])'

if ($tool -cmatch '(repo_pull_request_write|repo_pull_request_thread_write|repo_create_branch|wit_work_item_write|wit_work_item_comment_write|wit_work_item_link_write|wit_work_item_attachment_upload|wit_work_item_attachment_link|pipelines_write|work_iteration_write|work_capacity_write|wiki_upsert_page|testplan_[a-z_]*_write)') {
  if ($raw -match '"bypass[a-z]*"\s*:\s*true') { Decide deny 'bypassing branch policies is blocked.' }
  Decide ask 'this writes to Azure DevOps.'
}

if (-not $cmd) { exit 0 }

$deny = [ordered]@{
  "${B}git\s+push[^;&|]*\s(--force|-f)([\s;&|]|$)"                                    = 'force push is blocked; use --force-with-lease on your own feature branch.'
  "${B}git\s+push[^;&|]*\s\+\S"                                                       = 'force push via +refspec is blocked.'
  "${B}git\s+push[^;&|]*[\s:](main|master|develop|release/[^\s;&|]+)([\s;&|]|$)"      = 'pushing directly to a protected branch is blocked; open a pull request.'
  "${B}git\s+reset[^;&|]*--hard"                                                      = 'git reset --hard discards work and is blocked.'
  "${B}git\s+clean[^;&|]*\s(-[a-zA-Z]*f|--force)"                                     = 'git clean -f deletes untracked files and is blocked.'
  "${B}git\s+branch[^;&|]*\s-[a-zA-Z]*D([\s;&|]|$)"                                   = 'force-deleting a branch is blocked.'
  "${B}git\s+(checkout|restore)[^;&|]*\s\.([\s;&|]|$)"                                = 'discarding all working-tree changes is blocked.'
  "${B}git\s+stash\s+(drop|clear)"                                                    = 'dropping stashes is blocked.'
  "${B}git\s[^;&|]*--no-verify"                                                       = 'skipping git hooks with --no-verify is blocked.'
  '--bypass-policy'                                                                   = 'bypassing branch policies is blocked.'
}
foreach ($pattern in $deny.Keys) { if (Has $pattern) { Decide deny $deny[$pattern] } }

if ((Has "${B}rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)") -or (HasI "${B}Remove-Item[^;&|]*-Recurse")) {
  if (HasI '^(rm\s+-[a-zA-Z]+|Remove-Item)\s+"?[^\s;&|]*\.git[\\/]agentic-dev-kit[^\s;&|]*"?(\s+-Recurse)?(\s+-Force)?\s*$') { exit 0 }
  Decide ask 'recursive delete; confirm the target.'
}

if (Has "${B}git\s+push") { Decide ask 'this pushes to a shared remote.' }
if (Has "${B}gh\s+pr\s+(create|merge|review|comment|close|reopen|edit|ready)") { Decide ask 'this writes to a GitHub pull request.' }
if (Has "${B}gh\s+api") {
  if (HasI '(-X|--method)[\s=]*(POST|PATCH|PUT|DELETE)') { Decide ask 'this writes through the GitHub API.' }
  if (Has 'mutation') { Decide ask 'this runs a GitHub GraphQL mutation.' }
  if (-not (Has 'graphql') -and (Has '\s(-f|-F|--field|--raw-field|--input)\s')) { Decide ask 'this writes through the GitHub API.' }
}
if (Has "${B}az\s+repos\s+policy\s+[a-z-]+\s+(create|update|delete)") { Decide ask 'this changes branch policies.' }
if (Has "${B}az\s+repos\s+pr\s+(create|update|set-vote|reviewer\s+(add|remove)|work-item\s+(add|remove))") { Decide ask 'this writes to an Azure Repos pull request.' }
if (Has "${B}az\s+boards\s+work-item\s+(create|update|delete|relation\s+(add|remove))") { Decide ask 'this writes to Azure Boards.' }
if (HasI "${B}az\s+devops\s+invoke[^;&|]*--http-method[\s=]+(POST|PATCH|PUT|DELETE)") { Decide ask 'this writes through the Azure DevOps REST API.' }

exit 0
