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

## Explore the configured sample

Once the sample script has completed, run the following command to see what pods are running:

```powershell
kubectl get pods -w
```

You should see the frontend pod, but the backend pod should not be visible, and this is because it has scaled to zero using KEDA. We'll see this pod momentarily. The `-w` flag in the command we ran means that the view will update as new pods become available.

Navigate to the [Azure portal](https://portal.azure.com), and find the resource group based on the name you provided earlier. You should see all three of the resouces mentioned earlier.

To trigger the frontend, let us find out the external IP with
```powershell
kubectl get service nginx-ingress-controller
```

Before we will send a request to the endpoint, open `deploy/ingress.yaml` to see that all requests are routed to the NGINX Ingress Dapr sidecar which then uses service invocation to invoke methods on the frontend microservice.

The NGINX Ingress pod was Dapr enabled with the same annotation you use for your applications - you can find it in the `setup.ps1`.

Issue the following request:
```
GET http://EXTERNAL_IP:80/dosomething
```

If you head back to the terminal where you are running the `kubectl get pods -w` command, you should see a new pod enter the `ContainerCreating` state. This is the backend app, being scaled out because KEDA saw a message sitting in the queue from Azure Service Bus. Note that there are two containers created - one of them is the Dapr sidecar!

Opening `deploy/backend-scaler.yaml` to see how KEDA was configured for scaling the backend deployment.