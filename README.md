# go-lambda λ

Repository for a Golang HTTP JSON API running on AWS lambda and configured via Terraform.

## Setup

1. Install the <a href="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html">AWS CLI</a>.
2. Create an IAM role with adequate permissions in AWS.
3. Run the `aws configure` command. 
4. Run `export AWS_PROFILE=your_configured_user` to source the identity into the shell.
3. Install the <a href="https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli">Terraform CLI</a>.
4. Run `terraform init` in the root directory to download the providers.

## Development

1. Run `make` to build the binary.
2. Change into the infrastructure folder: `cd infrastructure`
2. Run `terraform apply` to apply the changes and upload the binary. Confirm.
3. POST to the endpoint: `curl -X POST https://mq4s9j0l8b.execute-api.us-east-2.amazonaws.com/test/hello -d '{ "name": "Harry" }'`
4. Rip down the infrastructure (still in the infrastructure folder): `terraform destroy`

## Helper Script
1. Run `. bin/deploy` from the root repo (make sure to run within the existing shell with `.` or `source`)
3. curl -X POST "$TF_URL/hello" -d '{ "name": "Harry" }'
