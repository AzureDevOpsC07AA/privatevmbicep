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

