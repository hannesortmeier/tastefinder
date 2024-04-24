output "fetch_index_lambda" {
  description = "Lambda function that fetches index files from s3"
  value = aws_lambda_function.fetch_index
}