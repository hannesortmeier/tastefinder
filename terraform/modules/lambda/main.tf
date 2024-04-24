data "archive_file" "fetch-index" {
  type        = "zip"
  source_dir = "../../lambda/fetch-index/target/lambda/fetch-index/"
  output_path = "../../lambda/fetch-index/target/lambda/fetch-index.zip"
}

resource "aws_lambda_function" "fetch_index" {
  function_name = "fetch-index"
  runtime = "provided.al2"
  handler = "bootstrap"
  filename = data.archive_file.fetch-index.output_path
  role = aws_iam_role.fetch_index.arn
  source_code_hash = data.archive_file.fetch-index.output_base64sha256
  environment {
    variables = {
      BUCKET_NAME = var.index_bucket_name
    }
  }
}

resource "aws_iam_role" "fetch_index" {
  name = "fetch-index-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "fetch_index" {
  name = "fetch-index-lambda-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = "${var.index_bucket_arn}/*"
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-policy-attachment"
  policy_arn = aws_iam_policy.fetch_index.arn
  roles      = [aws_iam_role.fetch_index.name]
}

resource "aws_lambda_function_url" "endpoint" {
  function_name      = aws_lambda_function.fetch_index.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    max_age           = 86400
  }
}