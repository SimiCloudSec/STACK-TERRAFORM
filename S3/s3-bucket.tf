###############################################################
# NEW CROSS-REGION REPLICATION (CRR) – S3 SETUP
# Source: stackprog (us-east-1)
# Destination: simiautomation (us-east-2)
###############################################################

locals {
  timestamp     = formatdate("YYYYMMDDhhmmss", timestamp())
  source_bucket = "stackprog-crr-source-${local.timestamp}"
  dest_bucket   = "simiauto-crr-dest-${local.timestamp}"
}

# ---------------- SOURCE BUCKET ----------------
resource "aws_s3_bucket" "source_bucket" {
  provider = aws.source
  bucket   = local.source_bucket
}

# Enable versioning
resource "aws_s3_bucket_versioning" "source_versioning" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "source_encryption" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "source_block" {
  provider                  = aws.source
  bucket                    = aws_s3_bucket.source_bucket.id
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
}

# Enable transfer acceleration
resource "aws_s3_bucket_accelerate_configuration" "source_accel" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.id
  status   = "Enabled"
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "source_website" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Logging (requires target bucket in same account)
resource "aws_s3_bucket" "log_bucket" {
  provider = aws.source
  bucket   = "stackprog-log-${local.timestamp}"
}

resource "aws_s3_bucket_logging" "source_logging" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# Lifecycle rule
resource "aws_s3_bucket_lifecycle_configuration" "source_lifecycle" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ---------------- DESTINATION BUCKET ----------------
resource "aws_s3_bucket" "dest_bucket" {
  provider = aws.destination
  bucket   = local.dest_bucket
}

resource "aws_s3_bucket_versioning" "dest_versioning" {
  provider = aws.destination
  bucket   = aws_s3_bucket.dest_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------- IAM ROLE FOR REPLICATION ----------------
resource "aws_iam_role" "replication_role" {
  provider = aws.source
  name     = "s3-crr-role-${local.timestamp}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  provider = aws.source
  role     = aws_iam_role.replication_role.id
  policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetReplicationConfiguration", "s3:ListBucket"],
        Resource = [aws_s3_bucket.source_bucket.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        Resource = ["${aws_s3_bucket.source_bucket.arn}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Resource = ["${aws_s3_bucket.dest_bucket.arn}/*"]
      }
    ]
  })
}

# ---------------- REPLICATION CONFIGURATION ----------------
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.source
  depends_on = [
    aws_s3_bucket_versioning.source_versioning,
    aws_s3_bucket_versioning.dest_versioning
  ]
  bucket = aws_s3_bucket.source_bucket.id

  role = aws_iam_role.replication_role.arn

  rule {
    id     = "crr-rule-${local.timestamp}"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dest_bucket.arn
      storage_class = "STANDARD"
    }
  }
}
