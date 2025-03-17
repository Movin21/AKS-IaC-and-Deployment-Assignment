#!/bin/bash
echo "Deploying AKS cluster..."
terraform init
terraform apply -auto-approve
echo "Fetching kubeconfig..."
az aks get-credentials --resource-group aks-assignment-rg --name my-aks-cluster
echo "Deploying app..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
echo "Waiting for external IP..."
sleep 60  # Wait for LoadBalancer to assign IP
kubectl get service echoserver-service