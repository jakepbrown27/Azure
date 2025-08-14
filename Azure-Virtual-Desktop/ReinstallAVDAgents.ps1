$registrationToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjM0MUM1MzlBMUU0MTg1QkY4OUY3RUUzNzMxMDA5QkI1QUVDM0NERUQiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjIxNWE5MGJjLTM4M2ItNDYwMC1iNzNmLTU3MWM2ZmFiM2U2NSIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy1qcC1yMS53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLWpwLXIxLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiZDBkZmI5NjAtNTk3Yi00YmQ2LTg1YWItMDhiMzYwZTdlYThjIiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJKUCIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL2QwZGZiOTYwLTU5N2ItNGJkNi04NWFiLTA4YjM2MGU3ZWE4Yy5yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJCcm9rZXJSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly9kMGRmYjk2MC01OTdiLTRiZDYtODVhYi0wOGIzNjBlN2VhOGMucmRicm9rZXItZy1qcC1yMS53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1Jlc291cmNlSWRVcmkiOiJodHRwczovL2QwZGZiOTYwLTU5N2ItNGJkNi04NWFiLTA4YjM2MGU3ZWE4Yy5yZGRpYWdub3N0aWNzLWctanAtcjEud3ZkLm1pY3Jvc29mdC5jb20vIiwiQUFEVGVuYW50SWQiOiJjZjM2MTQxYy1kZGQ3LTQ1YTctYjA3My0xMTFmNjZkMGIzMGMiLCJuYmYiOjE3NTUxMjQxNjcsImV4cCI6MTc1NTEzMTM2MywiaXNzIjoiUkRJbmZyYVRva2VuTWFuYWdlciIsImF1ZCI6IlJEbWkifQ.iyVeNVwaPwHFZTu_ElWNn7uRNsovl26X3yKp6ipuegFIK6CWa9b7vaqy1YukDPG10XemLbDS3xAzt6T_yM_cULaNkLqOX3PeE-RZ7q6vsjaFFrOQ5EJgESy7u-nD8yk6Dryz28CdDsKaEfmlAfizk-TFdefGbpMiPl6RZ6bz9SbdGWoAoQxbH2Eu61qyF1A0qB93ER5kEMMsqXn0swjpfPwY429XNEBbLouS-dndhl9hJmPnkvWO-gWIocbgGMMw1sJ2ZY5CPG8mNBkk8FKv0nWQafzIGd45_KyfhQpT9KE6LSNYihP959hqNLiCfOb_1Rf63ABBf6DkcGQdYM7cHw"

# Define the registration token 
# Define installer details for the components.
# For each component, we specify:
#   - Name: A descriptive name for logging.
#   - (For downloads) Url: The download URL for the MSI installer.
#   - (For downloads) FileName: The filename to use when saving the MSI.
#   - LocalPath: For installers already on the machine.
#   - NeedsToken: Indicates whether the installer requires the registration token.
$installers = @(
    [PSCustomObject]@{
         Name       = "Azure Virtual Desktop Agent"
         Url        = "https://go.microsoft.com/fwlink/?linkid=2310011"
         FileName   = "AVDAgent.msi"
         NeedsToken = $true
    },
    [PSCustomObject]@{
         Name       = "Azure Virtual Desktop Agent Bootloader"
         Url        = "https://go.microsoft.com/fwlink/?linkid=2311028"
         FileName   = "AVDAgentBootloader.msi"
         NeedsToken = $false
    }
)

# Create a temporary folder to store the downloaded installers.
$tempFolder = "$env:TEMP\AVDInstallers"
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory | Out-Null
}

# Function to download an installer MSI from a given URL.
function Download-Installer {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )
    try {
        Write-Output "Downloading installer from $Url ..."
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing
        Write-Output "Downloaded installer to: $DestinationPath"
    }
    catch {
        Write-Error "ERROR: Failed to download from $Url. $_"
        throw
    }
}

# Function to install an MSI package.
# If $NeedsToken is $true, the registration token is passed to the installer.
function Install-MSI {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MsiPath,
        [Parameter(Mandatory = $true)]
        [string]$ProductName,
        [Parameter(Mandatory = $true)]
        [bool]$NeedsToken,
        [Parameter(Mandatory = $false)]
        [string]$RegistrationToken = ""
    )
    Write-Output "Installing $ProductName..."
    
    if ($NeedsToken) {
        # Construct the msiexec command with the registration token.
        $arguments = "/i `"$MsiPath`" REGISTRATIONTOKEN=`"$RegistrationToken`" /qn /norestart"
    }
    else {
        # Construct the msiexec command without the token.
        $arguments = "/i `"$MsiPath`" /qn /norestart"
    }
    
    try {
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Output "Successfully installed $ProductName."
        }
        else {
            Write-Warning "Installation of $ProductName exited with code $($process.ExitCode)."
        }
    }
    catch {
        Write-Error "ERROR: Installation of $ProductName failed. $_"
    }
}

# Process each installer:
# - If the installer has a LocalPath defined, use it.
# - Otherwise, download the installer MSI to the temporary folder.
foreach ($installer in $installers) {
    if ($installer.PSObject.Properties.Name -contains "LocalPath") {
        Write-Output "Using local installer for $($installer.Name): $($installer.LocalPath)"
        $msiPath = $installer.LocalPath
    }
    else {
        $destination = Join-Path -Path $tempFolder -ChildPath $installer.FileName
        Download-Installer -Url $installer.Url -DestinationPath $destination
        $msiPath = $destination
    }
    
}

Set-ItemProperty -Path "HKLM:\Software\Microsoft\RDInfraAgent" -Name "IsRegistered" -Value 1

Write-Output "Reinstallation of all components completed."
Restart-Computer
 
