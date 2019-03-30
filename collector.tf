/*
  |-----------|
  | Collector |
  |-----------|
*/

# Data source for ACM certificate
data "aws_acm_certificate" "collector_docs" {
  provider = "aws.east_1"
  domain   = "collector.severski.net"
}

# configure cloudfront SSL caching for pkgdown site on GitHub
module "collectorcdn" {
  source = "github.com/davidski/tf-cloudfrontssl"

  origin_domain_name  = "davidski.github.io"
  origin_path         = "/collector"
  origin_id           = "collectorcdn"
  alias               = "collector.severski.net"
  acm_certificate_arn = "${data.aws_acm_certificate.collector_docs.arn}"
  project             = "${var.project}"
  audit_bucket        = "${data.terraform_remote_state.main.auditlogs}"
}