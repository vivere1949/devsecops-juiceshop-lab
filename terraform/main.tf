provider "aws" {
  region = "us-east-1"
}

# Intentionally misconfigured S3 bucket - publicly readable
resource "aws_s3_bucket" "juice_shop_uploads" {
  bucket = "juice-shop-user-uploads-demo"
}

resource "aws_s3_bucket_public_access_block" "juice_shop_uploads" {
  bucket = aws_s3_bucket.juice_shop_uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Intentionally misconfigured security group - SSH open to the world
resource "aws_security_group" "juice_shop_server" {
  name        = "juice-shop-server-sg"
  description = "Security group for Juice Shop EC2 instance"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
