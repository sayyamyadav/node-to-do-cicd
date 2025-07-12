resource "aws_s3_bucket" "example" {
  bucket = "my-devsecops-demo-bucket"
  acl    = "private"
}

