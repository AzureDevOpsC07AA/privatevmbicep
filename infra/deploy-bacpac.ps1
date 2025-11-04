param (
    [string]$KeyvaultFQDN
)


$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Log($msg) { Write-Host "$(Get-Date -Format 'HH:mm:ss')  $msg" }

# ---------------------------------------------------------
# Step 1: Install PowerShell 7 (MSI with retry)
# ---------------------------------------------------------
$pwshExe = "C:\Program Files\PowerShell\7\pwsh.exe"
if (-not (Test-Path $pwshExe)) {
    Log "Installing PowerShell 7..."
    $pwshUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi"
    $pwshInstaller = "$env:TEMP\PowerShell-7.4.6-win-x64.msi"

    $maxAttempts = 3
    for ($i=1; $i -le $maxAttempts; $i++) {
        try {
            Log "Downloading PowerShell installer (attempt $i)..."
            Invoke-WebRequest -Uri $pwshUrl -OutFile $pwshInstaller -UseBasicParsing -TimeoutSec 300
            if (Test-Path $pwshInstaller) {
                Log "Download complete. Installing..."
                Start-Process msiexec.exe -Wait -ArgumentList "/i `"$pwshInstaller`" /quiet /norestart"
                break
            }
        } catch {
            Log "Attempt $i failed: $($_.Exception.Message)"
            Start-Sleep -Seconds (10 * $i)
        }
    }

    if (-not (Test-Path $pwshExe)) {
        Log "ERROR: PowerShell 7 installation failed after $maxAttempts attempts."
        exit 1
    } else {
        Log "PowerShell 7 installed successfully."
    }
} else {
    Log "PowerShell 7 already installed."
}

# ---------------------------------------------------------
# Step 2: Trust PSGallery
# ---------------------------------------------------------
try {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Log "PSGallery trusted."
} catch {
    Log "Warning: Failed to trust PSGallery. Continuing..."
}

# ---------------------------------------------------------
# Step 3: Install SqlServer module with retry
# ---------------------------------------------------------
$moduleName = "SqlServer"
$maxAttempts = 3
$installed = $false

for ($i=1; $i -le $maxAttempts; $i++) {
    Log "Installing module '$moduleName' (attempt $i)..."
    try {
        Install-Module $moduleName -Force -AllowClobber -Confirm:$false -ErrorAction Stop
        $installed = $true
        break
    } catch {
        Log "Attempt $i failed: $($_.Exception.Message)"
        Start-Sleep -Seconds (15 * $i)
    }
}

if (-not $installed) {
    Log "ERROR: Failed to install module '$moduleName' after $maxAttempts attempts."
    exit 1
}

Log "All installations completed successfully."





# Build the script content
$lines = @()
$lines += '$KeyvaultFQDN1 = "' + $KeyvaultFQDN + '"'
$lines += '$SecretName = "AdventureWorksLT-ConnectionString"'
$lines += ''
$lines += '# Normalize FQDN (remove https:// and trailing slash)'
$lines += '$KeyvaultFQDN1 = $KeyvaultFQDN1 -replace "^https://|/$", ""'
$lines += ''
$lines += '# Get access token for Key Vault'
$lines += '$KeyVaultToken = (Invoke-RestMethod -Headers @{Metadata="true"} `'
$lines += '    -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" `'
$lines += '    -Method GET).access_token'
$lines += ''
$lines += '# Retrieve the connection string secret'
$lines += '$connectionStringSecret = Invoke-RestMethod -Uri "https://$KeyvaultFQDN1/secrets/$SecretName/?api-version=2016-10-01" `'
$lines += '    -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}'
$lines += ''
$lines += '# Clean the connection string (remove any ''Authentication='' part just in case)'
$lines += '$connectionString = ($connectionStringSecret.value -replace "Authentication=[^;]+;", "").Trim()'
$lines += ''
$lines += '# Get an access token for Azure SQL using Managed Identity'
$lines += '$sqlToken = (Invoke-RestMethod -Headers @{Metadata="true"} `'
$lines += '    -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://database.windows.net/" `'
$lines += '    -Method GET).access_token'
$lines += ''
$lines += '# Load SQL query'
$lines += '$sqlFile = "C:\scripts\workloadsim.sql"'
$lines += 'if (-not (Test-Path $sqlFile)) {'
$lines += '    Write-Error "SQL file not found: $sqlFile"'
$lines += '    exit 1'
$lines += '}'
$lines += '$query = Get-Content $sqlFile -Raw'
$lines += 'if ([string]::IsNullOrWhiteSpace($query)) {'
$lines += '    Write-Error "SQL file is empty or contains only whitespace: $sqlFile"'
$lines += '    exit 1'
$lines += '}'
$lines += 'Write-Host "Loaded SQL query from $sqlFile (Length: $($query.Length) characters)"'
$lines += ''
$lines += '# Execute continuously'
$lines += '$i = 0'
$lines += 'while ($true) {'
$lines += '    try {'
$lines += '        Invoke-Sqlcmd -ConnectionString $connectionString -AccessToken $sqlToken -Query $query | Out-Null'
$lines += '        Write-Host "Executed iteration $i"'
$lines += '        $i++'
$lines += '    } catch {'
$lines += '        Write-Error "Error executing SQL query: $_"'
$lines += '        Start-Sleep -Seconds 5'
$lines += '    }'
$lines += '}'

# Write to the file
Set-Content -Path $targetFile -Value $lines

# Create shortcut
$targetFile = "C:\scripts\workloadSim.ps1"
$targetFolder = Split-Path $targetFile
# Path for the shortcut on all user desktops
$shortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonDesktopDirectory"), "WorkloadSim.lnk")
# Create the shortcut
$WshShell = New-Object -ComObject WScript.Shell     
$shortcut = $WshShell.CreateShortcut($shortcutPath)
# Set the target to PowerShell executable
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
# Set arguments to run the script
$shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$targetFile`""
# Optional: set working directory (if needed)
$shortcut.WorkingDirectory = $targetFolder
# Optional: set a custom icon (otherwise leave this out)
$shortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
# Save the shortcut
$shortcut.Save()



# === Worloadsim as service CONFIGURATION ===
$serviceName = "WorkloadSimService"
$serviceDisplayName = "Workload Simulator"
$scriptPath = "C:\scripts\workloadsim.ps1"
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$installPath = "C:\nssm"
$downloadPath = "$env:TEMP\nssm.zip"
$extractPath = "$env:TEMP\nssm"


