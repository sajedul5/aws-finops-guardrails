terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }
}

provider "aws" {
  region = var.region

  # Every resource this example creates is tagged, so FinOps costs are themselves attributable.
  default_tags {
    tags = {
      Project   = "aws-finops-guardrails"
      ManagedBy = "terraform"
      Owner     = var.owner
    }
  }
}
