provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

provider "aws.east_1" {
  region  = "us-east-1"
  profile = "${var.aws_profile}"

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
  provider = "aws.east_1"
  domain   = "scenario-explorer.c.severski.net"
}

# Data source for main infrastructure state
data "terraform_remote_state" "main" {
  backend = "s3"

  config {
    bucket  = "infrastructure-severski"
    key     = "terraform/infrastructure.tfstate"
    region  = "us-west-2"
    encrypt = "true"
  }
}

# Find our target zone by id
data "aws_route53_zone" "zone" {
  zone_id = "${data.terraform_remote_state.main.severski_zoneid}"
}

/*
  --------------
  | Heroku App |
  --------------
*/

provider "heroku" {}

# Create a new Heroku app
resource "heroku_app" "evaluator" {
  name   = "scenario-explorer"
  region = "us"

  config_vars {
    BUILDPACK_URL = "http://github.com/virtualstaticvoid/heroku-buildpack-r.git#cedar-14-chroot"
  }
}

/*
  -------------
  | CDN Setup |
  -------------
*/

# configure cloudfront SSL caching for Heroku shiny site
module "scenario_explorer_cdn" {
  source = "github.com/davidski/tf-cloudfrontssl"

  origin_domain_name     = "${heroku_app.evaluator.heroku_hostname}"
  origin_path            = ""
  origin_id              = "scenario_explorercdn"
  alias                  = "scenario-explorer.c.severski.net"
  acm_certificate_arn    = "${data.aws_acm_certificate.scenario_explorer.arn}"
  project                = "${var.project}"
  audit_bucket           = "${data.terraform_remote_state.main.auditlogs}"
  origin_protocol_policy = "http-only"
}

/*
  -------
  | DNS |
  -------
*/

resource "aws_route53_record" "evaluator_v4" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "scenario-explorer.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = 300

  records = ["${module.scenario_explorer_cdn.domain_name}"]
}

resource "aws_route53_record" "scenario_explorer" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "_1ea1132ea83df2cb5759a15889743903.scenario-explorer.c.severski.net."
  type    = "CNAME"
  ttl     = 7200

  records = ["_2104122a6d525c62813b2e5c4888a07c.acm-validations.aws."]
}

/*
resource "aws_route53_record" "evaluator_v6" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "scenario-explorer.${data.aws_route53_zone.zone.name}"
  type    = "AAAA"

  alias {
    name                   = "${aws_cloudfront_distribution.evaluator.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.evaluator.hosted_zone_id}"
    evaluate_target_health = false
  }
}
*/

