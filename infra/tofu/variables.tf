variable "s3_region" {
  type        = string
  description = "The region for the S3 bucket (e.g., bhs)"
  default     = "bhs"
}

variable "s3_endpoint" {
  type        = string
  description = "The endpoint for the S3 bucket (e.g., s3.bhs.io.cloud.ovh.net)"
  default     = "s3.bhs.io.cloud.ovh.net"
}

variable "s3_access_key" {
  type        = string
  description = "S3 Access Key ID"
  sensitive   = true
}

variable "s3_secret_key" {
  type        = string
  description = "S3 Secret Access Key"
  sensitive   = true
}

variable "cache_bucket_name" {
  type        = string
  description = "Name of the Nix cache bucket"
  default     = "modern-resume-nix-cache"
}
