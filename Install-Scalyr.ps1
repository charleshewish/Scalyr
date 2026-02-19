#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads and installs the Scalyr Agent, applies a specified config, and injects an API key.

.PARAMETER ApiToken
    The Scalyr API key to inject into the config file.

.PARAMETER ConfigFile
    The name of the agent config file to download from GitHub (e.g. Agent1.json).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -Command "iwr -useb 'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/Install-Scalyr.ps1' | iex" -ApiToken "abc123" -ConfigFile "Agent1.json"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiToken,

    [Parameter(Mandatory = $true)]
    [string]$ConfigFile
)

$ErrorActionPreference = "Stop"

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
$MsiUrl         = "https://app.scalyr.com/scalyr-repo/stable/latest/ScalyrAgentInstaller-2.2.18.msi"
$GitHubRawBase  = "https://raw.githubusercontent.com/charleshewish/Scalyr/refs/heads/Windows"
$AgentConfigDir = "C:\Program Files (x86)\Scalyr\config"
$AgentConfigDst = Join-Path $AgentConfigDir "agent.json"
$TempDir        = $env:TEMP
$MsiPath        = Join-Path $TempDir "ScalyrAgentInstaller.msi"
$TempConfigPath = Join-Path $TempDir $ConfigFile
$ApiPlaceholder = "API_KEY_PLACEHOLDER"
# ──────────────────────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

# Step 1: Download the MSI
Write-Step "Downloading Scalyr Agent MSI from: $MsiUrl"
Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath -UseBasicParsing
Write-Success "MSI downloaded to: $MsiPath"

# Step 2: Install the MSI silently
Write-Step "Installing Scalyr Agent..."
$installArgs = "/i `"$MsiPath`" /qn /norestart /l*v `"$TempDir\scalyr_install.log`""
$process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "MSI installation failed with exit code: $($process.ExitCode). Check log at $TempDir\scalyr_install.log"
}
Write-Success "Scalyr Agent installed successfully."

# Step 3: Download the specified agent config from GitHub
$ConfigUrl = "$GitHubRawBase/$ConfigFile"
Write-Step "Downloading config '$ConfigFile' from: $ConfigUrl"
Invoke-WebRequest -Uri $ConfigUrl -OutFile $TempConfigPath -UseBasicParsing
Write-Success "Config downloaded to: $TempConfigPath"

# Step 4: Inject the API key into the config
Write-Step "Injecting API key into config..."
$configContent = Get-Content -Path $TempConfigPath -Raw
if ($configContent -notmatch [regex]::Escape($ApiPlaceholder)) {
    throw "Placeholder '$ApiPlaceholder' not found in $ConfigFile. Verify the config template is correct."
}
$configContent = $configContent -replace [regex]::Escape($ApiPlaceholder), $ApiToken
Set-Content -Path $TempConfigPath -Value $configContent -Encoding UTF8
Write-Success "API key injected successfully."

# Step 5: Replace the default agent.json with the downloaded config
Write-Step "Replacing agent.json at: $AgentConfigDst"
if (-not (Test-Path $AgentConfigDir)) {
    throw "Scalyr config directory not found at '$AgentConfigDir'. Installation may have failed or used a different path."
}
Copy-Item -Path $TempConfigPath -Destination $AgentConfigDst -Force
Write-Success "agent.json replaced successfully."

# Step 6: Restart the Scalyr Agent service to apply config
Write-Step "Restarting Scalyr Agent service..."
$service = Get-Service -Name "ScalyrAgent" -ErrorAction SilentlyContinue
if ($null -eq $service) {
    Write-Warning "Scalyr Agent service not found. You may need to restart it manually."
} else {
    Restart-Service -Name "ScalyrAgent" -Force
    Write-Success "Scalyr Agent service restarted."
}

Write-Success "Scalyr Agent installation and configuration complete."
