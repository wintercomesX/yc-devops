#!/bin/bash

#Create s3 structure
echo -e "\e[1;33mStarting s3 deployment\e[0m"

bash /root/yc-devops/bootstrap/deploy.sh

echo -e "\e[1;33mDeployment complete\e[0m"

#Create infrastructure
echo -e "\e[1;33mStarting infrastructure deployment\e[0m"

bash /root/yc-devops/infrastructure/deploy.sh

echo -e "\e[1;33mDeployment complete\e[0m"

echo -e "\e[1;33mWaiting infrastructure to be deployed \e[0m"

#Create test app
echo -e "\e[1;33mStarting app deployment\e[0m"

bash /root/yc-devops/test-app/deploy.sh

echo -e "\e[1;33mDeployment complete\e[0m"

#Create monitoring and nginx
echo -e "\e[1;33mStarting monitoring and nginx deployment\e[0m"

bash /root/yc-devops/k8s-configs/deploy.sh

echo -e "\e[1;33mDeployment complete\e[0m"
