terraform {
  backend "s3" {
    region         = "ap-southeast-2"
    bucket         = "terraform-backend-unleash-live-test"
    dynamodb_table = "terraform-backend-unleash-live"
    encrypt        = true
    key            = "auth/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
  }

  required_version = ">= 1.5.0"
}
