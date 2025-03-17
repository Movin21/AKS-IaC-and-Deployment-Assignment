#!/bin/bash

# Exit on any error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting AKS cluster deployment...${NC}"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init || { echo -e "${RED}Terraform init failed${NC}"; exit 1; }

# Apply Terraform configuration
echo "Deploying AKS cluster with Terraform..."
terraform apply -auto-approve || { echo -e "${RED}Terraform apply failed${NC}"; exit 1; }

# Fetch kubeconfig
echo "Fetching kubeconfig for AKS cluster..."
az aks get-credentials --resource-group aks-assignment-rg --name my-aks-cluster || { echo -e "${RED}Failed to get kubeconfig${NC}"; exit 1; }

# Verify cluster connection
echo "Verifying cluster connection..."
kubectl get nodes || { echo -e "${RED}kubectl failed - check your cluster or kubeconfig${NC}"; exit 1; }

# Deploy the nginx app
echo "Deploying nginx app to AKS..."
kubectl apply -f k8s/deployment.yaml || { echo -e "${RED}Deployment apply failed${NC}"; exit 1; }
kubectl apply -f k8s/service.yaml || { echo -e "${RED}Service apply failed${NC}"; exit 1; }

# Wait for the external IP to be assigned with a loop
echo "Waiting for LoadBalancer to assign an external IP..."
MAX_ATTEMPTS=6  # 6 attempts = 2 minutes (10 seconds each)
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    EXTERNAL_IP=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}External IP assigned: $EXTERNAL_IP${NC}"
        break
    else
        echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: IP not assigned yet, waiting 10 seconds..."
        sleep 10
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

if [ -z "$EXTERNAL_IP" ]; then
    echo -e "${RED}External IP not assigned after $MAX_ATTEMPTS attempts. Check 'kubectl get service nginx-service' manually.${NC}"
else
    echo -e "${GREEN}nginx app deployed! Test it at: http://$EXTERNAL_IP${NC}"
    # Test the app automatically
    echo "Testing the app..."
    curl -s http://$EXTERNAL_IP | grep "Welcome to nginx" && echo -e "${GREEN}Test passed!${NC}" || echo -e "${RED}Test failed - check the app${NC}"
fi

echo -e "${GREEN}Deployment complete!${NC}"