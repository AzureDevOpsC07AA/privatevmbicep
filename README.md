
# Azure SQL Workload Simulator Demo

This project sets up an Azure environment with a SQL workload simulator using Azure Developer CLI (azd).

## Prerequisites

Before you begin, make sure you have:

- An active Azure subscription
- Access to [Azure Cloud Shell](https://shell.azure.com)
- `azd` (Azure Developer CLI) installed (comes pre-installed in Cloud Shell)

## Deployment Steps

1. **Open Azure Cloud Shell**

   Go to [https://shell.azure.com](https://shell.azure.com) and choose either **Bash** or **PowerShell**.

2. **Clone the Repository**

   Run the following command in Cloud Shell:

   ```bash
   git clone https://github.com/koenraadhaedens/azd-sqlworloadsim
   ```

3. **Navigate to the Project Folder**

   ```bash
   cd azd-sqlworloadsim
   ```

4. **Deploy the Infrastructure**

   ```bash
   azd up
   ```

   Follow the prompts:

   - **Environment Name**  
     This will be used as both the environment name and the name of the Resource Group.

   - **Location**  
     Select your preferred Azure region (e.g., `westeurope`, `eastus`).

   - **Admin Password**  
     This password will be used for both:
     - The Azure Virtual Machine (VM) administrator account
     - The Azure SQL Server administrator account

## What’s Deployed

- Azure Virtual Machine (Windows)  
  → Pre-configured to simulate SQL workloads.

- Azure SQL Server + Database  
  → Connected to the workload simulation.

- Resource Group named after your chosen environment.

## Access Information

Once deployment is complete, the outputs will display:

- VM public IP address and credentials
- SQL Server connection details

Make sure to store these safely for connecting and testing.

## Cleanup

To avoid unexpected charges, remove the deployed resources when done:

```bash
azd down
```

## Questions or Issues?

Feel free to raise an issue in this repository or reach out to the project owner.
