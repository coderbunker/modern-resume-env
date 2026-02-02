# Infrastructure Management

This directory contains the infrastructure-as-code (IaC) for the Modern Resume ecosystem using [OpenTofu](https://opentofu.org/).

## Architecture Overview

The infrastructure consists of several components hosted primarily on OVHcloud:

- **Nix Cache (S3)**: An S3-compatible bucket used to store pre-built Nix derivations for fast CI/CD and developer environment setup.
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

Create a `terraform.tfvars` file or set environment variables:

```hcl
s3_access_key = "your-access-key"
s3_secret_key = "your-secret-key"
```

Then run:

```bash
tofu plan
tofu apply
```

## Managed Resources

### Nix Cache (S3)

The cache bucket is defined in `infra/tofu/s3.tf`. It is used by the GitHub Actions workflow `.github/workflows/push-to-s3.yml` to store built environments.

### Future Work

- **Kubernetes Provisioning**: Automate the creation of the Managed Kubernetes clusters.
- **Managed DB**: Automate the provisioning of the PostgreSQL databases.
- **Secret Management**: Integrate with a secret manager (e.g., Vault or OVH Secret Management).
