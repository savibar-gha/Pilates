terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Opcional: descomentar para guardar el estado en S3 en vez de local
  # backend "s3" {
  #   bucket = "TU-BUCKET-DE-ESTADO-TERRAFORM"
  #   key    = "maspilates-encuesta/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
