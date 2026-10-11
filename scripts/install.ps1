<#
Install the tools agentic-dev-kit skills use (git, az + azure-devops, gh, node) on Windows via winget.
Usage: install.ps1 [-Yes]
#>
param([switch]$Yes)
$ErrorActionPreference = 'Stop'

function Have([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Confirm-Step([string]$Prompt) {
  if ($Yes) { return $true }
  (Read-Host "$Prompt [y/N]") -match '^[yY]$'
}

$packages = @{ git = 'Git.Git'; az = 'Microsoft.AzureCLI'; gh = 'GitHub.cli'; node = 'OpenJS.NodeJS.LTS' }
$missing = @($packages.Keys | Where-Object { -not (Have $_) } | ForEach-Object { $packages[$_] })

if ($missing.Count -gt 0) {
  if (-not (Have winget)) { Write-Error 'winget not found; install App Installer from the Microsoft Store.' }
  if (Confirm-Step "Run: winget install $($missing -join ', ') ?") {
    foreach ($id in $missing) {
      winget install --exact --id $id --accept-source-agreements --accept-package-agreements
    }
    Write-Output 'Open a new terminal so PATH picks up the new tools, then rerun this script.'
    exit 0
  }
} else {
  Write-Output 'git, az, gh, and node are installed.'
}

if (Have az) {
  az extension show --name azure-devops *> $null
  if ($LASTEXITCODE -ne 0 -and (Confirm-Step 'Run: az extension add --name azure-devops ?')) {
    az extension add --name azure-devops
  }
}

Write-Output "Sign in yourself where needed: 'az login', 'gh auth login'."
