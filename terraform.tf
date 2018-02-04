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

resource "aws_s3_bucket" "sakemeshi-love-website-prod" {
  bucket = "sakemeshi-love-website-prod"
  acl = "public-read"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
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
        "arn:aws:s3:::sakemeshi-love-website-prod",
        "arn:aws:s3:::sakemeshi-love-website-prod/*"
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
