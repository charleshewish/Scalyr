function Install-Scalyr {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,

        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )

    $msiPath    = "$env:TEMP\ScalyrAgentInstaller.msi"
    $configUrl  = "https://raw.githubusercontent.com/YOUR_GITHUB_USER/YOUR_REPO/main/$ConfigFile"
    $configPath = "C:\Program Files (x86)\Scalyr\config\agent.json"
    $serviceName = "ScalyrAgent"

    # Check if service exists (i.e. agent installed)
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-Host "Scalyr Agent not detected. Installing..."
        Invoke-WebRequest -Uri "https://www.scalyr.com/scalyr-agent-2/latest/ScalyrAgentInstaller.msi" -OutFile $msiPath
        Start-Process msiexec.exe -ArgumentList '/i',$msiPath,'/qn' -Wait
    } else {
        Write-Host "Scalyr Agent already installed. Skipping MSI installation."
    }

    Write-Host "Fetching config $ConfigFile from GitHub..."
    $config = Invoke-WebRequest -Uri $configUrl | Select-Object -ExpandProperty Content
    $config = $config -replace 'API_KEY_PLACEHOLDER',$ApiKey

    Write-Host "Writing config to $configPath"
    Set-Content -Path $configPath -Value $config -Encoding UTF8

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
