param (
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,

    [Parameter(Mandatory=$true)]
    [string]$ConfigFile
)

$msiPath   = "$env:TEMP\ScalyrAgentInstaller.msi"
$configUrl = "https://raw.githubusercontent.com/charleshewish/Scalyr/Windows/$ConfigFile"
$configPath = "C:\Program Files (x86)\Scalyr\config\agent.json"

Write-Host "Downloading Scalyr Agent installer..."
Invoke-WebRequest -Uri "https://www.scalyr.com/scalyr-agent-2/latest/ScalyrAgentInstaller.msi" -OutFile $msiPath

Write-Host "Installing Scalyr Agent..."
Start-Process msiexec.exe -ArgumentList '/i',$msiPath,'/qn' -Wait

Write-Host "Fetching config $ConfigFile from GitHub..."
$config = Invoke-WebRequest -Uri $configUrl | Select-Object -ExpandProperty Content
$config = $config -replace 'API_KEY_PLACEHOLDER',$ApiKey

Write-Host "Writing config to $configPath"
Set-Content -Path $configPath -Value $config

Write-Host "Restarting Scalyr Agent service..."
Restart-Service ScalyrAgent

Write-Host "Installation complete with config $ConfigFile!"
