# Create a specific user for S3 management if those keys weren't provided
resource "ovh_cloud_project_user" "s3_manager" {
  service_name = var.ovh_project_id
  description  = "User for S3 Object Storage management"
  # role         = "administrator" # Or specific S3 roles if available in your region
}

resource "ovh_cloud_project_user_s3_credential" "s3_keys" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.s3_manager.id
}

# The bucket remains managed via the AWS provider (S3 compatible)
resource "aws_s3_bucket" "nix_cache" {
  bucket        = var.cache_bucket_name
  force_destroy = true
}

# resource "aws_s3_bucket_ownership_controls" "nix_cache" {
#   bucket = aws_s3_bucket.nix_cache.id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }

# --- Tofu State Bucket ---
resource "aws_s3_bucket" "tofu_state" {
  bucket        = var.tofu_state_bucket_name
  force_destroy = false # Protect the state bucket from accidental deletion
}

# resource "aws_s3_bucket_ownership_controls" "tofu_state" {
#   bucket = aws_s3_bucket.tofu_state.id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }


output "nix_cache_bucket_name" {
  value = aws_s3_bucket.nix_cache.id
}

output "generated_s3_access_key" {
  value     = ovh_cloud_project_user_s3_credential.s3_keys.access_key_id
  sensitive = true
}

output "generated_s3_secret_key" {
  value     = ovh_cloud_project_user_s3_credential.s3_keys.secret_access_key
  sensitive = true
}
