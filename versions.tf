terraform {
  required_version = ">= 0.12.0, < 0.14.0"
  required_providers {
    random = {
      version = "~> 2.2"
    }
    heroku = {
      source  = "heroku/heroku"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}