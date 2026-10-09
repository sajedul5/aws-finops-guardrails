terraform {
  required_version = ">= 1.10.0" # S3 native state locking (use_lockfile)

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

  # Remote state. Uncomment and fill in after creating the bucket (versioning on, public access blocked).
  # backend "s3" {
  #   bucket       = "my-org-terraform-state"
  #   key          = "finops-guardrails/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project    = "aws-finops-guardrails"
      ManagedBy  = "terraform"
      Owner      = var.owner
      CostCenter = var.cost_center
    }
  }
}
