terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Pin the provider so upgrades are explicit and controlled.  See
      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#version for details.
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  # Region is parameterised to allow deploying into different regions from a
  # single code base.  Provide a value in your tfvars file or via TF_VAR_region.
  region = var.region
}

# CloudFront and WAF resources must be created in the us-east-1 (global)
# partition.  This alias is used for the WAF resource and could be used
# for ACM certificates or other global services in the future.
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}