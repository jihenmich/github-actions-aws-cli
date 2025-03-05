provider "aws" {
  region = "eu-central-1"
}

resource "random_integer" "random" {
  min = 10000
  max = 99999
  keepers = {
    always_same = "static_value"
  }
}

# S3 bucket definition
resource "aws_s3_bucket" "website" {
  bucket = "techstarter-${random_integer.random.result}"
}

# Public access block configuration
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket ownership configuration
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Bucket ACL configuration
resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.website.id

  acl = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.site,
    aws_s3_bucket_public_access_block.site
  ]
}

# Bucket policy configuration
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Static website configuration
resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Output the website URL
output "website_url" {
  value = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.region}.amazonaws.com/"
}

# Define the region variable
variable "region" {
  default = "eu-central-1"
}
