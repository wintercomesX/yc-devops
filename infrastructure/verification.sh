#!/bin/bash

echo "Verification Starting"

echo "Check Kubernetes cluster"
  yc managed-kubernetes cluster list
echo "Finished"

echo "Verify nodes"
  yc managed-kubernetes node-group list
echo "Finished"

echo "Test kubectl access"
  yc managed-kubernetes cluster get-credentials main-k8s-cluster --external --force
  kubectl get nodes
  kubectl get pods --all-namespaces
echo "Finished"
