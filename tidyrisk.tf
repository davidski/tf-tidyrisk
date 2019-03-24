# Data source for ACM certificate
data "aws_acm_certificate" "tidyrisk" {
  provider = "aws.east_1"
  domain   = "tidyrisk.org"
  statuses = ["ISSUED", "PENDING_VALIDATION"]
}

/*
  ------------------------
  | TidyRisk DNS Records |
  ------------------------
*/

resource "aws_route53_zone" "tidyrisk" {
  name = "tidyrisk.org."

  tags {
    managed_by = "Terraform"
    project    = "${var.project}"
  }
}

resource "aws_route53_record" "tidyrisk_cert_validate" {
  zone_id = "${aws_route53_zone.tidyrisk.zone_id}"
  name    = "_9693ea50764deb75429d2cbc28c4cbd2.tidyrisk.org."
  type    = "CNAME"
  records = ["_77e56607f713458b4ab22ad1d279de6d.acm-validations.aws."]
  ttl     = "600"
}

resource "aws_route53_record" "tidyrisk_www_acm_validate" {
  zone_id = "${aws_route53_zone.tidyrisk.zone_id}"
  name    = "_4a4c82ec3e932a342bdaddf97433c0f1.www.tidyrisk.org."
  type    = "CNAME"
  records = ["_09837c41b1b4024e58e48c998ac5193b.acm-validations.aws."]
  ttl     = "600"
}

resource "aws_route53_record" "tidyrisk" {
  zone_id = "${aws_route53_zone.tidyrisk.zone_id}"
  name    = "${aws_route53_zone.tidyrisk.name}"
  type    = "A"

  alias {
    name                   = "${module.tidyriskcdn.domain_name}"
    zone_id                = "${module.tidyriskcdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "tidyrisk_www" {
  zone_id = "${aws_route53_zone.tidyrisk.zone_id}"
  name    = "www.${aws_route53_zone.tidyrisk.name}"
  type    = "A"

  alias {
    name                   = "${module.tidyriskcdn.domain_name}"
    zone_id                = "${module.tidyriskcdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

/*
  -------------
  | CDN Setup |
  -------------
*/

# configure cloudfront SSL caching for S3 hosted static content
module "tidyriskcdn" {
  #source = "E:/terraform/modules//tf-cloudfronts3"
  source = "github.com/davidski/tf-cloudfronts3"

  bucket_name         = "tidyrisk"
  origin_id           = "tidyrisk_bucket"
  alias               = ["tidyrisk.org", "www.tidyrisk.org"]
  acm_certificate_arn = "${data.aws_acm_certificate.tidyrisk.arn}"
  project             = "${var.project}"
  audit_bucket        = "${data.terraform_remote_state.main.auditlogs}"
}
