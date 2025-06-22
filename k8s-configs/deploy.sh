### Deploy Monitoring Stack with Helm
cd /root/yc-devops/k8s-configs
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30300 \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30900 \
  --set alertmanager.service.type=NodePort \
  --set alertmanager.service.nodePort=30903

# Install nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer

### Deploy Test Application
#cd k8s-configs
cp test-app-deployment.yaml app_backup.yaml

# Update registry ID in deployment file
REGISTRY_ID=$(cd /root/yc-devops/infrastructure && terraform output -raw container_registry_id)
sed -i "s/REGISTRY_ID/${REGISTRY_ID}/" test-app-deployment.yaml
sleep 2m
# Apply configurations
kubectl apply -f namespace.yaml
kubectl apply -f test-app-deployment.yaml
kubectl apply -f grafana-loadbalancer.yaml
sleep 1m

# Checking state
kubectl get pods -n monitoring
kubectl get pods -n test-app
kubectl get svc -n monitoring
kubectl get svc -n ingress-nginx
