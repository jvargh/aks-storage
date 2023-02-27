# Change these four parameters as needed
$AKS_RG="aksrgnp"
$AKS_NAME="aksnp"
$STORAGE_ACCOUNT_NAME="storageblobxxyyzz"
$CONTAINER_NAME="container01"
$IDENTITY_NAME="identity-storage-account"

# 1. Create Storage Account with type BlockBlobStorage
az storage account create -n $STORAGE_ACCOUNT_NAME -g $AKS_RG -l eastus --sku Premium_ZRS --kind BlockBlobStorage
az storage container create --account-name $STORAGE_ACCOUNT_NAME -n $CONTAINER_NAME

# Assign admin role to self
$CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
$STORAGE_ACCOUNT_ID=$(az storage account show -n $STORAGE_ACCOUNT_NAME --query id)

az role assignment create --assignee $CURRENT_USER_ID `
        --role "Storage Account Contributor" `
        --scope $STORAGE_ACCOUNT_ID

# 2. Create Managed Identity
az identity create -g $AKS_RG -n $IDENTITY_NAME

# 3. Assign RBAC role
$IDENTITY_CLIENT_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "clientId" -o tsv)
$STORAGE_ACCOUNT_ID=$(az storage account show -n $STORAGE_ACCOUNT_NAME --query id)

az role assignment create --assignee $IDENTITY_CLIENT_ID `
        --role "Storage Blob Data Owner" `
        --scope $STORAGE_ACCOUNT_ID

# 4. Attach Managed Identity to AKS VMSS (Nodepool(s) running CSI driver)        
$IDENTITY_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "id" -o tsv)
$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
#
$VMSS_NAME_0=$(az vmss list -g $NODE_RG --query [0].name -o tsv)
az vmss identity assign -g $NODE_RG -n $VMSS_NAME_0 --identities $IDENTITY_ID
$VMSS_NAME_1=$(az vmss list -g $NODE_RG --query [1].name -o tsv)
az vmss identity assign -g $NODE_RG -n $VMSS_NAME_1 --identities $IDENTITY_ID

# 5. Configure Persistent Volume (PV) with managed identity
Run pv.yaml contents on cli which creates pv-blobfuse.yaml

# 6. Deploy the application
kubectl apply -f pv-blobfuse.yaml -f pvc-blobfuse.yaml -f nginx-pod-blob.yaml
clear; kubectl get pods,svc,pvc,pv

# 7. Verify the Blob storage mounted successfully
$POD_NAME=$(kubectl get pods -l app=nginx-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- df -h
kubectl exec -it $POD_NAME -- echo 'Hello' > /mnt/azure/hello.txt
