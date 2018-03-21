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

/*
# Data source for ACM certificate
data "aws_acm_certificate" "evaluator" {
  provider = "aws.east_1"
  domain   = "scenario-explorer.c.severski.net"
}
*/

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

/*
provider "cloudflare" {}

resource "cloudflare_record" "evaluator" {
  domain  = "c.severski.net"
  name    = "scenario-explorer"
  value   = "${heroku_app.evaluator.heroku_hostname}"
  type    = "CNAME"
  proxied = true
}

resource "aws_cloudfront_distribution" "evaluator" {
  origin {
    origin_id   = "myHerokuOrigin"
    domain_name = "${heroku_app.evaluator.heroku_hostname}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Some comment"

  logging_config {
    include_cookies = false
    bucket          = "${data.terraform_remote_state.main.auditlogs}.s3.amazonaws.com"
    prefix          = "cloudfront/evaluator"
  }

  aliases = ["scenario-explorer.c.severski.net"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myHerokuOrigin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    Name       = "VP CloudFront"
    project    = "${var.project}"
    managed_by = "Terraform"
  }

  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.evaluator.arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }
}
*/

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

  records = ["scenario-explorer.c.severski.net.herokudns.com."]
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

