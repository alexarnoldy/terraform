provider "aws" {
  region = var.region
#  profile = var.profile
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
#    bucket = "" # This should match the unique name of the bucket you create as specified in the README steps.
#    key = ""
#    region = ""
    encrypt = true
  }
}
