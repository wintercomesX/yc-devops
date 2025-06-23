# Navigate to repository root
cd yc-devops/

# 1. Get Registry ID from your infrastructure
REGISTRY_ID=$(cd infrastructure && terraform output -raw container_registry_id)
echo "Registry ID: $REGISTRY_ID"

# 2. Get Cloud and Folder IDs
CLOUD_ID=$(yc config get cloud-id)
FOLDER_ID=$(yc config get folder-id)
echo "Cloud ID: $CLOUD_ID"
echo "Folder ID: $FOLDER_ID"

# 3. Get Service Account Key (from infrastructure directory)
echo "Service Account Key:"
cat infrastructure/key.json

# 4. Get Kubernetes cluster information from your existing kubeconfig
CLUSTER_ENDPOINT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA_B64=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
SA_TOKEN=$(kubectl get secret github-actions-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)

echo "Cluster Endpoint: $CLUSTER_ENDPOINT"
echo "CA Certificate (base64): $CLUSTER_CA_B64"
echo "Service Account Token: $SA_TOKEN"
