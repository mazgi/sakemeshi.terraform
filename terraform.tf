# vim: expandtab fenc=utf8 ff=unix ft=json

# --------------------------------
# Terraform configuration

terraform {
  required_version = ">= 0.10.0"
  backend "s3" {
    bucket = "mazgi-sakemeshi-aws-terraform"
    key    = "global/tfstate"
    region = "us-east-1" # N. Virginia
  }
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "us-east-1" # N. Virginia
}

# --------------------------------
# IAM User: sakemeshi-love-website-prod-writer

resource "aws_iam_user" "sakemeshi-love-website-prod-writer" {
  name = "sakemeshi-love-website-prod-writer"
  force_destroy = false
}

# --------------------------------
# Route 53 DNS: sakemeshi.love

resource "aws_route53_zone" "sakemeshi-love" {
  name = "sakemeshi.love"
}

# --------------------------------
# S3 buckets: sakemeshi.love

resource "aws_s3_bucket" "sakemeshi-love-website-prod-s3" {
  bucket = "sakemeshi-love-website-prod-s3"
  acl = "public-read"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::sakemeshi-love-website-prod-s3",
        "arn:aws:s3:::sakemeshi-love-website-prod-s3/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${var.aws_account_id}:user/sakemeshi-love-website-prod-writer"
        ]
      },
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::sakemeshi-love-website-prod-s3",
        "arn:aws:s3:::sakemeshi-love-website-prod-s3/*"
      ]
    }
  ]
}
POLICY
    website {
      index_document = "index.html"
      error_document = "404.html"
    }
    tags {
    }
    force_destroy = true
}

# --------------------------------
# CloudFront: sakemeshi.love

resource "aws_cloudfront_origin_access_identity" "sakemeshi-love-website-prod-origin_access_identity" {
}

resource "aws_cloudfront_distribution" "sakemeshi-love-website-prod-distribution" {
  origin {
    #domain_name = "${aws_s3_bucket.sakemeshi-love-website-prod-s3.website_endpoint}"
    domain_name = "${aws_s3_bucket.sakemeshi-love-website-prod-s3.bucket_domain_name}"
    origin_id = "sakemeshi-love-prod-origin"
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.sakemeshi-love-website-prod-origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  # ToDo
  #logging_config {
  #}

  aliases = [
    "sakemeshi.love"
  ]

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "sakemeshi-love-prod-origin"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
