#!/bin/bash

cd /root/yc-devops/infrastructure

# Path to your terraform state file
TFSTATE_FILE="../bootstrap/terraform.tfstate"

# Create IAM key
SERVICE_ACCOUNT_ID=$(jq -r '.outputs.service_account_id.value' "$TFSTATE_FILE")
yc iam key create \
  --service-account-id "$SERVICE_ACCOUNT_ID" \
  --output key.json

#Save backend current state to avoid github error

cp backend.tf backend_backup.tf

# Read bucket and credentials info
BUCKET_NAME=$(cat ../bucket_name.txt)
ACCESS_KEY=$(cat ../access_key.txt)
SECRET_KEY=$(cat ../secret_key.txt)

# Update backend.tf with actual values
sed -i 's/\(bucket\s*=\s*"\)[^"]*\(".*\)/\1'${BUCKET_NAME}'\2/' backend.tf
sed -i 's/\(access_key\s*=\s*"\)[^"]*\(".*\)/\1'${ACCESS_KEY}'\2/' backend.tf
sed -i 's/\(secret_key\s*=\s*"\)[^"]*\(".*\)/\1'${SECRET_KEY}'\2/' backend.tf

# Initialize Terraform with remote backend
terraform init -reconfigure

# Plan and apply with variables
terraform plan
terraform apply -auto-approve

#Verification step
bash verification.sh
