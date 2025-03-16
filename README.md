# AKS IaC and Deployment Assignment

## Overview

Visit [`http://51.8.25.138/`](http://51.8.25.138/) (currently running instance)

**Deployment is Automated - simply run deploy.sh script**

![Nginx Page](https://github.com/user-attachments/assets/64eda0b8-b485-4d17-9817-163a7ca56674)

This project sets up an Azure Kubernetes Service (AKS) cluster using Terraform and deploys an `nginx` web server with 2 replicas, exposed via a LoadBalancer over HTTP. It uses Azure Blob Storage as a remote backend for Terraform state, with a storage account created automatically and randomized for uniqueness. A bash script automates deployment and ensures the external IP is assigned. All code is in this public GitHub repo.

## Steps to Set Up the AKS Cluster

1. **Authenticated with Azure**:

   - Ran `az login` to log in via the browser.
   - Set subscription: `az account set --subscription "<subscription-id>"`.

2. **Wrote Terraform Config**:

   - Used AzureRM provider version `~> 3.0` in `provider.tf` (avoids subscription key requirement in 4.0+).
   - Created `provider.tf`, `main.tf`, and `variables.tf` to define:
     - A resource group (`aks-assignment-rg`).
     - A storage account (prefix `aksstate` + random suffix) and container (`tfstate`) for Terraform state.
     - A 2-node AKS cluster (`my-aks-cluster`) with kubenet networking.
     - Assigned a SystemAssigned identity to the cluster, granting Contributor role permissions.

3. **Deployed the Cluster**:

   - Initialized: `terraform init` (first locally, then with remote backend).
   - Deployed storage resources first, then configured remote backend in Blob Storage via `deploy.sh`.
   - Applied: `terraform apply -auto-approve` (two phases in script).
   - Took ~5-10 minutes to provision.
   - Outputs: Shows `cluster_name`, `resource_group_name`, `storage_account_name`, and an external IP command.

4. **Connected to the Cluster**:

   - Fetched kubeconfig: `az aks get-credentials --resource-group aks-assignment-rg --name my-aks-cluster`
   - Verified: `kubectl get nodes` (saw 2 nodes).

   ![Cluster Nodes](https://github.com/user-attachments/assets/eb6e65ec-c7f6-43a1-96e3-6418fe9b3a4f)

## How I Deployed the App (When Devoloping)

1. **Wrote Kubernetes YAMLs**:

   - `k8s/deployment.yaml`: Deploys `nginx:latest` with 2 replicas on port 80.
   - `k8s/service.yaml`: Exposes it with a LoadBalancer on port 80.

2. **Automated Deployment**:

   - Created `deploy.sh` to:
     - Deploy resource group and storage account first (Terraform).
     - Configure the remote backend with a unique storage account name.
     - Deploy the AKS cluster.
     - Fetch kubeconfig and apply YAMLs.
     - Loop to wait for the external IP (up to 2 minutes).

3. **Ran the Script**:
   - Made it executable: `chmod +x deploy.sh`
   - Executed: `./deploy.sh` to handle everything in one go.

## How to Check It’s Working

1. **Verify Pods**:

   - `kubectl get pods`
   - Look for 2 `nginx` pods with `STATUS: Running` and `READY: 1/1`.

   ![Pods Running](https://github.com/user-attachments/assets/a64f46bb-c8ac-489d-b80d-9e03aa590fc5)

2. **Get External IP**:

   - `kubectl get service nginx-service`
   - Note the `EXTERNAL-IP` (e.g., `4.156.88.136` or currently `http://51.8.25.138/`).

   ![Service IP](https://github.com/user-attachments/assets/22cc2808-5b6c-4bb8-9db5-7f44f99957f1)

3. **Test the App**:
   - Command: `curl http://<external-ip>`
   - Output: HTML with `<h1>Welcome to nginx!</h1>`.
   - Browser: Open `http://<external-ip>` to see the welcome page.
   - Tested with:
     - `curl http://4.156.88.136` (previous run).
     - `curl http://51.8.25.138/` (currently running instance).
   - The script also tests it automatically with `curl`.

## Challenges and Solutions

1. **External IP Delay**:

   - **Hiccup**: The LoadBalancer IP sometimes took longer than expected to assign.
   - **Fix**: Added a loop in `deploy.sh` to check every 10 seconds for up to 2 minutes, ensuring it captures the IP when ready.

2. **Terraform Version Choice**:

   - **Hiccup**: AzureRM 4.0+ requires a subscription key in the provider block, complicating setup.
   - **Fix**: Used `~> 3.0` in `provider.tf` to rely on `az login` authentication, making deployment simpler for this assignment.

3. **HTTPS Attempt**:

   - **Hiccup**: Tried adding HTTPS with a self-signed TLS certificate, but it caused browser warnings and added complexity.
   - **Fix**: Reverted to HTTP to keep the demo simple and avoid self-signed cert warnings for reviewers.

4. **Terraform State Management**:

   - **Hiccup**: Local state file wasn’t ideal for consistency; initial backend setup failed due to timing and uniqueness issues.
   - **Fix**: Added a remote backend with Azure Blob Storage, automated storage account creation with a randomized name (e.g., `aksstatex7k9p2m`), and split deployment in `deploy.sh` to create storage first.

5. **Learning Curve**:
   - **Hiccup**: New to AKS and Terraform syntax.
   - **Fix**: Used the [Terraform AKS Guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) and trial-and-error to get it working.

## Files

- `provider.tf`, `main.tf`, `variables.tf`: Terraform config for AKS and remote state backend (using AzureRM ~> 3.0).
- `k8s/deployment.yaml`, `k8s/service.yaml`: Kubernetes manifests for `nginx`.
- `deploy.sh`: Automation script with backend setup, error checking, and IP loop.
- `.gitignore`: Excludes sensitive files (e.g., `terraform.tfstate`).

## Cleanup

- To avoid charges: `terraform destroy` (removes all resources).

## Bonus

- Added color-coded output in `deploy.sh` for better readability.
- Included an automatic `curl` test in the script to verify `nginx` responds.
- Used a remote Terraform backend in Azure Blob Storage for state management.
- Added screenshots to visually confirm the setup works.
