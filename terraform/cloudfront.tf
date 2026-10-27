locals {
  s3_origin_id     = "architecture-site-s3"
  top_level_domain = var.domain_name
  aliases          = ["${var.subdomain}.${var.domain_name}"]
}

resource "aws_cloudfront_origin_access_control" "images" {
  name                              = "arch-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_acm_certificate" "cert" {
  region      = "us-east-1"
  domain      = "*.${var.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_cloudfront_distribution" "s3_software_arch_distribution" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = local.aliases
  price_class     = var.price_class

  default_root_object = var.default_root_object

  origin {
    domain_name              = aws_s3_bucket.software_arch_map.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.images.id
    origin_id                = local.s3_origin_id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_route53_zone" "software_arch" {
  name         = local.top_level_domain
  private_zone = false
}

resource "aws_route53_record" "cloudfront_a_record" {
  for_each = toset(local.aliases)
  zone_id  = data.aws_route53_zone.software_arch.zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_software_arch_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_software_arch_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_aaaa_record" {
  for_each = toset(local.aliases)
  zone_id  = data.aws_route53_zone.software_arch.zone_id
  name     = each.value
  type     = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_software_arch_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_software_arch_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

