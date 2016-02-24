provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# Variables need to be defined even though they are loaded from
# terraform.tfvars - see https://github.com/hashicorp/terraform/issues/2659
variable "aws_access_key" {}
variable "aws_secret_key" {}
