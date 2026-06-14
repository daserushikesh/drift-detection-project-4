resource "aws_s3_bucket" "project_bucket" {
  bucket = "${var.project_name}-bucket-${random_id.bucket_id.hex}"

  tags = {
    Name      = "${var.project_name}-bucket"
    ManagedBy = "Terraform"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "project_bucket_versioning" {
  bucket = aws_s3_bucket.project_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "project_bucket_encryption" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
