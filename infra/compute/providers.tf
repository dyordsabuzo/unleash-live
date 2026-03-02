provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed_by     = "terraform"
      description    = "compute infrastructure"
      workspace_name = terraform.workspace
      environment    = var.environment
    }
  }
}
