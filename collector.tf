/*
  |-----------|
  | Collector |
  |-----------|
*/

resource "aws_route53_record" "collector_tidyrisk" {
  zone_id = "${aws_route53_zone.tidyrisk.zone_id}"
  name    = "collector.${aws_route53_zone.tidyrisk.name}"
  type    = "A"

  alias {
    name                   = "${module.collector_tidyrisk_cdn.domain_name}"
    zone_id                = "${module.collector_tidyrisk_cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

# S3 sourced evaluator.tidyrisk.org
module "collector_tidyrisk_cdn" {
  source = "git@github.com:davidski/tf-cloudfronts3.git"

  bucket_name              = "collector-tidyrisk"
  origin_id                = "collector_bucket"
  alias                    = ["collector.tidyrisk.org"]
  acm_certificate_arn      = "${aws_acm_certificate.tidyrisk.arn}"
  project                  = "${var.project}"
  audit_bucket             = "${data.terraform_remote_state.main.auditlogs}"
  minimum_protocol_version = "TLSv1.2_2018"
}
