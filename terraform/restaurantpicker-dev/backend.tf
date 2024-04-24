terraform {
  backend "s3" {
    bucket = "restaurantpicker-dev-tfstate"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
  }
}