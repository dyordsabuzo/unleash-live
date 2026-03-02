provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed_by     = "terraform"
      description    = "authorizer infrastructure"
      workspace_name = terraform.workspace
      environment    = var.environment
    }
  }
}
