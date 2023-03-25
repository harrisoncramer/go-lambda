# go-lambda λ

Repository for a Golang HTTP JSON API running on AWS lambda and configured via Terraform.

## Setup

1. Install the AWS CLI.
2. Run `aws configure`
3. Install the terraform CLI.
4. Run `terraform init` in the root directory to download the providers.

## Development

1. Run `make` to build the binary.
2. Run `terraform apply` to apply the changes.
