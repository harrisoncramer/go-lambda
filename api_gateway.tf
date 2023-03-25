# In Amazon API Gateway, you build a REST API as a collection of programmable entities known as API Gateway resources. For example, you use a RestApi resource to represent an API that can contain a collection of Resource entities. Each Resource entity can in turn have one or more Method resources.
# See this tutorial: https://registry.terraform.io/providers/hashicorp/aws/2.34.0/docs/guides/serverless-with-aws-lambda-and-api-gateway

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
  depends_on  = [aws_api_gateway_integration.integration] # Wait for the API gateway integration to create
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
}

output "url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

