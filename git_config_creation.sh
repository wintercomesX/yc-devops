# Check your existing kubeconfig size
kubectl config view --raw > temp-kubeconfig.yaml
KUBECONFIG_SIZE=$(wc -c < temp-kubeconfig.yaml)
echo "Current kubeconfig size: $KUBECONFIG_SIZE bytes"
echo "GitHub secret limit: 65536 bytes"

if [ $KUBECONFIG_SIZE -gt 65536 ]; then
    echo "Kubeconfig is too large for GitHub secrets"
    echo "We'll use the component extraction method"
else
    echo "Kubeconfig is small enough, but we'll still use components for better security"
fi

# Extract cluster information from your existing kubeconfig
CLUSTER_ENDPOINT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA_B64=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

echo "Cluster Endpoint: $CLUSTER_ENDPOINT"
echo "CA Certificate length: ${#CLUSTER_CA_B64} characters"

# Clean up temp file
rm temp-kubeconfig.yaml

# Create service account for CI/CD in Kubernetes
kubectl create serviceaccount github-actions -n kube-system

# Create cluster role binding
kubectl create clusterrolebinding github-actions-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:github-actions

# Create secret for service account token
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

# Wait for token to be created
sleep 5

# Get the token
SA_TOKEN=$(kubectl get secret github-actions-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)
echo "Service Account Token length: ${#SA_TOKEN}"

# Save cluster CA certificate to file for verification
echo "$CLUSTER_CA_B64" | base64 -d > cluster-ca.crt
echo "✅ Cluster CA certificate saved to cluster-ca.crt"

# Verify the certificate is valid
openssl x509 -in cluster-ca.crt -text -noout | head -5

echo "✅ Components ready for GitHub secrets:"
echo "   - Cluster endpoint: $CLUSTER_ENDPOINT"
echo "   - CA certificate (base64): Ready"
echo "   - Service account token: Ready"
