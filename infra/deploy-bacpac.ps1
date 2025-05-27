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
$lines += '$Response = Invoke-RestMethod -Uri ''http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net'' -Method GET -Headers @{Metadata="true"}'
$lines += '$KeyVaultToken = $Response.access_token'
$lines += '$connectionString = Invoke-RestMethod -Uri https://$KeyvaultFQDN1/secrets/$SecretName/?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}'
$lines += ''
$lines += '$sqlFile = "C:\scripts\workloadsim.sql"'
$lines += '$query = Get-Content $sqlFile -Raw'
$lines += ''
$lines += 'for ($i = 0; $i -lt 1000; $i++) {'
$lines += '    Invoke-Sqlcmd -ConnectionString $connectionString -Query $query'
$lines += '    Write-Host "Executed iteration $i"'
$lines += '}'

# Write to the file
Set-Content -Path $targetFile -Value $lines

//create shortcut for this script on all user desktops
$shortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonDesktopDirectory"), "WorkloadSim.ps1.lnk")
$WshShell = New-Object -ComObject WScript.Shell     
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetFile
$shortcut.WorkingDirectory = $targetFolder
$shortcut.IconLocation = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetFile`""
$shortcut.Save()    



