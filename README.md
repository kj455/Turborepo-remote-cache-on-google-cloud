# Turborepo remote cache on Google Cloud

Easy self-hosting and management Turborepo remote cache（[ducktors/turborepo-remote-cache](https://github.com/ducktors/turborepo-remote-cache)） on Google Cloud.

<img width="800" alt="architecture" src="https://github.com/kj455/turborepo-remote-cache-cr-gcs/assets/38521709/4c256d26-c8ba-46e9-87bd-7f4fe41e652c" style="margin: 16px 0">

## 🚀 Usage
1. Clone this repository
2. Setup Terraform and enable "Resource Manager API" on Google Cloud
3. Create service accounts with editor and IAM administrator roles
4. Download the private key (JSON) for the service account and place it in the root of this repository as "credentials.json"
5. Authenticate gcloud cli
    ```sh
    gcloud auth login --cred-file=./credentials.json
    ```
6. Setup terraform variables
    ```sh
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars
    ```
7. Exec terraform
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```
8. Pull [fox1t/turborepo-remote-cache](https://hub.docker.com/r/fox1t/turborepo-remote-cache) image from Docker Hub and push it to artifact registry

    <details>
    <summary>details</summary>

    ```sh
    # only amd64 image works
    docker pull fox1t/turborepo-remote-cache:(tag)@(digest-of-amd64-image)

    docker tag fox1t/turborepo-remote-cache:(tag)@(digest-of-amd64-image) (artifact-registry-repository-location)/turborepo-remote-cache:(tag)

    docker push (artifact-registry-repository-location)/turborepo-remote-cache:(tag)
    ```
    </details>

10. Remote cache server is ready to use!!! 🚀

    ```sh
    turbo run ${command} \
    --api=${cloud run url} \
    --team=${your team name} \
    --token=${turbo_token in terraform.tfvars}
    ```

11. (If you push another image into the artifact registry, a new revision will be created automatically)