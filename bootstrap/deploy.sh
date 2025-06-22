#!/bin/bash
cd /root/yc-devops/bootstrap
# Initialize Terraform
terraform init

echo "Init: OK"

# List your cloud and folder IDs (optional, for verification)
yc config list

# Run terraform plan with variables
terraform plan

echo "Plan: OK"
# Apply the plan
terraform apply -auto-approve

echo "Apply: OK"
# Save outputs for later use
terraform output -raw access_key > ../access_key.txt
terraform output -raw secret_key > ../secret_key.txt
terraform output -raw bucket_name > ../bucket_name.txt

echo "Deployment complete. Outputs saved in ../"
