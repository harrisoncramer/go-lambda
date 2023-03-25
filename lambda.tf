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
