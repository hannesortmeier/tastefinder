output "index_bucket" {
  description = "S3 bucket containing indexed places records"
  value = aws_s3_bucket.restaurantpicker_index
}

output "website_bucket" {
  description = "S3 static website bucket domain"
  value = aws_s3_bucket.taste_finder_de
}