resource "aws_s3_bucket" "nix_cache" {
  bucket = var.cache_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "nix_cache" {
  bucket = aws_s3_bucket.nix_cache.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "nix_cache" {
  depends_on = [aws_s3_bucket_ownership_controls.nix_cache]

  bucket = aws_s3_bucket.nix_cache.id
  acl    = "private"
}

output "nix_cache_bucket_name" {
  value = aws_s3_bucket.nix_cache.id
}
