#!/bin/bash

echo "=== GitHub Secrets Configuration ==="
echo ""
echo "YC_REGISTRY_ID:"
cd infrastructure && terraform output -raw container_registry_id
cd ..
echo ""

echo "YC_CLOUD_ID:"
yc config get cloud-id
echo ""

echo "YC_FOLDER_ID:"
yc config get folder-id
echo ""

echo "YC_SERVICE_ACCOUNT_KEY:"
cat infrastructure/key.json
echo ""

echo "K8S_SERVER:"
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}'
echo ""

echo "K8S_CA_CERT:"
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
echo ""

echo "K8S_TOKEN:"
kubectl get secret github-actions-token -n kube-system -o jsonpath='{.data.token}' | base64 -d
echo ""
echo ""
echo "=== Copy each value to GitHub Secrets ==="
