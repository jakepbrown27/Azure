$registrationToken = ""

# Define the registration token 
$sxsMsi = (Get-ChildItem "$env:SystemDrive\Program Files\Microsoft RDInfra\" | ? Name -like SxSStack*.msi | Sort-Object CreationTime -Descending | Select-Object -First 1).FullName


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
    },
    [PSCustomObject]@{
         Name       = "Windows Virtual Desktop Side-by-Side Stack"
         LocalPath  = $sxsMsi
         NeedsToken = $false
    },
    [PSCustomObject]@{
         Name       = "Microsoft RD Geneva Installer"
         LocalPath  = "C:\Program Files\Microsoft RDInfra\Microsoft.RDInfra.Geneva.Installer-x64-46.5.1"
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
 
