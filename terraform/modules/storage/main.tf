resource "aws_s3_bucket" "restaurantpicker_index" {
  bucket = "${var.website_bucket_name}-index"
}

resource "aws_s3_bucket" "taste_finder_de" {
  bucket = var.website_bucket_name
}

resource "aws_s3_bucket" "www_taste_finder_de" {
  bucket = "www.${var.website_bucket_name}"
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.taste_finder_de.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "upload_html_objects" {
  for_each      = fileset("../../frontend/src/", "*.html")
  bucket        = aws_s3_bucket.taste_finder_de.id
  key           = each.value
  source        = "../../frontend/src/${each.value}"
  etag          = filemd5("../../frontend/src/${each.value}")
  content_type  = "text/html"
}

resource "aws_s3_object" "upload_css_objects" {
  for_each      = fileset("../../frontend/src/", "*.css")
  bucket        = aws_s3_bucket.taste_finder_de.id
  key           = each.value
  source        = "../../frontend/src/${each.value}"
  etag          = filemd5("../../frontend/src/${each.value}")
  content_type  = "text/css"
}

resource "aws_s3_object" "upload_js_objects" {
  for_each      = fileset("../../frontend/src/", "*.js")
  bucket        = aws_s3_bucket.taste_finder_de.id
  key           = each.value
  source        = "../../frontend/src/${each.value}"
  etag          = filemd5("../../frontend/src/${each.value}")
  content_type  = "text/javascript"
}

resource "aws_s3_object" "upload_png_objects" {
  for_each      = fileset("../../frontend/src/", "*.png")
  bucket        = aws_s3_bucket.taste_finder_de.id
  key           = each.value
  source        = "../../frontend/src/${each.value}"
  etag          = filemd5("../../frontend/src/${each.value}")
  content_type  = "image/png"
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.taste_finder_de.bucket
  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.website_bucket_name}"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.taste_finder_de.id
  policy = data.aws_iam_policy_document.taste_finder_de.json
}

data "aws_iam_policy_document" "taste_finder_de" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.website_bucket_name}",
      "arn:aws:s3:::${var.website_bucket_name}/*",
    ]
    actions = ["S3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
