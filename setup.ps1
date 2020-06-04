$setupFolder = "./utils/base-templates"
$deployFolder = "./deploy"
$frontendName = "frontend"
$backendName = "backend"
$sourceFolder = "./src"
$tag = "edge"

$frontendFolder = "$sourceFolder/$frontendName"
$backendFolder = "$sourceFolder/$backendName"


# Prompts
$resourceBase = Read-Host -Prompt "Enter resource name base"
$location = Read-Host -Prompt "Enter location"

$groupName= "$resourceBase-rg"
$clusterName= "$resourceBase" + "-cluster"
$registryName="${resourceBase}reg"
$sbNamespaceName = "${resourceBase}sb"

#### Azure resources and AKS preparation
##################################################################################################

# Resource Group
Write-Host
Write-Host "Creating resource group $groupName..."
az group create -n $groupName -l $location


# ACR
Write-Host
Write-Host "Creating ACR registry $registryName..."
az acr create --resource-group $groupName --name $registryName --sku Basic

# AKS
Write-Host
Write-Host "Creating AKS cluster $clusterName..."
az aks create -g $groupName -n $clusterName --generate-ssh-keys --attach-acr $registryName

# Login to ACR and AKS
az acr login -n $registryName
az aks get-credentials -n $clusterName -g $groupName


# Azure Service Bus
#################################################
Write-Host
Write-Host "Creating Azure Service Bus $sbNamespaceName..."
az servicebus namespace create -n $sbNamespaceName -g $groupName -l $location
az servicebus topic create --name A --namespace-name $sbNamespaceName -g $groupName 

$sbConnectionString = $(az servicebus namespace authorization-rule keys list -g $groupName --namespace-name $sbNamespaceName -n RootManageSharedAccessKey --query primaryConnectionString --output tsv)
(Get-Content $setupFolder/azure-service-bus-base.yaml) | Foreach-Object {$_ -replace "REPLACE_CONNECTION_STRING", $sbConnectionString} | Set-Content $deployFolder/azure-service-bus.yaml

az servicebus topic authorization-rule create -g $groupName --namespace-name $sbNamespaceName --topic-name A --name TopicPrimaryConnectionString --rights Manage Send Listen
$sbTopicConnectionStringRaw = $(az servicebus topic authorization-rule keys list -g $groupName --namespace-name $sbNamespaceName --topic-name A --name TopicPrimaryConnectionString --query primaryConnectionString --output tsv)
$sbTopicConnectionString = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sbTopicConnectionStringRaw))


# Install Dapr
#################################################
Write-Host
Write-Host "Installing Dapr on $clusterName..."
dapr init --kubernetes

Write-Host
Write-Host "Installing Redis as the Dapr state store on $clusterName..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install redis bitnami/redis --set rbac.create=true
Start-Sleep -Seconds 60

$redisHost= $(kubectl get service redis-master -o=custom-columns=IP:.spec.clusterIP --no-headers=true) + ":6379"

$encoded = kubectl get secret --namespace default redis -o jsonpath="{.data.redis-password}"
$redisSecret = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($encoded))

(Get-Content $setupFolder/redis-base.yaml) | Foreach-Object {$_ -replace "REPLACE_HOST", $redisHost} | Foreach-Object {$_ -replace "REPLACE_SECRET", $redisSecret} | Set-Content $deployFolder/redis.yaml

# Install NGINX
#################################################
Write-Host
Write-Host "Installing NGINX on $clusterName..."

#Using Helm 3.0 to install NGINX
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
kubectl create namespace ingress-basic
helm install nginx-ingress stable/nginx-ingress --set controller.replicaCount=2 --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux --set controller.podAnnotations."dapr\.io/enabled"=true --set controller.podAnnotations."dapr\.io/id"="nginx-ingress" --set controller.podAnnotations."dapr\.io/port"=80

# Install KEDA
#################################################
Write-Host
Write-Host "Installing KEDA on $clusterName..."

#Using Helm 3.0 to install Keda
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm install keda kedacore/keda --namespace keda


#### Application section
##################################################################################################

# Build images and deployment templates
Write-Host
Write-Host "Building and publishing images..."

(Get-Content $setupFolder/frontend-base.yaml) `
| Foreach-Object {$_ -replace "IMAGE_NAME", "$registryName.azurecr.io/${frontendName}:$tag"}  `
| Set-Content $deployFolder/frontend.yaml

docker build -t "$registryName.azurecr.io/${frontendName}:$tag" $frontendFolder  
docker push "$registryName.azurecr.io/${frontendName}:$tag"

(Get-Content $setupFolder/backend-base.yaml) `
| Foreach-Object {$_ -replace "IMAGE_NAME", "$registryName.azurecr.io/${backendName}:$tag"}  `
| Foreach-Object {$_ -replace "REPLACE_SB_CONNECTION_STRING", $sbTopicConnectionString} `
| Set-Content $deployFolder/backend.yaml

docker build -t "$registryName.azurecr.io/${backendName}:$tag" $backendFolder  
docker push "$registryName.azurecr.io/${backendName}:$tag"

# Deploy
Write-Host
Write-Host "Deploying application..."
kubectl apply -f $deployFolder