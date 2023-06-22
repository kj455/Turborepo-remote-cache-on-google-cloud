# Turborepo remote cache on Google Cloud

This repository provides a streamlined process for setting up and managing a self-hosted Turborepo remote cache on Google Cloud, utilizing the [ducktors/turborepo-remote-cache](https://github.com/ducktors/turborepo-remote-cache) project.

<img width="800" alt="architecture" src="https://github.com/kj455/turborepo-remote-cache-cr-gcs/assets/38521709/4c256d26-c8ba-46e9-87bd-7f4fe41e652c" style="margin: 16px 0">

## 🚀 Getting Started
### Prerequisites
1. Clone this repository
2. Ensure Terraform is set up and the "Resource Manager API" is enabled on Google Cloud
3. Create service accounts with the following roles:
    - Editor (or roles with sufficient permissions to create necessary resources)
    - Secret Manager Admin
    - Security Admin
4. Download the private key (in JSON format) of the service account and place it in the root of this repository as "credentials.json"

### Setup and Deployment
1. Authenticate the gcloud CLI:
    ```sh
    gcloud auth login --cred-file=./credentials.json
    ```
6. Prepare your Terraform variables:
    ```sh
    cp terraform.tfvars.example terraform.tfvars
    # Edit the copied file (terraform.tfvars) with your details
    ```
7. Initialize and apply your Terraform configuration:
    ```sh
    cd terraform
    terraform init
    terraform plan
    terraform apply
    ```
8. Pull the [fox1t/turborepo-remote-cache](https://hub.docker.com/r/fox1t/turborepo-remote-cache) image from Docker Hub and push it to your Artifact Registry:

    <details>
    <summary>Click here for detailed instructions</summary>

    ```sh
    # only amd64 image works
    docker pull fox1t/turborepo-remote-cache:(tag)@(digest-of-amd64-image)

    docker tag fox1t/turborepo-remote-cache:(tag)@(digest-of-amd64-image) (artifact-registry-repository-location)/turborepo-remote-cache:(tag)

    docker push (artifact-registry-repository-location)/turborepo-remote-cache:(tag)
    ```
    </details>

9. Now your remote cache server is set up and ready to use! 🚀

    ```sh
    turbo run ${command} \
    --api=${cloud run url} \
    --team=${your team name} \
    --token=${turbo_token in terraform.tfvars}
    ```

Note: If you push another image into the Artifact Registry, a new revision will be created automatically.

Enjoy your self-hosted Turborepo remote cache!

**Any feature requests or pull requests are welcome!**