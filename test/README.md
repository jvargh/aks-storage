
## Lab setup instructions

1.  Run below commands to initialize the Setup process.

> az login
>
> az account set \--subscription \"Azure Pass - Sponsorship\"
>
> az provider register \--namespace Microsoft.Storage
>
> az provider register \--namespace Microsoft.Compute
>
> az provider register \--namespace Microsoft.Network
>
> az provider register \--namespace Microsoft.Monitor
>
> az provider register \--namespace Microsoft.ManagedIdentity
>
> az provider register \--namespace Microsoft.OperationalInsights
>
> az provider register \--namespace Microsoft.OperationsManagement
>
> az provider register \--namespace Microsoft.KeyVault
>
> az provider register \--namespace Microsoft.ContainerService
>
> az provider register \--namespace Microsoft.Kubernetes
>
> From 'portal.azure.com' \> Subscriptions \> Select your \`Azure Pass -
> Sponsorship subscription\` \> select 'Resource Providers' \> Refresh
> and confirm all providers in Registered state.
>
> Or use
>
> az provider list \--query
> \"\[?registrationState==\'Registered\'\].namespace\"

2.  Build out Resource Group and Setup Log Analytics Workspace for AKS
    > cluster

> **\# Build out Resource Groups and AKS Cluster**
>
> \$resource_group="akslabs" \# \<- don't replace. Use as-is
>
> \$aks_name="akslabs" \# \<- don't replace. Use as-is
>
> \$location="eastus" \# \<- don't replace. Use as-is
>
> \$log_analytics_workspace_name=\$aks_name+\'-log-analytics-workspace\'
>
> echo \$resource_group; echo \$aks_name; echo \$location; echo
> \$log_analytics_workspace_name
>
> az group create \--name \$resource_group \--location \$location
>
> \# Create log analytics workspace and save its Resource Id to use in
> aks create
>
> az monitor log-analytics workspace create \`
>
> \--resource-group \$resource_group \`
>
> \--workspace-name \$log_analytics_workspace_name \`
>
> \--location \$location
>
> \$log_analytics_workspace_resource_id=az monitor log-analytics
> workspace show \`
>
> \--resource-group \$resource_group \`
>
> \--workspace-name \$log_analytics_workspace_name \`
>
> \--query id \--output tsv
>
> echo \$log_analytics_workspace_resource_id

3.  Spin up an AKS cluster. Ensure below settings on cluster creation.

> ![Graphical user interface, text, application Description
> automatically
> generated](vertopal_24b317e4e245491ea3a65f4d32fc89bf/media/image4.png){width="5.358338801399825in"
> height="1.7092104111986002in"}
>
> az aks create \`
>
> \--resource-group \$resource_group \`
>
> \--name \$aks_name \`
>
> \--node-count 1 \`
>
> \--node-vm-size standard_ds2_v2 \`
>
> **\--network-plugin kubenet** \`
>
> \--pod-cidr \"10.244.0.0/16\" \`
>
> \--service-cidr \"10.0.0.0/16\" \`
>
> \--enable-managed-identity \`
>
> **\--network-policy calico** \`
>
> **\--enable-addons monitoring \`**
>
> \--generate-ssh-keys \`
>
> **\--workspace-resource-id** \$log_analytics_workspace_resource_id

4.  Setup kubectl alias

> \<bash\> alias k=\'kubectl\'
>
> \<Powershell\> set-alias -Name k -Value kubectl

5.  Setup credentials:

**az aks get-credentials -g** \$resource_group **-n** \$aks_name
**\--overwrite-existing**

6.  Switch to the newly created namespace

> **kubectl create ns student**
>
> **kubectl config set-context \--current \--namespace=student**
>
> \# Verify current namespace
>
> **kubectl config view \--minify \--output \'jsonpath={..namespace}\'**
>
> \# Confirm ability to view
>
> **kubectl get pods -A**

7.  If jq and curl isn't installed, open a Powershell as Admin, and run
    "choco install jq -y" and "choco install curl -y"

