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

    # Write config AS SYSTEM using PsExec
    $psexecPath = "$env:TEMP\PsExec.exe"
    if (-not (Test-Path $psexecPath)) {
        Write-Host "Downloading PsExec..."
        Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "$env:TEMP\PSTools.zip"
        Expand-Archive -Path "$env:TEMP\PSTools.zip" -DestinationPath "$env:TEMP" -Force
    }

    Write-Host "Writing agent.json as SYSTEM..."
    $tempFile = "$env:TEMP\agent_temp.json"
    Set-Content -Path $tempFile -Value $config -Encoding UTF8
    Start-Process -FilePath $psexecPath -ArgumentList "-s -accepteula cmd /c copy `"$tempFile`" `"$configPath`"" -Wait
    Remove-Item $tempFile -Force

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
