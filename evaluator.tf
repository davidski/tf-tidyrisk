/*
  |-----------|
  | Evaluator |
  |-----------|
*/

# Data source for ACM certificate
data "aws_acm_certificate" "evaluator_docs" {
  provider = "aws.east_1"
  domain   = "evaluator.severski.net"
}

# Github sourced evaluator.severski.net
module "evaluatorcdn" {
  source = "git@github.com:davidski/tf-cloudfrontssl.git"

  origin_domain_name  = "davidski.github.io"
  origin_path         = "/evaluator"
  origin_id           = "evaluatorcdn"
  alias               = "evaluator.severski.net"
  acm_certificate_arn = "${data.aws_acm_certificate.evaluator_docs.arn}"
  project             = "${var.project}"
  audit_bucket        = "${data.terraform_remote_state.main.auditlogs}"
}

resource "aws_route53_record" "evaluator_tidyrisk" {
  zone_id = "${aws_route53_zone.tidyrisk.zone_id}"
  name    = "evaluator.${aws_route53_zone.tidyrisk.name}"
  type    = "A"

  alias {
    name                   = "${module.evaluator_tidyrisk_cdn.domain_name}"
    zone_id                = "${module.evaluator_tidyrisk_cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

# S3 sourced evaluator.tidyrisk.org
module "evaluator_tidyrisk_cdn" {
  source = "git@github.com:davidski/tf-cloudfronts3.git"

  bucket_name         = "evaluator-tidyrisk"
  origin_id           = "evaluator_bucket"
  alias               = ["evaluator.tidyrisk.org"]
  acm_certificate_arn = "${aws_acm_certificate_validation.tidyrisk.certificate_arn}"
  project             = "${var.project}"
  audit_bucket        = "${data.terraform_remote_state.main.auditlogs}"
  minimum_protocol_version = "TLSv1.2_2018"
}
