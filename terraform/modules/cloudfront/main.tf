resource "aws_acm_certificate" "taste_finder_de" {
  provider          = aws.us-east-1
  domain_name       = var.website_bucket_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "taste_finder_de" {
  for_each = {
    for dvo in aws_acm_certificate.taste_finder_de.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "taste_finder_de" {
  provider          = aws.us-east-1
  certificate_arn         = aws_acm_certificate.taste_finder_de.arn
  validation_record_fqdns = [for record in aws_route53_record.taste_finder_de : record.fqdn]
}


resource "aws_cloudfront_distribution" "taste_finder_de" {
  enabled = true

  origin {
    origin_id                = "${var.website_bucket_name}-origin"
    domain_name              = var.website_bucket_domain
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  aliases = [var.website_bucket_name]

  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "${var.website_bucket_name}-origin"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 10
    default_ttl            = 1400
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.taste_finder_de.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  price_class = "PriceClass_100"

}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-${var.website_bucket_name}.s3.amazonaws.com"
}