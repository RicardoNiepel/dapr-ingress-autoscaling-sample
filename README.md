# Dapr Sample for Ingress and Autoscaling in Kubernetes
Dapr sample of using NGINX for Ingress and KEDA for Autoscaling and Azure Kubernetes Services as deployment target.

## Run the sample

### Prerequisites

Setting up this sample requires you to have several components installed:

- [Install the Dapr CLI](https://github.com/dapr/cli)
- [Install Docker](https://docs.docker.com/install/)
- [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Install Helm](https://github.com/helm/helm)
- [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Install PowerShell Core 6](https://github.com/PowerShell/PowerShell)
- [Install the Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local#v2)

### Clone the sample repository
Clone this sample repository to your local machine:
```bash
git clone https://github.com/RicardoNiepel/dapr-ingress-autoscaling-sample.git
```

### Run the setup script

Before running this script, note that this will provision the following resources into your Azure subscription and will incur associated costs:

- An Azure Kubernetes Service
- An Azure Container Registry
- An Azure Service Bus

To run the script, first log into the Azure CLI:

```powershell
az login
```

Run this script:

```powershell
./setup.ps1
```

You will be prompted for a name that determines the resource group where things will be deployed. It also serves as a base name for the resources themselves. Note that storage accounts can only accept lowercase alphanumeric characters and must start with an alpha character. Please set the base name accordingly.

You will also be prompted for the azure region in which to deploy these resources. For example: "west europe"

This will create an entirely new cluster and configure it with this sample.