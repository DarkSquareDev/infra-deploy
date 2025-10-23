provider "aws" {
  region = "us-east-1"
}

locals {
  lambda_name = "wjpearce_lambda"
  handler     = "test_script.lambda_handler"
  runtime     = "python3.12"
  timeout     = 10
}

variable "lambda_src_path" {
  description = "Path to the Lambda source file"
  type        = string
  default     = "./lambda/test_script.py"
}

# Package Lambda source into a ZIP file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.lambda_src_path
  output_path = "./lambda_package.zip"
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM policy for CloudWatch logging
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  description = "Allow Lambda to log to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name    = local.lambda_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = local.handler
  runtime          = local.runtime
  timeout          = local.timeout
}
