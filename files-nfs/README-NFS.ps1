# Change these four parameters as needed
$AKS_RG="aksrgnp"
$STORAGE_ACCOUNT_NAME="storagefsxxyyzz"
$LOCATION="eastus"
$SHARE_NAME_NFS="share02"

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
az storage share-rm create --enabled-protocols NFS -n $SHARE_NAME_NFS --storage-account $STORAGE_ACCOUNT_NAME

# Set "Allow storage account key access" and "Secure transfer required" to enabled for an Azure storage account
az storage account update --name $STORAGE_ACCOUNT_NAME --resource-group $AKS_RG  --allow-shared-key-access false --https-only false

################################################################
# 2. Generate files for Storage Class, PV, PVC and App Pods
################################################################

############
#   NFS    #
############

# NFS - Deploy storage class
kubectl apply -f sc-azurefile-csi-nfs.yaml
kubectl describe sc/azurefile-csi-nfs-jv

# NFS - Deploy PV and PVC and confirm if PVC is bound
kubectl apply -f pv-azurefile-csi-nfs.yaml -f pvc-azurefile-csi-nfs.yaml
clear; kubectl get sc,pvc,pv 
kubectl describe pvc/pvc-azurefile-nfs-jv; 
kubectl describe pv/pv-azurefile-nfs-jv

# NFS - Deploy App
kubectl apply -f pod-azurefile-csi-nfs.yaml
clear; kubectl get pods,pvc,pv; 
kubectl describe pod/az-files-nfs-pod

# DELETE
kubectl delete pod/az-files-nfs-pod --force
kubectl delete pod/az-files-nfs-pod persistentvolume/pv-azurefile-nfs-jv persistentvolumeclaim/pvc-azurefile-nfs-jv `
 storageclass.storage.k8s.io/azurefile-csi-nfs-jv --force
k get pod,pv,pvc,sc


# ERRORS
# NFS  failed with mount failed: exit status 32. When Secure transfer required = Enabled. Should be disabled

