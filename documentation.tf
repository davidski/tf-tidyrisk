# Data source for ACM certificate
data "aws_acm_certificate" "evaluator_docs" {
  provider = "aws.east_1"
  domain   = "evaluator.severski.net"
}

# configure cloudfront SSL caching for pkgdown site on GitHub
module "evaluatorcdn" {
  source = "git://github.com/davidski/tf-cloudfrontssl.git"

  origin_domain_name  = "davidski.github.io"
  origin_path         = "/evaluator"
  origin_id           = "evaluatorcdn"
  alias               = "evaluator.severski.net"
  acm_certificate_arn = "${data.aws_acm_certificate.evaluator_docs.arn}"
  project             = "${var.project}"
}
