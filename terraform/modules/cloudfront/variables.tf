variable "website_bucket_name" {
  description = "Name of the website bucket"
  type = string
}

variable "website_bucket_domain" {
  description = "Domain name of the website bucket"
  type = string
}

variable "hosted_zone_id" {
  description = "Hosted zone id for the domain"
  type = string
}
