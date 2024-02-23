terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    key = "opentofu.tfstate"
  }
}

provider "aws" {
  region = "eu-west-1"
}
