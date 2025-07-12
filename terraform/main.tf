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
        sse_algorithm = "AES256"
      }
    }
  }
}

