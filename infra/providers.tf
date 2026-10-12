terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "kwames-terraform-state-bucket"
    key            = "proj-1/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "kwames-terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Restricts updates to minor versions only
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
