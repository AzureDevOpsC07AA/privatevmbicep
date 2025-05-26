az login --identity | Out-Null

$resourceGroup = "rg-sqlworkload"
$sqlServerName = "sqlserver-sqlworkload"
$firewallRuleName = "AllowMyVM"

# Get the public IP of the VM from inside the VM
$publicIp = (Invoke-RestMethod -Uri "http://whatismyip.akamai.com/")
Write-Output "Detected public IP: $publicIp"

# Add firewall rule to SQL Server
az sql server firewall-rule create `
  --resource-group $resourceGroup `
  --server $sqlServerName `
  --name $firewallRuleName `
  --start-ip-address $publicIp `
  --end-ip-address $publicIp


$bacpacUrl = "https://github.com/koenraadhaedens/azd-sqlworloadsim/raw/e94d861ed5d780408fa7cdc44d80bc4590b9ae17/media/adventureworks2017.bacpac"
$targetSqlServer = "sqlserver-dpdemo3.database.windows.net"
$targetDatabase = "avendtureworks2017"
$sqlAdminUser = "sqladminuser"
$sqlAdminPassword = 
$msiUrl = "https://go.microsoft.com/fwlink/?linkid=2316310"
$msiPath = "$env:TEMP\SqlPackageInstaller.msi"
$bacpacPath = "$env:TEMP\adventureworks2017.bacpac"
# --- Variables ---
$msiUrl = "https://go.microsoft.com/fwlink/?linkid=2316310"
$msiPath = "$env:TEMP\SqlPackageInstaller.msi"



Write-Host "Downloading .bacpac file..."
Invoke-WebRequest -Uri $bacpacUrl -OutFile $bacpacPath

# --- Step 1: Download the MSI ---
Write-Host "Downloading SqlPackage installer..."
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

# --- Step 2: Install the MSI silently ---
Write-Host "Installing SqlPackage..."
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait

# --- Step 3: Locate SqlPackage.exe dynamically ---
Write-Host "Searching for SqlPackage.exe..."
$sqlPackageExe = Get-ChildItem -Path "C:\" -Recurse -Filter "SqlPackage.exe" -ErrorAction SilentlyContinue -Force |
                 Where-Object { $_.FullName -like "*sqlpackage*" } |
                 Select-Object -First 1 -ExpandProperty FullName

if (-not $sqlPackageExe) {
    throw "SqlPackage.exe not found anywhere on disk."
}

# --- Step 4: Run SqlPackage to import BACPAC ---
Write-Host "Importing .bacpac to SQL Server using: $sqlPackageExe"
& "$sqlPackageExe" /a:Import /sf:"$bacpacPath" /tsn:"$targetSqlServer" /tdn:"$targetDatabase" /p:DatabaseEdition=Standard /p:DatabaseServiceObjective=S0

Write-Host "✅ Database import complete."
