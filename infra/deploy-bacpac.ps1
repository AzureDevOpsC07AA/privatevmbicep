'''
param(
    [string]$BacpacUrl,
    [string]$TargetSqlServer,
    [string]$TargetDatabase,
    [string]$SqlAdmin,
    [string]$SqlPassword
)

$msiUrl = "https://go.microsoft.com/fwlink/?linkid=2316310"
$msiPath = "$env:TEMP\\SqlPackageInstaller.msi"
$bacpacPath = "$env:TEMP\\adventureworks2017.bacpac"

Write-Host "Downloading .bacpac file from $BacpacUrl..."
Invoke-WebRequest -Uri $BacpacUrl -OutFile $bacpacPath

Write-Host "Downloading SqlPackage installer..."
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

Write-Host "Installing SqlPackage..."
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait

Write-Host "Searching for SqlPackage.exe..."
$sqlPackageExe = Get-ChildItem -Path "C:\\" -Recurse -Filter "SqlPackage.exe" -ErrorAction SilentlyContinue -Force |
                 Where-Object { $_.FullName -like "*sqlpackage*" } |
                 Select-Object -First 1 -ExpandProperty FullName

if (-not $sqlPackageExe) {
    throw "SqlPackage.exe not found anywhere on disk."
}

Write-Host "Importing .bacpac to SQL Server: $TargetSqlServer, Database: $TargetDatabase"
& "$sqlPackageExe" /a:Import /sf:"$bacpacPath" /tsn:"$TargetSqlServer" /tdn:"$TargetDatabase" /tu:"$SqlAdmin" /tp:"$SqlPassword" /p:DatabaseEdition=Standard /p:DatabaseServiceObjective=S0

Write-Host "✅ Database import complete."
'''

param(
    [string]$BacpacUrl,
    [string]$TargetSqlServer,
    [string]$TargetDatabase,
    [string]$SqlAdmin,
    [string]$SqlPassword
)

# Ensure script folder exists
$scriptFolder = "C:\scripts"
if (-not (Test-Path $scriptFolder)) {
    New-Item -Path $scriptFolder -ItemType Directory
}

# Download the SQL script from GitHub
$sqlFileUrl = "https://raw.githubusercontent.com/koenraadhaedens/azd-sqlworloadsim/refs/heads/main/sqlscript/workloadsim.sql"
$sqlFilePath = Join-Path $scriptFolder "workloadsim.sql"

Invoke-WebRequest -Uri $sqlFileUrl -OutFile $sqlFilePath

Write-Host "Downloaded SQL script to $sqlFilePath"


# Build the connection string (inject real values, wrap password in single quotes)

$connectionStringValue = "Server=tcp:$TargetSqlServer,1433;Database=$TargetDatabase;User ID=$SqlAdmin;Password='$SqlPassword';Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"


$scriptContent = @"
param(
    [string]\$ConnectionString,
    [string]\$SqlFile
)

\$query = Get-Content \$SqlFile -Raw

for (\$i = 0; \$i -lt 1000; \$i++) {
    Invoke-Sqlcmd -ConnectionString \$ConnectionString -Query \$query
    Write-Host "Executed iteration \$i"
}
"@

# Write the script to file
$runScriptPath = Join-Path $scriptFolder "run-workload.ps1"
$scriptContent | Out-File -FilePath $runScriptPath -Encoding UTF8

Write-Host "Script generated at $runScriptPath"

# Create shortcut on desktop for all users
$WScriptShell = New-Object -ComObject WScript.Shell
$desktopPath = "$Env:Public\Desktop"
$shortcutPath = Join-Path $desktopPath "Run Workload Simulation.lnk"

$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$runScriptPath`""
$shortcut.WorkingDirectory = $scriptFolder
$shortcut.WindowStyle = 1
$shortcut.IconLocation = "powershell.exe"
$shortcut.Save()

Write-Host "Shortcut created at $shortcutPath"

