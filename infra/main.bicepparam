using 'main.bicep'


param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')

param winVMPassword = readEnvironmentVariable('WIN_VM_PASSWORD')
