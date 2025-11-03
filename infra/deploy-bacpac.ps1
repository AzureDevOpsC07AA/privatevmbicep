param (
    [string]$KeyvaultFQDN
)


# Ensure the target directory exists
$targetFolder = "C:\scripts"
if (-not (Test-Path $targetFolder)) {
    New-Item -Path $targetFolder -ItemType Directory | Out-Null
}

// download sql script from github
$scriptUrl = "https://raw.githubusercontent.com/koenraadhaedens/azd-sqlworloadsim/refs/heads/main/sqlscript/workloadsim.sql"
$scriptPath = Join-Path $targetFolder "workloadsim.sql"
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath  


$targetFile = Join-Path $targetFolder "workloadsim.ps1"

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
$lines += '$query = Get-Content $sqlFile -Raw'
$lines += ''
$lines += '# Execute continuously'
$lines += '$i = 0'
$lines += 'while ($true) {'
$lines += '    Invoke-Sqlcmd -ConnectionString $connectionString -AccessToken $sqlToken -Query $query | Out-Null'
$lines += '    Write-Host "Executed iteration $i"'
$lines += '    $i++'
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


