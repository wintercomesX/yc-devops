#!/bin/bash

echo "=== Fixing Kubernetes Secrets for GitHub Actions ==="
echo ""

# Step 1: Get your Yandex Cloud Kubernetes cluster information
echo "1. Getting Yandex Cloud Kubernetes cluster information..."

# List all clusters to find yours
echo "Available Kubernetes clusters:"
yc managed-kubernetes cluster list

echo ""
echo "Please copy your cluster ID from above and run:"
echo "export CLUSTER_ID=your-cluster-id-here"
echo ""
read -p "Enter your cluster ID: " CLUSTER_ID

if [ -z "$CLUSTER_ID" ]; then
    echo "❌ Cluster ID is required!"
    exit 1
fi

echo ""
echo "2. Getting cluster external endpoint and CA certificate..."

# Get cluster details including external endpoint
CLUSTER_INFO=$(yc managed-kubernetes cluster get $CLUSTER_ID --format json)

# Extract external endpoint (not internal!)
# Try different possible JSON paths for the external endpoint
EXTERNAL_ENDPOINT=$(echo "$CLUSTER_INFO" | jq -r '.master.external_v4_endpoint // .master.external_v6_endpoint // .master.endpoints.external_v4_endpoint // .master.endpoints.external_v6_endpoint // empty')

# If still empty, try a more generic approach
if [ -z "$EXTERNAL_ENDPOINT" ] || [ "$EXTERNAL_ENDPOINT" = "null" ]; then
    echo "Trying alternative method to get external endpoint..."
    # Get it directly from the cluster list command since we can see it there
    EXTERNAL_ENDPOINT=$(yc managed-kubernetes cluster list --format json | jq -r --arg id "$CLUSTER_ID" '.[] | select(.id == $id) | .master.external_endpoint // empty')
fi

if [ -z "$EXTERNAL_ENDPOINT" ] || [ "$EXTERNAL_ENDPOINT" = "null" ]; then
    echo "❌ No external endpoint found for cluster!"
    echo "Debug: Full cluster info:"
    echo "$CLUSTER_INFO" | jq '.master'
    echo ""
    echo "Your cluster might not have external access enabled."
    echo "To enable external access, run:"
    echo "yc managed-kubernetes cluster update $CLUSTER_ID --enable-master-external-endpoint"
    exit 1
fi

echo "✅ External endpoint found: $EXTERNAL_ENDPOINT"

# Get cluster CA certificate - FIXED: Handle PEM format properly
CA_CERT_RAW=$(echo "$CLUSTER_INFO" | jq -r '.master.master_auth.cluster_ca_certificate')

if [ -z "$CA_CERT_RAW" ] || [ "$CA_CERT_RAW" = "null" ]; then
    echo "❌ Could not get cluster CA certificate!"
    exit 1
fi

# Check if the certificate is in PEM format or base64 encoded
if [[ "$CA_CERT_RAW" == "-----BEGIN CERTIFICATE-----"* ]]; then
    echo "Certificate is in PEM format, converting to base64..."
    # Extract the base64 content from PEM (remove headers and newlines)
    CA_CERT=$(echo "$CA_CERT_RAW" | sed '/-----BEGIN CERTIFICATE-----/d' | sed '/-----END CERTIFICATE-----/d' | tr -d '\n\r ')
else
    echo "Certificate appears to be in base64 format already"
    # The CA cert from Yandex Cloud is already base64 encoded, but we need to make sure
    # it's properly formatted for GitHub secrets (no newlines in the secret value itself)
    CA_CERT=$(echo "$CA_CERT_RAW" | tr -d '\n\r')
fi

echo "✅ CA certificate retrieved and formatted (length: ${#CA_CERT} characters)"

echo ""
echo "3. Creating service account for GitHub Actions..."

# Create kubeconfig for this cluster first
yc managed-kubernetes cluster get-credentials $CLUSTER_ID --external

# Test connection
echo "Testing cluster connection..."
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Cannot connect to cluster. Please check your configuration."
    exit 1
fi

echo "✅ Successfully connected to cluster"

# Create service account
kubectl create serviceaccount github-actions -n kube-system --dry-run=client -o yaml | kubectl apply -f -

# Create cluster role binding
kubectl create clusterrolebinding github-actions-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:github-actions \
  --dry-run=client -o yaml | kubectl apply -f -

# Create secret for service account token (for Kubernetes 1.24+)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: github-actions-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: github-actions
type: kubernetes.io/service-account-token
EOF

echo "Waiting for token to be created..."
sleep 10

# Get the token
SA_TOKEN=$(kubectl get secret github-actions-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)

if [ -z "$SA_TOKEN" ]; then
    echo "❌ Could not retrieve service account token!"
    echo "The secret might not be ready yet. Wait a few seconds and try:"
    echo "kubectl get secret github-actions-token -n kube-system -o jsonpath='{.data.token}' | base64 -d"
    exit 1
fi

echo "✅ Service account token retrieved (length: ${#SA_TOKEN} characters)"

echo ""
echo "4. Getting other required secrets..."

# Get Registry ID
if [ -f "infrastructure/terraform.tfstate" ]; then
    REGISTRY_ID=$(cd infrastructure && terraform output -raw container_registry_id 2>/dev/null)
fi

if [ -z "$REGISTRY_ID" ]; then
    echo "Getting registry ID from Yandex Cloud..."
    REGISTRY_ID=$(yc container registry list --format json | jq -r '.[0].id // empty')
fi

if [ -z "$REGISTRY_ID" ]; then
    echo "❌ Could not find container registry ID!"
    echo "Please create a container registry first or check your terraform state."
    exit 1
fi

# Get Cloud and Folder IDs
CLOUD_ID=$(yc config get cloud-id)
FOLDER_ID=$(yc config get folder-id)

# Get Service Account Key
if [ -f "infrastructure/key.json" ]; then
    SA_KEY=$(cat infrastructure/key.json | tr -d '\n\r')
else
    echo "❌ Service account key file not found at infrastructure/key.json"
    echo "Please make sure you have the service account key file."
    exit 1
fi

echo ""
echo "=== GITHUB SECRETS CONFIGURATION ==="
echo ""
echo "Copy these values to your GitHub repository secrets:"
echo "Repository → Settings → Secrets and variables → Actions → New repository secret"
echo ""

echo "YC_REGISTRY_ID:"
echo "$REGISTRY_ID"
echo ""

echo "YC_CLOUD_ID:"
echo "$CLOUD_ID"
echo ""

echo "YC_FOLDER_ID:"
echo "$FOLDER_ID"
echo ""

echo "YC_SERVICE_ACCOUNT_KEY:"
echo "$SA_KEY"
echo ""

echo "K8S_SERVER:"
echo "$EXTERNAL_ENDPOINT"
echo ""

echo "K8S_CA_CERT:"
echo "$CA_CERT"
echo ""

echo "K8S_TOKEN:"
echo "$SA_TOKEN"
echo ""

echo "=== VERIFICATION ==="
echo ""
echo "To verify these settings work, you can test locally:"
echo ""

# Create a test kubeconfig
cat > test-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_CERT
    server: $EXTERNAL_ENDPOINT
  name: yc-cluster
contexts:
- context:
    cluster: yc-cluster
    user: github-actions
  name: yc-context
current-context: yc-context
users:
- name: github-actions
  user:
    token: $SA_TOKEN
EOF

echo "Testing GitHub Actions kubeconfig..."
if KUBECONFIG=test-kubeconfig.yaml kubectl cluster-info >/dev/null 2>&1; then
    echo "✅ GitHub Actions kubeconfig works correctly!"
    echo "✅ CA certificate is properly base64 encoded for GitHub secrets"
else
    echo "❌ GitHub Actions kubeconfig test failed!"
    echo "Let's test the certificate format..."
    
    # Test if we can decode the certificate
    if echo "$CA_CERT" | base64 -d > /dev/null 2>&1; then
        echo "✅ Certificate can be decoded from base64"
    else
        echo "❌ Certificate cannot be decoded from base64"
        echo "This might indicate a formatting issue."
    fi
fi

# Cleanup test file
rm -f test-kubeconfig.yaml

echo ""
echo "=== NEXT STEPS ==="
echo "1. Add all the secrets above to your GitHub repository"
echo "2. Make sure your cluster has external endpoint enabled"
echo "3. Push a new commit or create a tag to trigger the workflow"
echo ""

# Save values to a file for easy reference
cat > github-secrets.txt <<EOF
YC_REGISTRY_ID=$REGISTRY_ID
YC_CLOUD_ID=$CLOUD_ID
YC_FOLDER_ID=$FOLDER_ID
K8S_SERVER=$EXTERNAL_ENDPOINT
K8S_CA_CERT=$CA_CERT
K8S_TOKEN=$SA_TOKEN
EOF

echo "Values also saved to github-secrets.txt for your reference"
echo "(Remember to delete this file after setting up secrets!)"
