# Change these four parameters as needed
$AKS_RG="aksrgnp"
$AKS_NAME="aksnp"
$STORAGE_ACCOUNT_NAME="storagefsxxyyzz"
$LOCATION="eastus"
$SHARE_NAME="share01"

#################################################
# 1. Create Storage account and File share
#################################################

# Create the storage account with the parameters
az storage account create `
    --resource-group $AKS_RG `
    --name $STORAGE_ACCOUNT_NAME `
    --location $LOCATION `
    --sku Premium_LRS --kind StorageV2 --access-tier Hot

# Create the file share
az storage share-rm create --enabled-protocols SMB -n $SHARE_NAME --storage-account $STORAGE_ACCOUNT_NAME

# Set "Allow storage account key access" and "Secure transfer required" to enabled for the Azure storage account
az storage account update --name $STORAGE_ACCOUNT_NAME --resource-group $AKS_RG  --allow-shared-key-access true --https-only true

########################################################################
# 2. Set RBAC on AKS default MI. Set Storage account permissions
########################################################################

# Asign Role to AKS default managed id i.e. grant kubelet identity permission on Storage account hosting file share
$IDENTITY_CLIENT_ID=az aks show -g $AKS_RG -n $AKS_NAME --query "identityProfile.kubeletidentity.objectId" -o tsv
$STORAGE_ACCOUNT_ID=$(az storage account show -n $STORAGE_ACCOUNT_NAME --query id)

az role assignment create --assignee $IDENTITY_CLIENT_ID `
        --role "Storage Account Contributor" `
        --scope $STORAGE_ACCOUNT_ID
az role assignment list --all --assignee $IDENTITY_CLIENT_ID    # confirm role assignment

################################################################
# 3. Generate files for Storage Class, PV, PVC and App Pods
################################################################

############
#   SMB    #
############

# Generate SMB SC and PV files from CLI
run _sc-temp.yaml AND _pv-temp.yaml 

# Generate NFS SC and PV files from CLI
run _sc-temp-nfs.yaml AND _pv-temp.yaml 

# SMB - Deploy storage class
kubectl apply -f sc-azurefile-csi.yaml
kubectl describe sc azurefile-csi-jv

# SMB - Deploy PV and PVC and confirm if PVC is bound
kubectl apply -f pv-azurefile-csi.yaml -f pvc-azurefile-csi.yaml
clear; kubectl get sc,pvc,pv 
kubectl describe pvc/pvc-azurefile-jv; kubectl describe pv/pv-azurefile-jv

# SMB - Deploy App
kubectl apply -f pod-azurefile-csi.yaml
clear; kubectl get pods,pvc,pv; 
kubectl describe pod/az-files-pod

# Verify the File share mounted successfully
$POD_NAME=$(kubectl get pods -l app=azfile-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- df -h
kubectl exec -it $POD_NAME -- 'echo "hello" > /mnt/azure/hello.txt'

kubectl delete pod/az-files-pod persistentvolume/pv-azurefile-jv persistentvolumeclaim/pvc-azurefile-jv storageclass.storage.k8s.io/azurefile-csi-jv --force

# SMB - DELETE
kubectl delete pod/az-files-pod --force
kubectl delete pod/az-files-pod pv/pv-azurefile-jv pvc/pvc-azurefile-jv sc/azurefile-csi-jv --force
clear; kubectl get sc,pods,svc,pvc,pv 

kubectl delete -f pod-azurefile-csi.yaml # delete app
kubectl delete -f pvc-azurefile-csi.yaml -f pv-azurefile-csi.yaml # delete pv, pvc
kubectl delete -f  sc-azurefile-csi.yaml # delete sc
clear; kubectl get sc,pods,svc,pvc,pv 


# ERRORS
# SMB HTTPStatusCode: 403 > object id does not have authorization to perform action 'Microsoft.Storage/storageAccounts/listKeys/action' over scope <STORAGE_ACCOUNT>
# had to give MI the Contributor role on storage account. Delete sc,pv,pvc. Recreate SC, PV, PVC


