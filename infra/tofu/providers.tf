terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.10" # Modern version supporting S3 native resources
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Once you have run 'tofu apply' once and created the bucket,
  # you can uncomment this block and run 'tofu init' to migrate
  # your state to the bucket, making it idempotent across all machines.
  #
  backend "s3" {
     bucket                      = "modern-resume-tofu-state"
     key                         = "tofu/state.tfstate"
     region                      = "bhs" # Your OVH region
     endpoint                    = "https://s3.bhs.io.cloud.ovh.net"
     skip_credentials_validation = true
     skip_region_validation      = true
     skip_metadata_api_check     = true
     skip_requesting_account_id  = true
     skip_s3_checksum            = true
  }
}

provider "ovh" {
  endpoint           = "ovh-ca"
  application_key    = var.application_key
  application_secret = var.application_secret
  consumer_key       = var.consumer_key
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
