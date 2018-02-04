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
# Route 53 DNS

resource "aws_route53_zone" "sakemeshi-love" {
  name = "sakemeshi.love"
}

