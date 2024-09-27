terraform {
  required_version = ">= 1.7.4"

  backend "s3" {
    bucket = "fiap-health-med-tfstate"
    key    = "fiap-health-med-notifier.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43.0"
    }
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "fiap-health-med-tfstate"
    key    = "fiap-health-med-infra.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = data.terraform_remote_state.infra.outputs.region

  default_tags {
    tags = {
      environment = data.terraform_remote_state.infra.outputs.environment
      app         = data.terraform_remote_state.infra.outputs.resource_prefix
      project     = data.terraform_remote_state.infra.outputs.resource_prefix
    }
  }
}
