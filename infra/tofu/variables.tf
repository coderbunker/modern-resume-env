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

variable "ovh_project_id" {
  type        = string
  description = "The OVH Public Cloud Project ID (Service Name)"
}

variable "s3_access_key" {
  type        = string
  description = "S3 Access Key ID (Optional if generating via OVH provider)"
  sensitive   = true
  default     = null
}

variable "s3_secret_key" {
  type        = string
  description = "S3 Secret Access Key (Optional if generating via OVH provider)"
  sensitive   = true
  default     = null
}

variable "cache_bucket_name" {
  type        = string
  description = "Name of the Nix cache bucket"
  default     = "modern-resume-nix-cache"
}

variable "tofu_state_bucket_name" {
  type        = string
  description = "Name of the bucket to store Tofu state"
  default     = "modern-resume-tofu-state"
}

variable "application_key" {
  type        = string
  description = "OVH Application Key"
  sensitive   = true
}

variable "application_secret" {
  type        = string
  description = "OVH Application Secret"
  sensitive   = true
}

variable "consumer_key" {
  type        = string
  description = "OVH Consumer Key"
  sensitive   = true
  default     = null
}
