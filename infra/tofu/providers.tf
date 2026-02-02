terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.38"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "ovh" {
  endpoint = "ovh-ca"
}

# AWS provider is used for S3 Object Storage on OVH
# because it's S3-compatible.
provider "aws" {
  region     = var.s3_region
  access_key = var.s3_access_key
  secret_key = var.s3_secret_key

  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    s3 = "https://${var.s3_endpoint}"
  }
}
