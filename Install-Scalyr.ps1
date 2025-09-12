function Install-Scalyr {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,

        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )

    $msiUrl    = "https://app.scalyr.com/scalyr-repo/stable/latest/ScalyrAgentInstaller-2.2.18.msi"
    $msiPath   = "$env:TEMP\ScalyrAgentInstaller.msi"
    $configUrl = "https://raw.githubusercontent.com/charleshewish/Scalyr/refs/heads/Windows/$ConfigFile"
    $configPath = "C:\Program Files (x86)\Scalyr\config\agent.json"
    $serviceName = "ScalyrAgent"

    # Check if service exists (i.e. agent installed)
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-Host "Scalyr Agent not detected. Installing..."
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath
        Start-Process msiexec.exe -ArgumentList '/i',$msiPath,'/qn' -Wait
    } else {
        Write-Host "Scalyr Agent already installed. Skipping MSI installation."
    }

    Write-Host "Fetching config $ConfigFile from GitHub..."
    $config = Invoke-WebRequest -Uri $configUrl | Select-Object -ExpandProperty Content
    $config = $config -replace 'API_KEY_PLACEHOLDER',$ApiKey

    # Write config as SYSTEM using a temporary scheduled task
$tempScript = "$env:TEMP\WriteAgentConfig.ps1"
$scheduledTaskName = "WriteScalyrConfigTemp"

# Save a small script to write the config
Set-Content -Path $tempScript -Value @"
Set-Content -Path '$configPath' -Value @'
$config
'@ -Encoding UTF8
"@

# Create scheduled task to run as SYSTEM once
schtasks /create /tn $scheduledTaskName /tr "powershell.exe -ExecutionPolicy Bypass -File `"$tempScript`"" /sc once /st 00:00 /RL HIGHEST /F
schtasks /run /tn $scheduledTaskName

# Cleanup
Start-Sleep -Seconds 5
schtasks /delete /tn $scheduledTaskName /f
Remove-Item $tempScript -Force


    Write-Host "Restarting Scalyr Agent service..."
    if (-not $service) { $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue }
    if ($service) {
        Restart-Service $serviceName
        Write-Host "Service restarted."
    } else {
        Write-Warning "Could not restart $serviceName (service not found)."
    }

    Write-Host "Done! Agent is installed and configured with $ConfigFile."
}
