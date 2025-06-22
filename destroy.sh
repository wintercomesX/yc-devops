#!/bin/bash

#Destroy infrastructure
cd /root/yc-devops/infrastructure
terraform destroy -auto-approve
echo "infrastructure destroyed"

#Destroy s3
cd /root/yc-devops/bootstrap
terraform destroy -auto-approve
echo "S3 destroyed"

# Destroy registries
REGISTRIES=$(yc container registry list --format json | jq -r '.[].id' 2>/dev/null || echo "")
if [ -n "$REGISTRIES" ]; then
    for registry_id in $REGISTRIES; do
        echo "🗑️  Deleting registry: $registry_id"
        
        # First, delete all images in the registry
        echo "  Deleting images..."
        IMAGES=$(yc container image list --registry-id="$registry_id" --format json | jq -r '.[].id' 2>/dev/null || echo "")
        
        if [ -n "$IMAGES" ]; then
            # Store operation IDs for synchronous waiting
            OPERATION_IDS=()
            
            for image_id in $IMAGES; do
                echo "    Deleting image: $image_id"
                # Remove --async flag to wait for completion, or capture operation ID
                OPERATION_ID=$(yc container image delete "$image_id" --async --format json | jq -r '.id' 2>/dev/null)
                if [ -n "$OPERATION_ID" ] && [ "$OPERATION_ID" != "null" ]; then
                    OPERATION_IDS+=("$OPERATION_ID")
                fi
            done
            
            # Wait for all image deletion operations to complete
            echo "  Waiting for image deletions to complete..."
            for op_id in "${OPERATION_IDS[@]}"; do
                echo "    Waiting for operation: $op_id"
                yc operation wait "$op_id"
            done
            
            # Additional verification - wait until no images are left
            echo "  Verifying all images are deleted..."
            while true; do
                REMAINING_IMAGES=$(yc container image list --registry-id="$registry_id" --format json | jq -r '.[].id' 2>/dev/null || echo "")
                if [ -z "$REMAINING_IMAGES" ]; then
                    echo "  ✅ All images deleted successfully"
                    break
                else
                    echo "  Still waiting for images to be deleted..."
                    sleep 10
                fi
            done
        else
            echo "  No images found in registry"
        fi
        
        # Delete the registry
        echo "  Deleting registry..."
        yc container registry delete "$registry_id"
        echo "✅ Registry $registry_id deleted"
    done
else
    echo "📋 No container registries found"
fi
#Replacing REGESTRY_ID back
cd
cd /root/yc-devops/k8s-configs
rm test-app-deployment.yaml
cp app_backup.yaml test-app-deployment.yaml
rm app_backup.yaml
