#!/bin/bash
cd test-app

# Build image
docker build -t test-app:1.0.0 .

# Get registry info
REGISTRY_ID=$(cd /root/yc-devops/infrastructure && terraform output -raw container_registry_id)

# Configure Docker for Yandex Container Registry
yc container registry configure-docker

# Tag and push
docker tag test-app:v1.0.0 cr.yandex/${REGISTRY_ID}/test-app:v1.0.0
docker push cr.yandex/${REGISTRY_ID}/test-app:v1.0.0
