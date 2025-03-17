# AKS IaC and Deployment Assignment

## Overview

`curl http://128.203.121.40` (currently running instance)

This project sets up an Azure Kubernetes Service (AKS) cluster using Terraform and deploys an `nginx` web server with 2 replicas, exposed via a LoadBalancer. It includes a bash script for automation and a loop to ensure the external IP is assigned. All code is in this public GitHub repo.

## Steps to Set Up the AKS Cluster

1. **Authenticated with Azure**:

   - Ran `az login` to log in via the browser.
   - Set subscription: `az account set --subscription "<subscription-id>"`.

2. **Wrote Terraform Config**:

   - Used AzureRM provider version `~> 3.0` in `provider.tf` (avoids subscription key requirement in 4.0+).
   - Created `provider.tf` and `main.tf` to define:
     - A resource group (`aks-assignment-rg`).
     - A 2-node AKS cluster (`my-aks-cluster`) with kubenet networking.

3. **Deployed the Cluster**:

   - Initialized: `terraform init`
   - Applied: `terraform apply -auto-approve`
   - Took ~5-10 minutes to provision.

4. **Connected to the Cluster**:
   - Fetched kubeconfig: `az aks get-credentials --resource-group aks-assignment-rg --name my-aks-cluster`
   - Verified: `kubectl get nodes` (saw 2 nodes).

## How I Deployed the App

1. **Wrote Kubernetes YAMLs**:

   - `k8s/deployment.yaml`: Deploys `nginx:latest` with 2 replicas on port 80.
   - `k8s/service.yaml`: Exposes it with a LoadBalancer on port 80.

2. **Automated Deployment**:

   - Created `deploy.sh` to:
     - Deploy the cluster (Terraform).
     - Fetch kubeconfig.
     - Apply YAMLs: `kubectl apply -f k8s/deployment.yaml` and `kubectl apply -f k8s/service.yaml`.
     - Loop to wait for the external IP (up to 2 minutes).

3. **Ran the Script**:
   - Made it executable: `chmod +x deploy.sh`
   - Executed: `./deploy.sh` to handle everything in one go.

## How to Check It’s Working

1. **Verify Pods**:

   - `kubectl get pods`
   - Look for 2 `nginx` pods with `STATUS: Running` and `READY: 1/1`.

2. **Get External IP**:

   - `kubectl get service nginx-service`
   - Note the `EXTERNAL-IP` (e.g., `4.156.88.136` or currently `128.203.121.40`).

3. **Test the App**:
   - Command: `curl http://<external-ip>`
   - Output: HTML with `<h1>Welcome to nginx!</h1>`.
   - Browser: Open `http://<external-ip>` to see the welcome page.
   - Tested with:
     - `curl http://4.156.88.136` (previous run).
     - `curl http://128.203.121.40` (currently running instance).
   - The script also tests it automatically with `curl`.

## Challenges and Solutions

1. **External IP Delay**:

   - **Hiccup**: The LoadBalancer IP sometimes took longer than expected to assign.
   - **Fix**: Added a loop in `deploy.sh` to check every 10 seconds for up to 2 minutes, ensuring it captures the IP when ready.

2. **Terraform Version Choice**:

   - **Hiccup**: AzureRM 4.0+ requires a subscription key in the provider block, complicating setup.
   - **Fix**: Used `~> 3.0` in `provider.tf` to rely on `az login` authentication, making deployment simpler for this assignment.

3. **Learning Curve**:
   - **Hiccup**: New to AKS and Terraform syntax.
   - **Fix**: Used the [Terraform AKS Guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) and trial-and-error to get it working.

## Files

- `provider.tf`, `main.tf`: Terraform config for AKS (using AzureRM ~> 3.0).
- `k8s/deployment.yaml`, `k8s/service.yaml`: Kubernetes manifests for `nginx`.
- `deploy.sh`: Automation script with error checking and IP loop.
- `.gitignore`: Excludes sensitive files (e.g., `terraform.tfstate`).

## Cleanup

- To avoid charges: `terraform destroy` (removes all resources).

## Bonus

- Added color-coded output in `deploy.sh` for better readability.
- Included an automatic `curl` test in the script to verify `nginx` responds.
