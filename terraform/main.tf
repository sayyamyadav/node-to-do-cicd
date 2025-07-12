provider "aws" {
  region = "us-east-1"
}

# Logging bucket for storing access logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "dummy-logging-bucket"
  acl    = "log-delivery-write"

  tags = {
    Name        = "log-bucket"
    Environment = "dev"
  }
}

# Main secured S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "my-devsecops-demo-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
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

# S3 to Lambda notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.example.id

  lambda_function {
    lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
    events              = ["s3:ObjectCreated:*"]
  }
}

# 🔐 Grant S3 permission to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = "my-function"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.example.arn
}

