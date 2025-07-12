provider "aws" {
  alias  = "aws-primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "aws-dr"
  region = "us-west-2"
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "test_dr_bucket" {
  provider = aws.aws-dr
  bucket   = "${var.bucket_name}-dr"
}

resource "aws_s3_bucket_versioning" "test_bucket_versioning" {
  bucket = aws_s3_bucket.test_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "test_dr_bucket_versioning" {
  provider = aws.aws-dr
  bucket = aws_s3_bucket.test_dr_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "dr_replication" {
  name_prefix = "replication"
  description = "Allow S3 to assume the role for replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "s3ReplicationAssume",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "dr_replication" {
  name_prefix = "replication"
  description = "Allows reading for replication."

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.test_bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.test_bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateTags",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.test_dr_bucket.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "dr_replication" {
  name       = "replication"
  roles      = [aws_iam_role.dr_replication.name]
  policy_arn = aws_iam_policy.dr_replication.arn
}

resource "aws_s3_bucket_replication_configuration" "dr_bucket_replication" {

  # Must have bucket versioning enabled first
  depends_on = [
    aws_s3_bucket_versioning.test_bucket_versioning,
    aws_s3_bucket_versioning.test_dr_bucket_versioning,
  ]

  role   = aws_iam_role.dr_replication.arn
  bucket = aws_s3_bucket.test_bucket.id

  rule {
    id     = "entire_bucket"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.test_dr_bucket.arn
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

