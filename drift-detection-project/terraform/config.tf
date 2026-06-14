# Enable AWS Config Recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "${var.project_name}-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# S3 bucket for AWS Config logs
resource "aws_s3_bucket" "config_bucket" {
  bucket        = "${var.project_name}-config-logs-${random_id.bucket_id.hex}"
  force_destroy = true

  tags = {
    Name      = "${var.project_name}-config-logs"
    ManagedBy = "Terraform"
  }
}

# S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Delivery channel for AWS Config
resource "aws_config_delivery_channel" "channel" {
  name           = "${var.project_name}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  depends_on = [aws_config_configuration_recorder.recorder]
}

# Start the Config recorder
resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.channel]
}

# AWS Config Rule - Check EC2 tags
resource "aws_config_config_rule" "ec2_tag_rule" {
  name = "${var.project_name}-ec2-required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Instance"]
  }

  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = "Production"
    tag2Key   = "ManagedBy"
    tag2Value = "Terraform"
  })

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

# AWS Config Rule - Check Security Group
resource "aws_config_config_rule" "sg_rule" {
  name = "${var.project_name}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  input_parameters = jsonencode({
    blockedPort1 = "22"
  })

  depends_on = [aws_config_configuration_recorder_status.recorder_status]
}

# IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy to Config role
resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Allow Config to access S3
resource "aws_iam_role_policy" "config_s3_policy" {
  name = "${var.project_name}-config-s3-policy"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
      }
    ]
  })
}
