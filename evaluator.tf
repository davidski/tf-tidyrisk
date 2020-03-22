/*
  |-----------|
  | Evaluator |
  |-----------|
*/

resource "aws_route53_record" "evaluator_tidyrisk" {
  zone_id = aws_route53_zone.tidyrisk.zone_id
  name    = "evaluator.${aws_route53_zone.tidyrisk.name}"
  type    = "A"

  alias {
    name                   = module.evaluator_tidyrisk_cdn.domain_name
    zone_id                = module.evaluator_tidyrisk_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# S3 sourced evaluator.tidyrisk.org
module "evaluator_tidyrisk_cdn" {
  source = "git@github.com:davidski/tf-cloudfronts3.git"
  #source = "../../modules//cloudfronts3"

  providers                = { aws = aws.us-east-1, aws.bucket = aws}
  bucket_name         = "evaluator-tidyrisk"
  origin_id           = "evaluator_bucket"
  alias               = ["evaluator.tidyrisk.org"]
  acm_certificate_arn = aws_acm_certificate.tidyrisk.arn
  project             = var.project
  audit_bucket        = data.terraform_remote_state.main.outputs.auditlogs
  minimum_protocol_version = "TLSv1.2_2018"
}



/*
  ---------------------
  | Scenario Explorer |
  ---------------------
*/


/*
# Scenario Explorer is hosted in Heroku
resource "heroku_app" "evaluator" {
  name   = "scenario-explorer"
  region = "us"

  config_vars = {
    BUILDPACK_URL = "http://github.com/virtualstaticvoid/heroku-buildpack-r.git#cedar-14-chroot"
  }
}

# configure cloudfront SSL caching for Heroku shiny site
module "scenario_explorer_cdn" {
  source = "git@github.com:davidski/tf-cloudfrontssl.git"
  #source = "../../modules//cloudfronts3"
  providers                = { aws = aws.us-east-1, aws.bucket = aws}

  origin_domain_name     = heroku_app.evaluator.heroku_hostname
  origin_path            = ""
  origin_id              = "scenario_explorercdn"
  alias                  = "scenario-explorer.tidyrisk.org"
  acm_certificate_arn    = aws_acm_certificate.tidyrisk.arn
  project                = var.project
  audit_bucket           = data.terraform_remote_state.main.outputs.auditlogs
  origin_protocol_policy = "http-only"
}

resource "aws_route53_record" "scenario_explorer" {
  zone_id = aws_route53_zone.tidyrisk.zone_id
  name    = module.scenario_explorer_cdn.domain_name
  type    = "A"

  alias {
    name                   = module.scenario_explorer_cdn.domain_name
    zone_id                = module.scenario_explorer_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
*/