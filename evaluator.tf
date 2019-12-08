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
  -------------
  | CDN Setup |
  -------------
*/

# configure cloudfront SSL caching for Heroku shiny site
module "scenario_explorer_cdn" {
  source = "git@github.com:davidski/tf-cloudfrontssl.git"
  #source = "../../modules//cloudfronts3"
  providers                = { aws = aws.us-east-1, aws.bucket = aws}

  origin_domain_name     = heroku_app.evaluator.heroku_hostname
  origin_path            = ""
  origin_id              = "scenario_explorercdn"
  alias                  = "scenario-explorer.c.severski.net"
  acm_certificate_arn    = data.aws_acm_certificate.scenario_explorer.arn
  project                = var.project
  audit_bucket           = data.terraform_remote_state.main.outputs.auditlogs
  origin_protocol_policy = "http-only"
}

/*
  -------
  | DNS |
  -------
*/

resource "aws_route53_record" "evaluator_v4" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "scenario-explorer.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = 300

  records = [module.scenario_explorer_cdn.domain_name]
}

resource "aws_route53_record" "scenario_explorer" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "_1ea1132ea83df2cb5759a15889743903.scenario-explorer.c.severski.net."
  type    = "CNAME"
  ttl     = 7200

  records = ["_2104122a6d525c62813b2e5c4888a07c.acm-validations.aws."]
}

/*
resource "aws_route53_record" "evaluator_v6" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "scenario-explorer.${data.aws_route53_zone.zone.name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.evaluator.domain_name
    zone_id                = aws_cloudfront_distribution.evaluator.hosted_zone_id
    evaluate_target_health = false
  }
}
*/
