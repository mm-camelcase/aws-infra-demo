data "aws_acm_certificate" "amazon_issued" {
  domain      = var.wildcard_domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}