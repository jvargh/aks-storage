# aks-storage

The folders contain AKS provisioning files for different protocols, as described below.

Contains code pertinent to MSFT article: [Field tips for AKS storage provisioning](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/field-tips-for-aks-storage-provisioning/ba-p/3761105
).


## blob-fuse
The **blob-fuse folder** contains AKS provisioning files for using the **BlobFuse** protocol to mount Azure Blob Storage as a file system in an AKS cluster. BlobFuse allows you to access your data in Blob Storage using standard file system APIs, which can be useful if your applications expect to read or write files from a file system.

## files-nfs
The **files-nfs** folder contains AKS provisioning files for using the **NFS** protocol to mount Azure Files as a file system in an AKS cluster. Azure Files is a managed file share service in Azure that allows you to create file shares that can be accessed from multiple machines. NFS is a standard protocol for accessing file systems over a network.

## files-smb
The **files-smb** folder contains AKS provisioning files for using the **SMB** protocol to mount Azure Files as a file system in an AKS cluster. SMB is another standard protocol for accessing file systems over a network, and it is commonly used in Windows and Linux OS environments.
