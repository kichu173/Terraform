# https://registry.terraform.io/providers/hashicorp/aws/latest/docs - USE PROVIDER
# just the place where you define which providers your project is using with which versisons.
# It works only for the providers who are part of terraform registry.
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.64.0"
    }
  }
}