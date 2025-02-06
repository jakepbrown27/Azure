# List of product names to uninstall
$productsToRemove = @(
    "Remote Desktop Agent Boot Loader",
    "Remote Desktop Services Infrastructure Agent",
    "Remote Desktop Services Infrastructure Geneva Agent",
    "Remote Desktop Services SxS Network Stack"
)

# Function that finds and uninstalls an application by its display name
function Uninstall-Application {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName
    )
    
    Write-Output "Searching for application: $AppName"

    # Define the registry paths where uninstall information is stored
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    $found = $false
    
    foreach ($path in $registryPaths) {
        # Get all subkeys under the uninstall path (ignore errors if the key doesn’t exist)
        $keys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($key in $keys) {
            $appInfo = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            if ($appInfo.DisplayName -and $appInfo.DisplayName -like "*$AppName*") {
                Write-Output "Found: $($appInfo.DisplayName)"
                if ($appInfo.UninstallString) {
                    $uninstallCmd = $appInfo.UninstallString
                    Write-Output "Uninstall command: $uninstallCmd"
                    
                    # If the uninstall string uses msiexec, add silent flags if not already present
                    if ($uninstallCmd -match "msiexec") {
                        # Ensure the command will uninstall (/x) and run silently (/qn) if not already specified.
                        if ($uninstallCmd -match "/I") {
                            # Replace install flag with uninstall flag
                            $uninstallCmd = $uninstallCmd -replace "/I", "/x"
                        }
                        if (($uninstallCmd -notmatch "/qn") -and ($uninstallCmd -notmatch "/quiet")) {
                            $uninstallCmd = "$uninstallCmd /qn"
                        }
                    }
                    
                    try {
                        Write-Output "Executing uninstall command..."
                        # Run the command using cmd /c so that any command line switches are parsed correctly.
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $uninstallCmd -Wait -NoNewWindow
                        Write-Output "Uninstalled: $($appInfo.DisplayName)`n"
                    }
                    catch {
                        Write-Output "ERROR: Failed to uninstall $($appInfo.DisplayName): $_`n"
                    }
                    $found = $true
                }
                else {
                    Write-Output "No uninstall command found for $($appInfo.DisplayName)`n"
                }
            }
        }
    }
    
    if (-not $found) {
        Write-Output "Application matching '$AppName' was not found on this system.`n"
    }
}

# Loop through each product name and attempt uninstallation
foreach ($product in $productsToRemove) {
    Uninstall-Application -AppName $product
}

Write-Output "Uninstallation script completed."
 
