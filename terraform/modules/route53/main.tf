resource "aws_route53_record" "taste_finder_de_a" {
  zone_id = var.hosted_zone_id
  name = var.website_bucket_name
  type = "A"
  alias {
    name = var.cloudfront_domain_name
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}