# In Amazon API Gateway, you build a REST API as a collection of programmable entities known as API Gateway resources. For example, you use a RestApi resource to represent an API that can contain a collection of Resource entities. Each Resource entity can in turn have one or more Method resources.
# See this tutorial: https://registry.terraform.io/providers/hashicorp/aws/2.34.0/docs/guides/serverless-with-aws-lambda-and-api-gateway

# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "go_lambda_api" {
  name        = "go_lambda_api"
  description = "The API gateway for our hello world application. We could add more functions in the future if we wanted to."
}

# Create a resource within the REST API that sends requests to /test/hello to our lambda
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.go_lambda_api.id
  parent_id   = aws_api_gateway_rest_api.go_lambda_api.root_resource_id
  path_part   = "hello"
}
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.go_lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Create an Integration resource to integrate the proxy with our backend endpoint, our lambda.
# Each method on an API gateway resource has an integration which specifies where incoming requests are routed. Add the following configuration to specify that requests to this method should be sent to the Lambda function.
# The type parameter specifies that the integration type is AWS_PROXY, which means that the entire request is passed to the Lambda function. The uri parameter specifies the ARN of the Lambda function.
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.go_lambda_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Call the lambda
  uri                     = aws_lambda_function.go_lambda.invoke_arn
}

# By default any two AWS services have no access to one another, until access is explicitly granted. 
# For Lambda functions, access is granted using the aws_lambda_permission resource. 
# This lets the API gateway have access to the function.
resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.go_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.go_lambda_api.execution_arn}/*/*"
}

# Finally, we need to deploy the API gateway in order to expose the API at a URL
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration] # Wait for the API gateway integration to create
  rest_api_id = aws_api_gateway_rest_api.go_lambda_api.id
  stage_name  = "test"
}

# To hit the endpoint, use the below URL output followed by the stage name, in this case "/test"
output "url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

