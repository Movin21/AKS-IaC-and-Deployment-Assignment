#!/bin/bash
set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting AKS cluster deployment...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed.${NC}"
    exit 1
fi

echo "Initializing Terraform with local backend..."
terraform init || { echo -e "${RED}Terraform init failed${NC}"; exit 1; }

echo "Deploying resource group and storage account first..."
terraform apply -auto-approve -target=azurerm_resource_group.rg -target=azurerm_storage_account.state -target=azurerm_storage_container.state_container || { echo -e "${RED}Initial apply failed${NC}"; exit 1; }

echo "Fetching storage account name..."
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name) || { echo -e "${RED}Failed to get storage account name${NC}"; exit 1; }
echo "Storage account: $STORAGE_ACCOUNT"

echo "Configuring Terraform remote backend..."
terraform init -backend-config="resource_group_name=aks-assignment-rg" \
               -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
               -backend-config="container_name=tfstate" \
               -backend-config="key=terraform.tfstate" \
               -reconfigure -force-copy || { echo -e "${RED}Backend config failed${NC}"; exit 1; }

echo "Deploying full AKS cluster..."
terraform apply -auto-approve || { echo -e "${RED}Terraform apply failed${NC}"; exit 1; }

echo "Fetching kubeconfig..."
az aks get-credentials --resource-group aks-assignment-rg --name my-aks-cluster || { echo -e "${RED}Failed to get kubeconfig${NC}"; exit 1; }

echo "Verifying cluster..."
kubectl get nodes || { echo -e "${RED}kubectl failed${NC}"; exit 1; }

echo "Deploying nginx app..."
kubectl apply -f k8s/deployment.yaml || { echo -e "${RED}Deployment failed${NC}"; exit 1; }
kubectl apply -f k8s/service.yaml || { echo -e "${RED}Service failed${NC}"; exit 1; }

echo "Waiting for external IP..."
MAX_ATTEMPTS=12
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    EXTERNAL_IP=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}External IP assigned: $EXTERNAL_IP${NC}"
        break
    else
        echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Waiting 10 seconds..."
        sleep 10
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

if [ -z "$EXTERNAL_IP" ]; then
    echo -e "${RED}IP not assigned after $MAX_ATTEMPTS attempts.${NC}"
else
    echo -e "${GREEN}nginx app deployed! Test it at: http://$EXTERNAL_IP${NC}"
    echo "Testing the app..."
    curl -s http://$EXTERNAL_IP | grep "Welcome to nginx" && echo -e "${GREEN}Test passed!${NC}" || echo -e "${RED}Test failed${NC}"
fi

echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${RED}Reminder: Run 'terraform destroy' to clean up resources and avoid charges.${NC}"