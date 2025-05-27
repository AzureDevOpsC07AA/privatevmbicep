param (
    [string]$KeyvaultFQDN
)

# Ensure the target directory exists
$targetFolder = "C:\scripts"
if (-not (Test-Path $targetFolder)) {
    New-Item -Path $targetFolder -ItemType Directory | Out-Null
}

$targetFile = Join-Path $targetFolder "get-keyvault-secret.ps1"

# Build the script content
$lines = @()
$lines += '$KeyvaultFQDN1 = "' + $KeyvaultFQDN + '"'
$lines += '$SecretName = "AdventureWorksLT-ConnectionString"'
$lines += ''
$lines += '$Response = Invoke-RestMethod -Uri ''http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net'' -Method GET -Headers @{Metadata="true"}'
$lines += '$KeyVaultToken = $Response.access_token'
$lines += '$uri = Invoke-RestMethod -Uri https://$KeyvaultFQDN1/secrets/$SecretName/?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}'

# Write to the file
Set-Content -Path $targetFile -Value $lines

Write-Host "File '$targetFile' has been created with the script content."
