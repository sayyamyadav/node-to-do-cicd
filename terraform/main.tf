provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-devsecops-demo-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "dummy-logging-bucket"
    target_prefix = "logs/"
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "alias/aws/s3"
      }
    }
  }

  tags = {
    Environment = "dev"
    Owner       = "devsecops"
  }
}

# ✅ Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

