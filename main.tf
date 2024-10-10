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
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# resource "aws_vpc" "bedrock_vpc" {
#     cidr_block       = "10.0.0.0/16"
#     instance_tenancy = "default"

#     tags = {
#         Name = "bedrock_vpc"
#     }  
# }

