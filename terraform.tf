# vim: expandtab fenc=utf8 ff=unix ft=json

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
  version    = "~> 1.9.0"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"             # N. Virginia
}

# --------------------------------
# IAM User: sakemeshi-love-website-prod-writer

resource "aws_iam_user" "sakemeshi-love-website-prod-writer" {
  name          = "sakemeshi-love-website-prod-writer"
  force_destroy = false
}

# --------------------------------
# Route 53 DNS: sakemeshi.love

resource "aws_route53_zone" "sakemeshi-love" {
  name = "sakemeshi.love"
}

resource "aws_route53_record" "sakemeshi-love" {
  zone_id = "${aws_route53_zone.sakemeshi-love.zone_id}"
  name    = "sakemeshi.love"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.sakemeshi-love-website-prod-distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.sakemeshi-love-website-prod-distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

# --------------------------------
# ACM: sakemeshi.love, *.sakemeshi.love
# Need AWS provider v1.9 or more.
# see: https://github.com/terraform-providers/terraform-provider-aws/pull/2813

resource "aws_acm_certificate" "sakemeshi-love" {
  domain_name               = "sakemeshi.love"
  subject_alternative_names = ["*.sakemeshi.love"]
  validation_method         = "DNS"
}

# for 'sakemeshi.love'
resource "aws_route53_record" "certificate-validation-sakemeshi-love" {
  name    = "${aws_acm_certificate.sakemeshi-love.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.sakemeshi-love.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.sakemeshi-love.zone_id}"
  records = ["${aws_acm_certificate.sakemeshi-love.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

## for '*.sakemeshi.love'
#resource "aws_route53_record" "certificate-validation-_-sakemeshi-love" {
#  name = "${aws_acm_certificate.sakemeshi-love.domain_validation_options.1.resource_record_name}"
#  type = "${aws_acm_certificate.sakemeshi-love.domain_validation_options.1.resource_record_type}"
#  zone_id = "${aws_route53_zone.sakemeshi-love.zone_id}"
#  records = ["${aws_acm_certificate.sakemeshi-love.domain_validation_options.1.resource_record_value}"]
#  ttl = 60
#}

resource "aws_acm_certificate_validation" "sakemeshi-love" {
  certificate_arn = "${aws_acm_certificate.sakemeshi-love.arn}"

  validation_record_fqdns = [
    "${aws_route53_record.certificate-validation-sakemeshi-love.fqdn}",
    "${aws_route53_record.certificate-validation-sakemeshi-love.fqdn}",
  ]
}

# --------------------------------
# S3 buckets: sakemeshi.love

data "aws_iam_policy_document" "sakemeshi-love-website-prod-s3-policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.sakemeshi-love-website-prod-s3.arn}",
      "${aws_s3_bucket.sakemeshi-love-website-prod-s3.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${aws_cloudfront_origin_access_identity.sakemeshi-love-website-prod-origin_access_identity.iam_arn}",
      ]
    }
  }

  statement {
    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.sakemeshi-love-website-prod-s3.arn}",
      "${aws_s3_bucket.sakemeshi-love-website-prod-s3.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${aws_iam_user.sakemeshi-love-website-prod-writer.arn}",
      ]
    }
  }
}

resource "aws_s3_bucket" "sakemeshi-love-website-prod-s3" {
  bucket = "sakemeshi-love-website-prod-s3"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags {}

  force_destroy = true
}

resource "aws_s3_bucket_policy" "sakemeshi-love-website-prod-s3" {
  bucket = "${aws_s3_bucket.sakemeshi-love-website-prod-s3.id}"
  policy = "${data.aws_iam_policy_document.sakemeshi-love-website-prod-s3-policy.json}"
}

# --------------------------------
# CloudFront: sakemeshi.love

resource "aws_cloudfront_origin_access_identity" "sakemeshi-love-website-prod-origin_access_identity" {}

resource "aws_cloudfront_distribution" "sakemeshi-love-website-prod-distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"

  origin {
    domain_name = "${aws_s3_bucket.sakemeshi-love-website-prod-s3.website_endpoint}"
    origin_id   = "sakemeshi-love-prod-origin"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ToDo
  #logging_config {
  #}

  aliases = [
    "sakemeshi.love",
  ]
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "sakemeshi-love-prod-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.sakemeshi-love.arn}"
    ssl_support_method  = "sni-only"
  }
  tags = {}
}
