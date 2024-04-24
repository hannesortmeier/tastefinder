module "storage" {
  source     = "../modules/storage"

  website_bucket_name    = var.domain_name
  hosted_zone_id         = var.hosted_zone_id
  cloudfront_domain_name = module.cloudfront.cloudfront_domain_name
}

module "lambda" {
  source          = "../modules/lambda"
  project_version = var.project_version

  index_bucket_arn  = module.storage.index_bucket.arn
  index_bucket_name = module.storage.index_bucket.id
}

module "cloudfront" {
  source = "../modules/cloudfront"

  website_bucket_domain = module.storage.website_bucket.bucket_domain_name
  website_bucket_name   = var.domain_name
  hosted_zone_id        = var.hosted_zone_id
}

module "route53" {
  source                 = "../modules/route53"
  hosted_zone_id         = var.hosted_zone_id
  website_bucket_name    = var.domain_name
  cloudfront_domain_name = module.cloudfront.cloudfront_domain_name
}
