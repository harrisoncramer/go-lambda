terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

# This is the role that our function will adopt when running
# The first field, resource type, is required to match terraform specs.
# The second field, reference name, is just our own name for the resource.
resource "aws_iam_role" "lambda_role" {
  name = "hello_world_lambda_role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
  EOF
}

# This is the policy that will be attached to the role
resource "aws_iam_policy" "lambda_policy" {
  name        = "hello_world_lambda_policy"
  path        = "/"
  description = "IAM policy for hello world lambda function"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
  EOF
}

# This is the actual attachment of the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Use a zip file of the binary to upload and run
data "archive_file" "hello_world_archive" {
  type        = "zip"
  source_file = "bin/hello_world"
  output_path = "hello_world.zip"
}

# Create the lambda function, pointing it at the binary
resource "aws_lambda_function" "hello_world" {
  function_name    = "hello_world"
  filename         = data.archive_file.hello_world_archive.output_path
  source_code_hash = data.archive_file.hello_world_archive.output_base64sha256
  handler          = "hello_world"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10
}

# In Amazon API Gateway, you build a REST API as a collection of programmable entities known as API Gateway resources. For example, you use a RestApi resource to represent an API that can contain a collection of Resource entities. Each Resource entity can in turn have one or more Method resources.

# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name = "hello_world_api"
}

# Create a resource within the REST API
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

# Create a method for the resource (in this case, a GET resource)
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Next create an Integration resource to integrate the above method with a backend endpoint, also known as the integration endpoint, by forwarding the incoming request to a specified integration endpoint URI.
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_world.invoke_arn
}

# Gives an external source (in our case the API gateway) permission to access the Lambda function.
resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
}

output "url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

