# Infrastructure Management

This directory contains the infrastructure-as-code (IaC) for the Modern Resume ecosystem using [OpenTofu](https://opentofu.org/).

## Architecture Overview

The infrastructure consists of several components hosted primarily on OVHcloud:

- **Nix Cache (S3)**: An S3-compatible bucket (`modern-resume-nix-cache`) used to store pre-built Nix derivations.
- **Tofu State (S3)**: A dedicated S3-compatible bucket (`modern-resume-tofu-state`) used to store the OpenTofu state file for idempotency and teamwork.
- **Kubernetes (Managed)**: Used for running self-hosted GitHub Actions runners and the application services (Backend/Frontend).
- **Managed Databases**: PostgreSQL instances for the application.

## Prerequisites

1.  **Nix Shell**: Enter the development shell to have `tofu` available:
    ```bash
    nix develop
    ```
2.  **OVH Credentials**: Ensure you have your OVH API credentials (`APPLICATION_KEY`, `APPLICATION_SECRET`, `CONSUMER_KEY`).
3.  **S3 Credentials**: Required for managing object storage via the S3-compatible API.

## OpenTofu Usage

The Tofu scripts are located in `infra/tofu/`.

### Initialization

```bash
cd infra/tofu
tofu init
```

### Plan and Apply

1.  **Project ID**: Get your OVH Public Cloud Project ID from the OVH Manager.
2.  **Initial Run**: Add it to your `terraform.tfvars`:
    ```hcl
    ovh_project_id = "your-project-id"
    ```
3.  **Bootstrap**: Run `tofu plan` and `tofu apply`. This will:
    -   Create an S3 User in OVH.
    -   Generate S3 credentials.
    -   Manage your Nix Cache bucket.

### Achieving Full Idempotency (Remote Backend)

Because `.tfstate` is gitignored, your setup is currently only idempotent on your local machine. To make it work everywhere (including CI/CD):

1.  After the first successful `tofu apply`, copy the `generated_s3_` outputs.
2.  Uncomment the `backend "s3"` block in `providers.tf`.
3.  Run `tofu init`. Tofu will ask if you want to migrate your local state to the new S3 bucket.
4.  Say **yes**. Now your state is stored in the cloud, and Tofu will always know the bucket exists, regardless of where you run it from.

## Managed Resources

### Nix Cache (S3)

The cache bucket is defined in `infra/tofu/s3.tf`. It is used by the GitHub Actions workflow `.github/workflows/push-to-s3.yml` to store built environments.

### Future Work

- **Kubernetes Provisioning**: Automate the creation of the Managed Kubernetes clusters.
- **Managed DB**: Automate the provisioning of the PostgreSQL databases.
- **Secret Management**: Integrate with a secret manager (e.g., Vault or OVH Secret Management).
