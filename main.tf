provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  version = "~> 2.7"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

provider "aws" {
  alias = "us-east-1"
  region  = "us-east-1"
  profile = var.aws_profile

  version = "~> 2.7"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

# Data source for the availability zones in this zone
data "aws_availability_zones" "available" {}

# Data source for current account number
data "aws_caller_identity" "current" {}

# Data source for ACM certificate
data "aws_acm_certificate" "scenario_explorer" {
  provider = aws.us-east-1
  domain   = "scenario-explorer.c.severski.net"
}

# Data source for main infrastructure state
data "terraform_remote_state" "main" {
  backend = "s3"

  config = {
    bucket  = "infrastructure-severski"
    key     = "terraform/infrastructure.tfstate"
    region  = "us-west-2"
    encrypt = "true"
  }
}

/*
  --------------
  | Heroku App |
  --------------
*/

provider "heroku" {
  version = "~> 2.0"
}
