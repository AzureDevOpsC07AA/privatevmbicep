
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

## Start Workload

Once deployment is complete:

1. **Enable RDP Access**

   - **Recommended**: Use **Azure Just-in-Time (JIT)** access to open RDP securely on port 3389.  
     Go to the VM in the Azure Portal → **Microsoft Defender for Cloud** → **Just-in-Time VM access** → request RDP access.
   
   - **Alternatively**: Manually create an **Inbound Security Rule** in the Network Security Group (NSG) attached to the VM:
     - Allow **RDP (TCP port 3389)** from your public IP.
     - Set a limited time window to reduce exposure.

2. **Connect to the Virtual Machine**

   - Use Remote Desktop (RDP) to connect to the VM using:
     - The public IP address from the deployment outputs.
     - The admin username and password you provided during deployment.

3. **Start the Workload Simulation**

   - Once logged in to the VM, locate the **desktop shortcut** for the workload simulator.
   - Double-click the shortcut to start the workload.

4. **Monitor Performance**

   - Use the **Azure Portal** → SQL Database → Metrics, or monitoring tools inside the VM, to observe workload behavior.

 For Azure SQL Database, the Performance Recommendations feature (sometimes called SQL Database Advisor) generally starts providing recommendations after it has collected at least a few days of workload telemetry — typically 24–72 hours of continuous activity.

5. **Demo Performance Recommendations

For Azure SQL Database, the Performance Recommendations feature (sometimes called SQL Database Advisor) generally starts providing recommendations after it has collected at least a few days of workload telemetry — typically 24–72 hours of continuous activity.

✅ Initial recommendations: You might see something as soon as 24 hours if the workload is steady and significant.
✅ More accurate & refined recommendations: Expect around 5–7 days of regular usage to get meaningful index tuning and query improvement suggestions.
✅ No workload = no recommendations: If the database has no or very low activity, the advisor has nothing to analyze, so it won’t recommend anything.  



## Cleanup

To avoid unexpected charges, remove the deployed resources when done:

```bash
azd down
```

## Questions or Issues?

Feel free to raise an issue in this repository or reach out to the project owner.
