# --------------------------------
# Terraform configuration

terraform {
  required_version = "~> 0.10"

  backend "s3" {
    bucket = "mazgi-sakemeshi-aws-terraform"
    key    = "global/tfstate"
    region = "us-east-1"                     # N. Virginia
  }
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"             # N. Virginia
}

# --------------------------------
# Route 53 DNS:

resource "aws_route53_zone" "website-zone" {
  name = "${var.website_domain_name}"
}

# --------------------------------
# Module: aws-static-website

module "static-website" {
  source       = "mazgi/static-website/aws"
  website_name = "${var.website_name}"

  website_domain = {
    name    = "${var.website_domain_name}"
    zone_id = "${aws_route53_zone.website-zone.zone_id}"
  }
}
