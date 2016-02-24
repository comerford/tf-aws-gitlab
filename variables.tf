#
# General variables file
#
# Variables need to be defined even though they are loaded from
# terraform.tfvars - see https://github.com/hashicorp/terraform/issues/2659

# Ubuntu 14.04 LTS AMIs (HVM) will be used (note: you have to agree to the TOU)

variable "amazon_amis" {
  default = {
    eu-west-1 = "ami-b265c7c1"
    eu-central-1 = "ami-ad8894c1"
    us-west-2 = "ami-13988772"
    us-east-1 = "ami-663a6e0c"
    us-west-1 = "ami-b885eed8"
    ap-northeast-1 = "ami-575b6e39"
  }
}

variable "tag_Owner" {
    default = "owner@example.com"
}

variable "aws_region" {
    default = "us-west-2"
}

variable "account_vpc" {
    default = "vpc-11111111"
}
variable "host_key_name" {
    default = "host_keypair"
}
variable "private_key_path" {
    default = "~/.ssh/keypair.pem"
}
variable "instance_size" {
    default = "m3.medium"
}
variable "elb_ssl_cert" {
    default = "arn:aws:iam::111111111111:server-certificate/gitlab.example.com"
}
variable "host_subnet" {
    default = "subnet-FFFFFFFF"
}
variable "bucket_name" {
    default = "mybucket"
}
variable "elb_subnet" {
    default = "subnet-EEEEEEEE"
}
variable "elb_whitelist" {
    default = "198.51.100.0/24,203.0.113.0/24"
}
variable "bucket_name" {
    default = "gitlab-example-com"
}
